# cluster/

複数 worker を使った cluster 実行用のファイルを置くディレクトリです。

- `compose.yml`: `master` だけを定義する base compose
- `run_example.sh`: 任意 worker 数で cluster を起動して Asir サンプルを流す
- `scripts/worker-entrypoint.sh`: worker の接続処理
- `examples/`: 固定 worker 数の参考サンプル
- `.generated/`: 実行時に生成される compose / Asir サンプル置き場

代表的な使い方:

```bash
./cluster/run_example.sh
./cluster/run_example.sh 3
./cluster/run_example.sh 8 --keep
```
