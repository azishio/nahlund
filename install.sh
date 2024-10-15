#! /bin/bash

set -eu

#### ディレクトリの作成
sudo mkdir -p /etc/nahlund/import /opt/nahlund/neo4j_scripts

#### ファイルのコピー
download_file() {
  local url="$1"
  local output="$2"

  if [ -f "$output" ]; then
    echo "File $output already exists, skipping download."
  else
    echo "Downloading $url to $output..."
    sudo curl -#fL "$url" -o "$output"
    echo "Downloaded $url to $output."
  fi
}

download_file https://raw.githubusercontent.com/azishio/nahlund/refs/heads/main/docker-compose.yml /opt/nahlund/docker-compose.yml
download_file https://raw.githubusercontent.com/azishio/nahlund/refs/heads/main/nahlund.service /etc/systemd/system/nahlund.service

download_file https://github.com/azishio/rnet/releases/latest/download/river_node.csv.zst /etc/nahlund/import/river_node.csv.zst
download_file https://github.com/azishio/rnet/releases/latest/download/river_link.csv.zst /etc/nahlund/import/river_link.csv.zst
download_file https://github.com/azishio/rnet/releases/latest/download/delaunay.csv.zst /etc/nahlund/import/delaunay.csv.zst

#### ファイルの解凍（対象の .zst ファイルが存在する場合のみ）
decompress_file() {
  local input="$1"
  local output="$2"

  if [ -f "$input" ]; then
    echo "Decompressing $input to $output..."
    sudo zstd -d "$input" -o "$output"
    echo "Decompressed $input to $output."
  fi
}

decompress_file /etc/nahlund/import/river_node.csv.zst /etc/nahlund/import/river_node.csv
decompress_file /etc/nahlund/import/river_link.csv.zst /etc/nahlund/import/river_link.csv
decompress_file /etc/nahlund/import/delaunay.csv.zst /etc/nahlund/import/delaunay.csv

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

# メモリキャッシュ最大サイズをメモリの1/4に設定（バイト単位）
memory_cache_max_size=$((memory_size_byte / 4))

# 既に .env が存在する場合は .env.bak にリネーム
if [ -f /etc/nahlund/.env ]; then
  echo ".env file already exists, creating backup as .env.bak."
  sudo mv /etc/nahlund/.env /etc/nahlund/.env.bak
fi

# server.env ファイルを作成
sudo tee /etc/nahlund/.env > /dev/null <<EOF
# port
SERVER_PORT=3001
SOCKETIO_PORT=3002

# cors setting
CLIENT_HOST=localhost:3000

# server cache [bytes]
DISK_CACHE_MAX_SIZE=10737418240
MEMORY_CACHE_MAX_SIZE=${memory_cache_max_size}

# neo4j
NEO4J_server_memory_heap_initial__size=${neo4j_memory_size}G
NEO4J_server_memory_heap_max__size=${neo4j_memory_size}G
NEO4J_server_memory_pagecache_size=${page_cache_size}G
EOF
