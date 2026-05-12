# ghcr/

GHCR に公開したイメージ `ghcr.io/nakanoryunosuke/risa-asir-container:latest` を使うための入口です。

- `pull.sh`: GHCR イメージを pull する
- `single/run.sh`: GHCR イメージで単一コンテナを起動する
- `cluster/run_example.sh`: GHCR イメージで cluster サンプルを実行する

代表的な使い方:

```bash
./ghcr/pull.sh
./ghcr/single/run.sh
./ghcr/cluster/run_example.sh 4
```
