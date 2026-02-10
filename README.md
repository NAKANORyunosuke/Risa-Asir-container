# Risa-Asir Container

OpenXM(Risa/Asir)をDocker上でビルドして使うためのリポジトリです.  
`dockerfile`はUbuntuベースでOpenXMをビルドし, コンテナ内で`openxm`を使える状態まで構築します. 

## ファイル構成

- `dockerfile`: イメージ定義
- `setup_docker.sh`: Dockerの初期導入(apt系OS向け)
- `build_container.sh`: イメージをビルド(`risa-asir:latest`)し, ログを`build.log`に保存
- `run_container.sh`: コンテナ(`risa-asir-container`)を作成/起動して`bash`に入る
- `delete_container.sh`: コンテナとイメージを削除

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

### 3.クリーンアップ

```bash
./delete_container.sh
```

`risa-asir-container`と`risa-asir:latest`を削除します. 

## 注意点

- このリポジトリのビルド定義ファイル名は`dockerfile`(小文字)です. 
- `ubuntu:latest`を使用しているため, 将来的にビルド結果が変わる可能性があります. 
