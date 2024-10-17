#! /bin/bash

set -eu

#### ディレクトリの作成
sudo mkdir -p /etc/nahlund/import /opt/nahlund/neo4j_scripts

#### 一般的なファイルのダウンロード関数
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

#### .zst ファイルのダウンロード関数
download_zstd_file() {
  local url="$1"
  local zst_output="$2"
  local decompressed_output="$3"

  if [ -f "$decompressed_output" ]; then
    echo "File $decompressed_output already exists, skipping download and decompression."
  else
    echo "Downloading $url to $zst_output..."
    sudo curl -#fL "$url" -o "$zst_output"
    echo "Downloaded $url to $zst_output."

    echo "Decompressing $zst_output to $decompressed_output..."
    sudo zstd -d "$zst_output" -o "$decompressed_output"
    echo "Decompressed $zst_output to $decompressed_output."

    echo "Removing $zst_output..."
    sudo rm "$zst_output"
    echo "Removed $zst_output."
  fi
}

#### 一般的なファイルのダウンロード
download_file "https://raw.githubusercontent.com/azishio/nahlund/refs/heads/main/docker-compose.yml" "/opt/nahlund/docker-compose.yml"
download_file "https://raw.githubusercontent.com/azishio/nahlund/refs/heads/main/neo4j_extension_script.sh" "/opt/nahlund/neo4j_scripts/neo4j_extension_script.sh"
download_file "https://raw.githubusercontent.com/azishio/nahlund/refs/heads/main/nahlund.service" "/etc/systemd/system/nahlund.service"

#### .zst ファイルのダウンロードと解凍

# river_node.csv
RIVER_NODE_URL="https://github.com/azishio/rnet/releases/latest/download/river_node.csv.zst"
RIVER_NODE_ZST="/etc/nahlund/import/river_node.csv.zst"
RIVER_NODE_CSV="/etc/nahlund/import/river_node.csv"

download_zstd_file "$RIVER_NODE_URL" "$RIVER_NODE_ZST" "$RIVER_NODE_CSV"

# river_link.csv
RIVER_LINK_URL="https://github.com/azishio/rnet/releases/latest/download/river_link.csv.zst"
RIVER_LINK_ZST="/etc/nahlund/import/river_link.csv.zst"
RIVER_LINK_CSV="/etc/nahlund/import/river_link.csv"

download_zstd_file "$RIVER_LINK_URL" "$RIVER_LINK_ZST" "$RIVER_LINK_CSV"

# tiles.csv
TILES_URL="https://github.com/azishio/rnet/releases/latest/download/tiles.csv.zst"
TILES_ZST="/etc/nahlund/import/tiles.csv.zst"
TILES_CSV="/etc/nahlund/import/tiles.csv"

download_zstd_file "$TILES_URL" "$TILES_ZST" "$TILES_CSV"

# tile_family_relationship.csv
TILE_FAMILY_RELATIONSHIP_URL="https://github.com/azishio/rnet/releases/latest/download/tile_family_relationship.csv.zst"
TILE_FAMILY_RELATIONSHIP_ZST="/etc/nahlund/import/tile_family_relationship.csv.zst"
TILE_FAMILY_RELATIONSHIP_CSV="/etc/nahlund/import/tile_family_relationship.csv"

download_zstd_file "$TILE_FAMILY_RELATIONSHIP_URL" "$TILE_FAMILY_RELATIONSHIP_ZST" "$TILE_FAMILY_RELATIONSHIP_CSV"

# tile_membership.csv
TILE_MEMBERSHIP_URL="https://github.com/azishio/rnet/releases/latest/download/tile_membership.csv.zst"
TILE_MEMBERSHIP_ZST="/etc/nahlund/import/tile_membership.csv.zst"
TILE_MEMBERSHIP_CSV="/etc/nahlund/import/tile_membership.csv"

download_zstd_file "$TILE_MEMBERSHIP_URL" "$TILE_MEMBERSHIP_ZST" "$TILE_MEMBERSHIP_CSV"

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
