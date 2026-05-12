#!/bin/sh
set -eu

# 実行可能なコマンド候補を順番に探す。
resolve_cmd() {
    for candidate in "$@"; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done
    return 1
}

require_cmd() {
    name="$1"
    shift
    if ! resolved="$(resolve_cmd "$@")"; then
        echo "worker-entrypoint: required command not found: ${name}" >&2
        exit 1
    fi
    printf '%s\n' "$resolved"
}

MASTER_HOST="${MASTER_HOST:-asir-master}"
CONTROL_PORT="${CONTROL_PORT:?CONTROL_PORT is required}"
SERVER_PORT="${SERVER_PORT:?SERVER_PORT is required}"
WORKER_TAG="${WORKER_TAG:-$(hostname):0}"
RETRY_SECONDS="${RETRY_SECONDS:-2}"

# イメージ内の配置差を吸収して ox_launch / ox_asir を見つける。
OX_LAUNCH="$(require_cmd ox_launch ox_launch /OpenXM/lib/asir/ox_launch /OpenXM/bin/ox_launch /usr/local/bin/ox_launch)"
OX_ASIR="$(require_cmd ox_asir ox_asir /OpenXM/bin/ox_asir /OpenXM/lib/asir/ox_asir /usr/local/lib/asir/ox_asir)"

echo "worker-entrypoint: master=${MASTER_HOST} cport=${CONTROL_PORT} sport=${SERVER_PORT} tag=${WORKER_TAG}"
echo "worker-entrypoint: ox_launch=${OX_LAUNCH} ox_asir=${OX_ASIR}"

while :; do
    # master 側がまだ bind していない場合があるので、失敗時は待って再試行する。
    echo "worker-entrypoint: connecting to master ${MASTER_HOST} ..."
    if "$OX_LAUNCH" "$MASTER_HOST" 0 "$CONTROL_PORT" "$SERVER_PORT" "$OX_ASIR" "$WORKER_TAG"; then
        exit 0
    fi
    echo "worker-entrypoint: connection failed, retrying in ${RETRY_SECONDS}s" >&2
    sleep "$RETRY_SECONDS"
done
