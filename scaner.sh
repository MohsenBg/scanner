#!/bin/bash

# Print a welcoming message
echo -e "\033[1;33mWelcome to the IP Scanner!\033[0m"
echo -e "\033[1;32mThis script was made by MOHSEN BG.\033[0m"
echo -e "\033[1;34mStarting the IP scan...\033[0m"
echo ""

ips_url="https://raw.githubusercontent.com/MohsenBg/scanner/refs/heads/main/ips.txt"

# Download ips.txt file using curl
# echo -e "\033[1;34mDownloading ips.txt file...\033[0m"
# curl -s -o "ips.txt" "$ips_url"
#
ip_file="ips.txt"

# Check if the download was successful
if [ ! -f "$ip_file" ]; then
	echo -e "\033[1;31mIP file not found! Please check the file path.\033[0m"
	exit 1
fi

# Start reading the ips.txt file line by line
echo -e "\033[1;34mReading IPs from the file...\033[0m"
echo ""

# Temporary file to store the reachable IPs with their ping times
temp_file=$(mktemp)

# Define a function to handle Ctrl+C (SIGINT) and show the found IPs
handle_interrupt() {
	echo -e "\033[1;33mScript interrupted! Showing reachable IPs found so far...\033[0m"

	# Sort reachable IPs by ping time (ascending order) and display the results
	if [ -f "$temp_file" ]; then
		# Sort the file by the first column (ping time) and print the IP along with the ping time
		sort -n "$temp_file" | while read line; do
			# Extract ping time and IP, and display both
			ping_time=$(echo $line | awk '{print $1}')
			ip=$(echo $line | awk '{print $2}')
			echo $ip
		done
		rm -f "$temp_file"
	else
		echo -e "\033[1;31mNo reachable IPs found.\033[0m"
	fi
	exit 1
}

# Trap Ctrl+C (SIGINT) and call the handle_interrupt function
trap handle_interrupt SIGINT

# Loop through each IP in the file
count=0
while IFS= read -r ip; do
	((count++))
	echo -e "\033[1;36mScanning IP #$count: $ip\033[0m"

	# Perform a simple ping to check if the IP is reachable and get the ping time
	ping_output=$(ping -c 1 -W 1 "$ip" 2>/dev/null) # Suppress errors
	ping_time=$(echo "$ping_output" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')

	# Check if we got a valid ping time
	if [ -n "$ping_time" ]; then
		# Save the IP and its ping time to the temporary file
		echo "$ping_time $ip" >>"$temp_file"
		echo -e "\033[1;32m$ip is reachable with ping time: $ping_time ms\033[0m"
	else
		echo -e "\033[1;31m$ip is not reachable.\033[0m"
	fi

done <"$ip_file"

# Sort reachable IPs by ping time (ascending order) and display the results
if [ -f "$temp_file" ]; then
	echo -e "\033[1;33mReachable IPs sorted by best ping time:\033[0m"
	sort -n "$temp_file" | while read line; do
		# Extract ping time and IP from the sorted result and display both
		ping_time=$(echo $line | awk '{print $1}')
		ip=$(echo $line | awk '{print $2}')
		echo $ip
	done
	rm -f "$temp_file"
else
	echo -e "\033[1;31mNo reachable IPs found.\033[0m"
fi

echo -e "\033[1;33mIP scan completed!\033[0m"
