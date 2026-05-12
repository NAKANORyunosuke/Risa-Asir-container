#!/bin/sh
set -eu

# このスクリプトは、cluster 用 compose を起動し、
# master 上で Asir の並列サンプルを実行するところまでをまとめて行う。
# worker 定義と Asir サンプルは、指定された worker 数に応じて .generated/ に生成する。

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BASE_COMPOSE_FILE="${SCRIPT_DIR}/compose.cluster.yml"
GENERATED_DIR="${SCRIPT_DIR}/.generated"
GENERATED_COMPOSE_FILE="${GENERATED_DIR}/compose.cluster.generated.yml"
GENERATED_EXAMPLE_FILE="${GENERATED_DIR}/compose_cluster_example.generated.rr"
PROJECT_NAME="risa-asir-cluster"
BASE_CONTROL_PORT=34101
PORT_STEP=10
JOB_EXPONENT_STEP=40
JOB_VARIANTS=4

usage() {
    cat <<'EOF'
使い方:
  ./run_cluster_example.sh [N] [--keep] [--build]

引数:
  N            実行する worker 数 (デフォルト: 4)
  --keep       実行後も compose 環境を停止しない
  --build      起動前にイメージを build する
EOF
}

WORKERS=4
KEEP_CLUSTER=0
DO_BUILD=0
WORKER_SERVICES=""

compose_cmd() {
    docker compose -p "$PROJECT_NAME" -f "$BASE_COMPOSE_FILE" -f "$GENERATED_COMPOSE_FILE" "$@"
}

generate_worker_compose() {
    mkdir -p "$GENERATED_DIR"

    cat > "$GENERATED_COMPOSE_FILE" <<EOF
services:
EOF

    WORKER_SERVICES=""
    i=1
    while [ "$i" -le "$WORKERS" ]; do
        control_port=$((BASE_CONTROL_PORT + PORT_STEP * (i - 1)))
        server_port=$((control_port + 1))
        WORKER_SERVICES="${WORKER_SERVICES} worker${i}"
        cat >> "$GENERATED_COMPOSE_FILE" <<EOF
  # worker${i} は control=${control_port}, server=${server_port} を使う。
  worker${i}:
    image: risa-asir:latest
    depends_on:
      - master
    hostname: asir-worker${i}
    working_dir: /workspace
    entrypoint: ["/bin/sh", "/workspace/scripts/worker-entrypoint.sh"]
    environment:
      MASTER_HOST: asir-master
      CONTROL_PORT: "${control_port}"
      SERVER_PORT: "${server_port}"
      WORKER_TAG: "worker${i}:0"
    volumes:
      - ${SCRIPT_DIR}:/workspace
EOF
        i=$((i + 1))
    done
}

generate_example_rr() {
    cat > "$GENERATED_EXAMPLE_FILE" <<EOF
/* run_cluster_example.sh が生成する動的サンプル */
WorkerCount = ${WORKERS}\$
ControlBasePort = ${BASE_CONTROL_PORT}\$
PortStep = ${PORT_STEP}\$
SM_popSerializedLocalObject = 258\$

ControlPorts = newvect(WorkerCount)\$
ServerPorts = newvect(WorkerCount)\$
Jobs = newvect(WorkerCount)\$
Ids = newvect(WorkerCount)\$
CListen = newvect(WorkerCount)\$
SListen = newvect(WorkerCount)\$
Results = newvect(WorkerCount)\$
Finished = newvect(WorkerCount)\$

/* worker 数に応じて control/server ポートとサンプル計算を組み立てる */
for (I=0; I<WorkerCount; I++) {
  ControlPorts[I] = ControlBasePort + PortStep*I;
  ServerPorts[I] = ControlPorts[I] + 1;
}

EOF

    i=1
    while [ "$i" -le "$WORKERS" ]; do
        exponent=$((JOB_EXPONENT_STEP * (((i - 1) % JOB_VARIANTS) + 1)))
        cat >> "$GENERATED_EXAMPLE_FILE" <<EOF
Jobs[$((i - 1))] = x^${exponent} - y^${exponent}\$
EOF
        i=$((i + 1))
    done

    cat >> "$GENERATED_EXAMPLE_FILE" <<EOF

/* 各 worker の control/server ポートで待受を開始 */
for (I=0; I<WorkerCount; I++) {
  CListen[I] = try_bind_listen(ControlPorts[I]);
  SListen[I] = try_bind_listen(ServerPorts[I]);
}

print(["Waiting for workers to connect ...",WorkerCount])\$
/* worker からの control/server 接続を受け取り、OpenXM server として登録する */
for (I=0; I<WorkerCount; I++) {
  CSocket = try_accept(CListen[I],ControlPorts[I]);
  SSocket = try_accept(SListen[I],ServerPorts[I]);
  Ids[I] = register_server(CSocket,ControlPorts[I],SSocket,ServerPorts[I]);
}

print(["registered worker ids",vtol(Ids)])\$

/* 各 worker に計算を投げ、結果を ox_get で拾える状態にする */
for (I=0; I<WorkerCount; I++) {
  ox_rpc(Ids[I],"fctr",Jobs[I]);
  ox_push_cmd(Ids[I],SM_popSerializedLocalObject);
}

Done = 0\$
/* ready になった worker から順に結果を回収する */
while (Done < WorkerCount) {
  Ready = ox_select(vtol(Ids));
  for (J=0; J<length(Ready); J++) {
    Id = Ready[J];
    for (K=0; K<WorkerCount; K++) {
      if (Ids[K] == Id && Finished[K] == 0) {
        Results[K] = ox_get(Id);
        Finished[K] = 1;
        Done++;
        break;
      }
    }
  }
}

print("All results collected.")\$
Results;

/* 最後に worker を shutdown する */
for (I=0; I<WorkerCount; I++) ox_shutdown(Ids[I]);
EOF
}

for arg in "$@"; do
    case "$arg" in
        ''|*[!0-9]*)
            case "$arg" in
                --keep)
                    KEEP_CLUSTER=1
                    ;;
                --build)
                    DO_BUILD=1
                    ;;
                -h|--help)
                    usage
                    exit 0
                    ;;
                *)
                    echo "Unknown argument: $arg" >&2
                    usage >&2
                    exit 1
                    ;;
            esac
            ;;
        *)
            WORKERS="$arg"
            ;;
    esac
done

if [ "$WORKERS" -lt 1 ]; then
    echo "Worker count must be >= 1." >&2
    exit 1
fi

MAX_SERVER_PORT=$((BASE_CONTROL_PORT + PORT_STEP * (WORKERS - 1) + 1))
if [ "$MAX_SERVER_PORT" -gt 65535 ]; then
    echo "Worker count is too large for the current port allocation." >&2
    exit 1
fi

cleanup() {
    # --keep が指定されていなければ、最後に cluster を止める。
    if [ "$KEEP_CLUSTER" -ne 1 ]; then
        compose_cmd down >/dev/null 2>&1 || true
    fi
}

trap cleanup EXIT INT TERM

generate_worker_compose
generate_example_rr

echo "[1/4] 既存の cluster を停止して、待受ポート競合を避けます..."
compose_cmd down --remove-orphans >/dev/null 2>&1 || true

if [ "$DO_BUILD" -eq 1 ]; then
    echo "[2/4] イメージを build します..."
    compose_cmd build master
else
    echo "[2/4] build を省略します..."
fi

echo "[3/4] master と worker を起動します..."
compose_cmd up -d master $WORKER_SERVICES

echo "[4/4] master 上で Asir サンプルを実行します..."
# Asir はファイル引数実行ではなく、load("...")$ で読み込む。
compose_cmd exec -T master asir <<EOF
load("/workspace/.generated/compose_cluster_example.generated.rr")$
quit;
EOF

if [ "$KEEP_CLUSTER" -eq 1 ]; then
    echo "cluster は起動したままです。"
    echo "停止する場合: docker compose -p ${PROJECT_NAME} -f compose.cluster.yml -f .generated/compose.cluster.generated.yml down"
fi
