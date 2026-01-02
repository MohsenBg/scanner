#!/bin/bash

echo -e "\033[1;33mWelcome to the IP Scanner!\033[0m"
echo -e "\033[1;32mThis script was made by MOHSEN BG.\033[0m"
echo -e "\033[1;34mStarting the IP scan...\033[0m"
echo ""

ips_url="https://raw.githubusercontent.com/MohsenBg/scanner/refs/heads/main/ips.txt"

echo -e "\033[1;34mDownloading ips.txt file...\033[0m"
curl -s -o ips.txt "$ips_url"

ip_file="ips.txt"

if [ ! -f "$ip_file" ]; then
	echo -e "\033[1;31mIP file not found!\033[0m"
	exit 1
fi

temp_file=$(mktemp)

handle_interrupt() {
	echo -e "\n\033[1;33mInterrupted! Reachable IPs so far:\033[0m"
	if [ -s "$temp_file" ]; then
		cat "$temp_file"
	else
		echo -e "\033[1;31mNone found.\033[0m"
	fi
	rm -f "$temp_file"
	exit 1
}

trap handle_interrupt SIGINT

count=0
while IFS= read -r ip; do
	# sanitize input (IMPORTANT)
	ip=$(echo "$ip" | tr -d '\r[:space:]')
	[ -z "$ip" ] && continue

	((count++))
	echo -e "\033[1;36m[$count] Scanning $ip\033[0m"

	# TCP test on port 443 with 1s timeout
	if nc -z -w 1 "$ip" 443 >/dev/null 2>&1; then
		echo -e "\033[1;32m$ip is reachable (TCP 443)\033[0m"
		echo "$ip" >>"$temp_file"
	else
		echo -e "\033[1;31m$ip is not reachable\033[0m"
	fi

done <"$ip_file"

echo -e "\n\033[1;33mReachable IPs:\033[0m"
if [ -s "$temp_file" ]; then
	cat "$temp_file"
else
	echo -e "\033[1;31mNone found.\033[0m"
fi

rm -f "$temp_file"
echo -e "\033[1;33mScan completed.\033[0m"
