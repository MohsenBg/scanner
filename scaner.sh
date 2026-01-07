#!/bin/bash

PORT=443
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
RESULT_FILE="$SCRIPT_DIR/result_$TIMESTAMP.txt"

clear
echo -e "\033[1;36m"
echo "██████╗  ██████╗      ███████╗ ██████╗ █████╗ ███╗   ██╗"
echo "██╔══██╗██╔════╝      ██╔════╝██╔════╝██╔══██╗████╗  ██║"
echo "██████╔╝██║  ███╗     ███████╗██║     ███████║██╔██╗ ██║"
echo "██╔══██╗██║   ██║     ╚════██║██║     ██╔══██║██║╚██╗██║"
echo "██████╔╝╚██████╔╝     ███████║╚██████╗██║  ██║██║ ╚████║"
echo "╚═════╝  ╚═════╝      ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e "\033[0m"
echo -e "\033[1;33m            BG  S C A N\033[0m"

echo -e "\033[1;36m"
echo "╔══════════════════════════════════════╗"
echo "║                                      ║"
echo "║        🔍  IP SCANNER TOOL  🔍       ║"
echo "║                                      ║"
echo "║        Made by  MOHSEN BG            ║"
echo "║                                      ║"
echo "╚══════════════════════════════════════╝"
echo -e "\033[0m"
echo ""

echo -ne "\033[1;36mEnter domain (e.g. www.example.com): \033[0m"
read -r DOMAIN

# sanitize domain input
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||; s|/.*||')

if [ -z "$DOMAIN" ]; then
  echo -e "\033[1;31mNo domain provided. Exiting.\033[0m"
  exit 1
fi

echo -e "\033[1;33mScanning HTTPS for domain:\033[0m $DOMAIN"
echo ""

NO_DOWNLOAD=false

while [[ "$1" != "" ]]; do
  case "$1" in
  -n | --no-download)
    NO_DOWNLOAD=true
    ;;
  -h | --help)
    echo "Usage: $0 [-n|--no-download]"
    exit 0
    ;;
  esac
  shift
done

ips_url="https://raw.githubusercontent.com/MohsenBg/scanner/refs/heads/main/ips.txt"

if [ "$NO_DOWNLOAD" = false ]; then
  echo -e "\033[1;34mDownloading ips.txt file...\033[0m"
  curl -s -o ips.txt "$ips_url"
else
  echo -e "\033[1;33mSkipping download, using local ips.txt\033[0m"
fi

ip_file="ips.txt"

if [ ! -f "$ip_file" ]; then
  echo -e "\033[1;31mIP file not found!\033[0m"
  exit 1
fi

temp_file=$(mktemp)

handle_interrupt() {
  echo -e "\n\033[1;33mInterrupted! Working IPs so far:\033[0m"

  if [ -s "$temp_file" ]; then
    cat "$temp_file"
    echo -e "\n\033[1;34mSaving results to:\033[0m $RESULT_FILE"
    cp "$temp_file" "$RESULT_FILE"
  else
    echo -e "\033[1;31mNone found.\033[0m"
  fi

  rm -f "$temp_file"
  exit 1
}

trap handle_interrupt SIGINT

shuffled_file=$(mktemp)
awk 'BEGIN{srand()} {print rand(), $0}' "$ip_file" | sort -n | cut -d' ' -f2- >"$shuffled_file"

count=0
while IFS= read -r ip; do
  ip=$(echo "$ip" | tr -d '\r[:space:]')
  [ -z "$ip" ] && continue

  ((count++))
  echo -e "\033[1;36m[$count] Testing $ip\033[0m"

  http_code=$(curl \
    --resolve "$DOMAIN:$PORT:$ip" \
    --connect-timeout 2 \
    --max-time 4 \
    -s -o /dev/null \
    -w "%{http_code}" \
    "https://$DOMAIN")

  if [ "$http_code" != "000" ]; then
    echo -e "\033[1;32m$ip - HTTP $http_code\033[0m"
    echo "$ip" >>"$temp_file"
  else
    echo -e "\033[1;31m$ip does NOT serve $DOMAIN\033[0m"
  fi

done <"$shuffled_file"

echo -e "\n\033[1;33mValid IPs for $DOMAIN:\033[0m"
if [ -s "$temp_file" ]; then
  cat "$temp_file"
  cp "$temp_file" "$RESULT_FILE"
  echo -e "\n\033[1;34mSaved to:\033[0m $RESULT_FILE"
else
  echo -e "\033[1;31mNone found.\033[0m"
fi

rm -f "$temp_file" "$shuffled_file"
echo -e "\033[1;33mScan completed.\033[0m"
