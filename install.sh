#! /bin/bash

set -eu

#### ディレクトリの作成
sudo mkdir -p /etc/nahlund/import /opt/nahlund/neo4j_scripts

#### ファイルのコピー
sudo curl -fsSL https://raw.githubusercontent.com/azishio/nahlund/refs/heads/main/docker-compose.yml -o /opt/nahlund/docker-compose.yml
sudo curl -fsSL https://raw.githubusercontent.com/azishio/nahlund/refs/heads/main/nahlund.service -o /etc/systemd/system/nahlund.service

sudo curl -fL https://github.com/azishio/rnet/releases/latest/download/river_node.csv.zst -o /etc/nahlund/import/river_node.csv.zst
sudo curl -fL https://github.com/azishio/rnet/releases/latest/download/river_link.csv.zst -o /etc/nahlund/import/river_kink.csv.zst
sudo curl -fL https://github.com/azishio/rnet/releases/latest/download/delaunay.csv.zst -o /etc/nahlund/import/delaunay.csv.zst

#### ファイルの解凍
sudo zstd -d /etc/nahlund/import/river_node.csv.zst -o /etc/nahlund/import/river_node.csv
sudo zstd -d /etc/nahlund/import/river_link.csv.zst -o /etc/nahlund/import/river_link.csv
sudo zstd -d /etc/nahlund/import/delaunay.csv.zst -o /etc/nahlund/import/delaunay.csv

### 圧縮ファイルの削除
sudo rm /etc/nahlund/import/*.zst

#### 初期環境変数ファイルの作成
# システムメモリをバイト単位で取得
memory_size_byte=$(free --bytes | grep Mem | awk '{print $2}')

# システムメモリをギガバイト単位で取得
memory_size_giga=$(free -g | grep Mem | awk '{print $2}')

# ヒープサイズをメモリの1/4に設定
neo4j_memory_size=$((memory_size_giga / 4))

# ヒープサイズの上限を31GBに設定
if [ "$neo4j_memory_size" -gt 31 ]; then
    neo4j_memory_size=31
fi

# ページキャッシュサイズをヒープサイズと同じに設定
page_cache_size=${neo4j_memory_size}

# ディスクキャッシュ最大サイズを10GBに設定（バイト単位）
disk_cache_max_size=10737418240

# メモリキャッシュ最大サイズをメモリの1/4に設定（バイト単位）
memory_cache_max_size=$((memory_size_byte / 4))

# 環境ファイルのディレクトリが存在しない場合は作成
sudo mkdir -p /etc/nahlund

# server.env ファイルを作成
sudo tee /etc/nahlund/.env > /dev/null <<EOF
# port
SERVER_PORT=3001
SOCKETIO_PORT=3002

# cors setting
CLIENT_HOST=localhost:3000

# server cache [bytes]
DISK_CACHE_MAX_SIZE=${disk_cache_max_size}
MEMORY_CACHE_MAX_SIZE=${memory_cache_max_size}

# neo4j
NEO4J_server_memory_heap_initial__size=${neo4j_memory_size}G
NEO4J_server_memory_heap_max__size=${neo4j_memory_size}G
NEO4J_server_memory_pagecache_size=${page_cache_size}G
EOF
