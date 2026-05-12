# Risa-Asir Container

OpenXM(Risa/Asir)を Docker 上でビルドして使うためのリポジトリです。  
役割ごとに `single/` と `cluster/` を分けています。

## 構成

- `dockerfile`: 共通のイメージ定義
- `setup_docker.sh`: Docker の初期導入スクリプト
- `single/`: 単一コンテナで使うためのスクリプト群
- `cluster/`: 複数 worker で分散実行するための compose / script 群
- `ghcr/`: GHCR に公開したイメージを使うためのスクリプト群

## 共通前提

- Docker がインストール済みであること
- または `setup_docker.sh` で初期導入すること

初期導入が必要な場合:

```bash
sudo ./setup_docker.sh
```

非 root ユーザーで `docker` を sudo なし実行する場合は、スクリプト完了後に再ログインしてください。

## 単一コンテナ版

単一コンテナ版の入口は `single/` 配下です。

- `single/build.sh`: イメージを build する
- `single/run.sh`: 単一コンテナを起動し、`bash` に入る
- `single/delete.sh`: 単一コンテナとイメージを削除する

build:

```bash
./single/build.sh
```

起動とログイン:

```bash
./single/run.sh
```

削除:

```bash
./single/delete.sh
```

`single/run.sh` はリポジトリ全体を `/workspace` に mount して起動します。

## Cluster 版

cluster 版の入口は `cluster/` 配下です。

- `cluster/compose.yml`: `master` だけを定義する base compose
- `cluster/run_example.sh`: 任意 worker 数で cluster を起動し、Asir サンプルを実行
- `cluster/scripts/worker-entrypoint.sh`: worker の接続処理
- `cluster/examples/`: 固定 worker 数の参考サンプル
- `cluster/.generated/`: 実行時に compose / Asir サンプルを生成する作業ディレクトリ

### まとめて実行する

4 worker:

```bash
./cluster/run_example.sh
```

2 worker:

```bash
./cluster/run_example.sh 2
```

8 worker:

```bash
./cluster/run_example.sh 8
```

cluster を起動したまま残す:

```bash
./cluster/run_example.sh 8 --keep
```

`dockerfile` や OpenXM 本体を作り直したいときだけ build する:

```bash
./cluster/run_example.sh 8 --build
```

### cluster 版の動き

`cluster/run_example.sh` は内部で次を行います。

1. `cluster/.generated/compose.cluster.generated.yml` を生成する
2. `cluster/.generated/compose_cluster_example.generated.rr` を生成する
3. `master` と指定数の worker を起動する
4. master 上で Asir サンプルを `load("...")$` で実行する

worker は `ssh` を使わず、`ox_launch` を entrypoint から直接実行して master の `control/server` ポートへ接続します。

### 手動操作する

`./cluster/run_example.sh 8 --keep` を実行した後なら、生成済みファイルを使って手動操作できます。

master に入る:

```bash
docker compose -p risa-asir-cluster -f cluster/compose.yml -f cluster/.generated/compose.cluster.generated.yml exec master bash
```

生成済み Asir サンプルをもう一度流す:

```bash
docker compose -p risa-asir-cluster -f cluster/compose.yml -f cluster/.generated/compose.cluster.generated.yml exec -T master asir <<'EOF'
load("/workspace/cluster/.generated/compose_cluster_example.generated.rr")$
quit;
EOF
```

停止:

```bash
docker compose -p risa-asir-cluster -f cluster/compose.yml -f cluster/.generated/compose.cluster.generated.yml down
```

### 補足

- worker のポート割り当ては `34101/34102` から 10 ずつずらして自動生成します
- `cluster/scripts/worker-entrypoint.sh` は master が待受を始める前でも再接続を繰り返します
- `asir ./file.rr` のような引数実行はできず、`load("...")$` でファイルを読む形になります

## GHCR 版

GHCR に公開したイメージを使う入口は `ghcr/` 配下です。

- `ghcr/pull.sh`: `ghcr.io/nakanoryunosuke/risa-asir-container:latest` を pull する
- `ghcr/single/run.sh`: GHCR イメージで単一コンテナを起動する
- `ghcr/cluster/run_example.sh`: GHCR イメージで cluster サンプルを実行する

pull:

```bash
./ghcr/pull.sh
```

単一コンテナ:

```bash
./ghcr/single/run.sh
```

cluster 4 worker:

```bash
./ghcr/cluster/run_example.sh 4
```

cluster を起動したまま残す:

```bash
./ghcr/cluster/run_example.sh 8 --keep
```

## dockerfile の内容

`dockerfile` では主に次を実行します。

1. `ubuntu:24.04` をベースイメージとして使用
2. OpenXM ビルドに必要な開発ツールやライブラリを `apt-get` で導入
3. `OpenXM`, `OpenXM_contrib2` を clone
4. `/OpenXM/src` で `make configure`, `make install` を実行
5. `/OpenXM/rc` で `make` を実行し、`~/bin/openxm` を配置

### optional パッケージ

`dockerfile` 内の `# ----- 数値計算・OpenXM 本体依存 -----` から `default-jdk` までは optional です。必要な機能がある場合にだけインストールしてください。

- gnuplot 描画拡張 (cairo/pango/Qt)
- TeX/LaTeX ドキュメント生成
- 日本語 LaTeX 対応
- 補助ツール (`nkf`, `default-jdk` など)

## 注意点

- このリポジトリのビルド定義ファイル名は `dockerfile` (小文字) です
- `ubuntu:24.04` に固定しているため、`latest` 追従によるビルド変動は避けています
