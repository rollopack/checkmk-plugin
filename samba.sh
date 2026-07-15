#!/bin/bash

# Get number of connected clients
clients=$(smbstatus -b | awk '{print $4}' | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}|\[.*\]' | wc -l)

# Get number of open files using smbstatus -L, filtering elements that end in an extension before the date string
files=$(smbstatus -L | grep -c -E '\.[a-zA-Z0-9_-]+[[:space:]]+[A-Z][a-z]{2}[[:space:]]+[A-Z][a-z]{2}[[:space:]]+')

# Output the data in Nagios-style format
echo "0 \"Samba\" - Clients: ${clients}, Files: ${files}"
