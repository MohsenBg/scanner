#!/bin/bash

DOMAIN="www.siemens.com/global/en.html" # <<< CHANGE THIS TO YOUR DOMAIN
PORT=443

echo -e "\033[1;33mWelcome to the IP Scanner!\033[0m"
echo -e "\033[1;32mThis script was made by MOHSEN BG.\033[0m"
echo -e "\033[1;34mStarting HTTPS scan for domain: $DOMAIN\033[0m"
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
    echo -e "\033[1;32m$ip - (HTTP $http_code)\033[0m"
    echo "$ip" >>"$temp_file"
  else
    echo -e "\033[1;31m$ip does NOT serve $DOMAIN\033[0m"
  fi

done <"$shuffled_file"

echo -e "\n\033[1;33mValid IPs for $DOMAIN:\033[0m"
if [ -s "$temp_file" ]; then
  cat "$temp_file"
else
  echo -e "\033[1;31mNone found.\033[0m"
fi

rm -f "$temp_file" "$shuffled_file"
echo -e "\033[1;33mScan completed.\033[0m"
