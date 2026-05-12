# Risa-Asir Container

OpenXM(Risa/Asir)をDocker上でビルドして使うためのリポジトリです.  
`dockerfile`はUbuntuベースでOpenXMをビルドし, コンテナ内で`openxm`を使える状態まで構築します. 

## ファイル構成

- `dockerfile`: イメージ定義
- `AGENTS.md`: このリポジトリ向けの運用メモ
- `setup_docker.sh`: Dockerの初期導入(apt系OS向け)
- `build_container.sh`: イメージをビルド(`risa-asir:latest`)し, ログを`build.log`に保存
- `run_container.sh`: コンテナ(`risa-asir-container`)を作成/起動して`bash`に入る
- `compose.cluster.yml`: cluster 実行用の base compose (`master`のみ定義)
- `run_cluster_example.sh`: 任意 worker 数で cluster を起動し, Asir サンプルを実行
- `delete_container.sh`: コンテナとイメージを削除
- `.generated/`: cluster 実行時に compose / Asir サンプルを生成する作業ディレクトリ(管理対象外)

## dockerfile の内容

`dockerfile`では主に次を実行します. 

1. `ubuntu:latest`をベースイメージとして使用
2. OpenXMビルドに必要な開発ツールやライブラリを`apt-get`で導入  
  (build-essential, autoconf, bison, flex, libcerf-dev, Qt/TeX関連など)
3. 次のリポジトリをclone
  - `https://github.com/openxm-org/OpenXM`
  - `https://github.com/openxm-org/OpenXM_contrib2`
4. `/OpenXM/src`で`make configure`と`make install`を実行
5. `/OpenXM/rc`で`make`を実行し, `~/bin/openxm`を配置
6. コンテナ起動時のデフォルトコマンドは`/bin/bash`

### optional パッケージについて

`dockerfile`内の以下の範囲はoptionalです. 必要な機能がある場合にだけインストールしてください.  
対象: `# ----- 数値計算・OpenXM 本体依存 -----`から`default-jdk`まで

- gnuplot描画拡張 (cairo/pango/Qt)
- TeX/LaTeXドキュメント生成
- 日本語LaTeX対応
- 補助ツール (`nkf`, `default-jdk`など)

## 前提

- Dockerがインストール済みであること
- または初期導入用に`setup_docker.sh`を使用すること

## 使い方

### 0.Docker初期セットアップ(必要な場合のみ)

```bash
sudo ./setup_docker.sh
```

非rootユーザーで`docker`をsudoなし実行する場合は, スクリプト完了後に再ログインしてください.

### 1.ビルド

```bash
./build_container.sh
```

手動で実行する場合:

```bash
DOCKER_BUILDKIT=1 docker build --no-cache -t risa-asir .
```

### 2.コンテナ起動とログイン

```bash
./run_container.sh
```

既存コンテナがあれば再利用し, 停止中なら起動してから`bash`に接続します. 

## Docker Compose で複数 worker を直結する

`compose.cluster.yml` は `master` だけを定義する base compose です.  
worker 定義と Asir サンプルは, `run_cluster_example.sh` が worker 数に応じて `.generated/` に生成します.  
worker は `ssh` を使わず, `ox_launch` を entrypoint から直接実行して master の `control/server` ポートへ接続します.

### 1.まとめて実行する

4 worker の場合:

```bash
./run_cluster_example.sh
```

2 worker の場合:

```bash
./run_cluster_example.sh 2
```

8 worker の場合:

```bash
./run_cluster_example.sh 8
```

cluster を起動したまま残す場合:

```bash
./run_cluster_example.sh 8 --keep
```

`dockerfile` や OpenXM 本体を作り直したいときだけ build する場合:

```bash
./run_cluster_example.sh 8 --build
```

このスクリプトは内部で

1. `try_bind_listen()` で待受
2. `try_accept()` と `register_server()` で worker を登録
3. `ox_rpc()` で各 worker に計算を投げる
4. `ox_select()` と `ox_get()` で ready になった順に回収する

という最小手順の Asir サンプルを `.generated/compose_cluster_example.generated.rr` に生成して実行します.

`asir ./file.rr` のような引数実行はできず, `load("...")$` でファイルを読む形になります.

### 2.生成された compose / sample を手で使う

`./run_cluster_example.sh 8 --keep` を実行した後なら, 生成済みファイルを使って手動操作もできます.

master に入る場合:

```bash
docker compose -p risa-asir-cluster -f compose.cluster.yml -f .generated/compose.cluster.generated.yml exec master bash
```

生成済み Asir サンプルをもう一度流す場合:

```bash
docker compose -p risa-asir-cluster -f compose.cluster.yml -f .generated/compose.cluster.generated.yml exec -T master asir <<'EOF'
load("/workspace/.generated/compose_cluster_example.generated.rr")$
quit;
EOF
```

### 3.停止

```bash
docker compose -p risa-asir-cluster -f compose.cluster.yml -f .generated/compose.cluster.generated.yml down
```

### 補足

- worker のポート割り当ては `34101/34102` から 10 ずつずらして自動生成します.
- 生成された compose は `.generated/compose.cluster.generated.yml` に保存されます.
- 生成された Asir サンプルは `.generated/compose_cluster_example.generated.rr` に保存されます.
- `scripts/worker-entrypoint.sh` は master が待受を始める前でも再接続を繰り返します.

### 3.クリーンアップ

```bash
./delete_container.sh
```

`risa-asir-container`と`risa-asir:latest`を削除します. 

## 注意点

- このリポジトリのビルド定義ファイル名は`dockerfile`(小文字)です. 
- `ubuntu:latest`を使用しているため, 将来的にビルド結果が変わる可能性があります. 
