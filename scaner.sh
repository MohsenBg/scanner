#!/bin/bash

PORT=443
PARALLEL=6 # <-- adjust: 4–8 is ideal on mobile
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
echo ""

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

echo -e "\033[1;33mBG SCAN — Parallel Mode (Active)\033[0m"

# ----- read domain safely -----
echo -ne "\033[1;36mEnter domain (e.g. www.example.com): \033[0m"
read -r DOMAIN </dev/tty

DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||; s|/.*||')

if [ -z "$DOMAIN" ]; then
  echo -e "\033[1;31mNo domain provided. Exiting.\033[0m"
  exit 1
fi

echo -e "\033[1;33mScanning HTTPS for:\033[0m $DOMAIN"
echo ""

# ----- get IP list -----
ips_url="https://raw.githubusercontent.com/MohsenBg/scanner/refs/heads/main/ips.txt"
curl -s -o ips.txt "$ips_url" || exit 1

# ----- temp files -----
temp_file=$(mktemp)
shuffled_file=$(mktemp)

trap 'echo -e "\nInterrupted. Saving results."; cp "$temp_file" "$RESULT_FILE"; exit 1' SIGINT

awk 'BEGIN{srand()} {print rand(), $0}' ips.txt | sort -n | cut -d' ' -f2- >"$shuffled_file"

export DOMAIN PORT temp_file

# ----- function executed in parallel -----
test_ip() {
  ip="$1"
  ip="${ip//$'\r'/}"

  [ -z "$ip" ] && exit 0

  code=$(curl \
    --resolve "$DOMAIN:$PORT:$ip" \
    --head \
    --http1.1 \
    --connect-timeout 1 \
    --max-time 2 \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    "https://$DOMAIN")

  if [ "$code" != "000" ]; then
    printf "\033[1;32m[OK]\033[0m %s → %s\n" "$ip" "$code"
    echo "$ip" >>"$temp_file"
  else
    printf "\033[1;31m[NO]\033[0m %s\n" "$ip"
  fi
}

export -f test_ip

# ----- run in parallel -----
cat "$shuffled_file" |
  xargs -n 1 -P "$PARALLEL" bash -c 'test_ip "$@"' _

# ----- final output -----
echo -e "\n\033[1;33mValid IPs:\033[0m"
if [ -s "$temp_file" ]; then
  cat "$temp_file"
  cp "$temp_file" "$RESULT_FILE"
  echo -e "\n\033[1;34mSaved to:\033[0m $RESULT_FILE"
else
  echo -e "\033[1;31mNone found.\033[0m"
fi

rm -f "$temp_file" "$shuffled_file"
echo -e "\033[1;33mScan completed.\033[0m"
