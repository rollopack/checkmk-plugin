#!/bin/bash
# Description: Monitor Samba — count connected clients and open files
# Type: local check
# Output: 0 "Samba" - Clients: <n>, Files: <n>
# Codes: 0 = OK (always)

clients=$(smbstatus -b | awk '{print $4}' | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}|\[.*\]' | wc -l)

files=$(smbstatus -L | grep -c -E '\.[a-zA-Z0-9_-]+[[:space:]]+[A-Z][a-z]{2}[[:space:]]+[A-Z][a-z]{2}[[:space:]]+')

echo "0 \"Samba\" - Clients: ${clients}, Files: ${files}"