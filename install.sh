#! /bin/bash

set -eu

#### ディレクトリの作成
sudo mkdir -p /etc/nahlund
sudo mkdir -p /opt/nahlund

#### ファイルのコピー
sudo curl -fsSL https://raw.githubusercontent.com/azishio/nahlund/refs/heads/main/docker-compose.yml -o /opt/nahlund/docker-compose.yml
sudo curl -fsSL https://raw.githubusercontent.com/azishio/nahlund/refs/heads/main/nahlund.service -o /etc/systemd/system/nahlund.service

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
sudo tee /etc/nahlund/server.env > /dev/null <<EOF
SOCKETIO_HOST=localhost:3002
SERVER_HOST=localhost:3001
CLIENT_HOST=localhost:3000
DISK_CACHE_MAX_SIZE=${disk_cache_max_size}
MEMORY_CACHE_MAX_SIZE=${memory_cache_max_size}
EOF

# neo4j.env ファイルを作成
sudo tee /etc/nahlund/neo4j.env > /dev/null <<EOF
NEO4J_server_memory_heap_initial__size=${neo4j_memory_size}G
NEO4J_server_memory_heap_max__size=${neo4j_memory_size}G
NEO4J_server_memory_pagecache_size=${page_cache_size}G
EOF

# socketio.env ファイルを作成（内容が空の場合）
sudo tee /etc/nahlund/socketio.env > /dev/null <<EOF
EOF
