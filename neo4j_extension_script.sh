#!/bin/bash

#!/bin/bash
set -euC

if [ -f /import/done ]; then
    echo "Skip import process"
    return
fi

# neo4jのdatabaseの削除
echo "Start the database deletion process"
rm -rf /data/databases
rm -rf /data/transactions
echo "Complete the database deletion process"

# CSVデータのインポート
echo "Start the data import process"
bin/neo4j-admin database import full neo4j \
  --nodes=/import/tiles.csv \
  --nodes=/import/river_node.csv \
  --relationships=/import/river_link.csv \
  --relationships=/import/tile_family_relationship.csv \
  --relationships=/import/tile_membership.csv
echo "Complete the data import process"

# import処理の完了フラグファイルの作成
echo "Start creating flag file"
touch /import/done
echo "Complete creating flag file"

echo "Start ownership change"
chown -R neo4j:neo4j /data
chown -R neo4j:neo4j /logs
echo "Complete ownership change"
