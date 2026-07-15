#!/bin/bash
# Description: Check Debian version and last dist-upgrade date
# Type: local check
# Output: <code> "Debian version" - <version> | Last update: <date>
# Codes: 0 = current, 1 = oldstable, 2 = obsolete

version=$(cat /etc/debian_version)

main_version=$(echo "$version" | cut -d'.' -f1)

if [[ $main_version -eq 11 ]]; then
    code=1
elif [[ $main_version -lt 11 ]]; then
    code=2
else
    code=0
fi

last_dist_upgrade="N/A"

apt_files=()
[ -f /var/log/apt/history.log ] && apt_files+=("/var/log/apt/history.log")
for f in $(ls /var/log/apt/history.log.*.gz 2>/dev/null | sort -V); do
    apt_files+=("$f")
done

for f in "${apt_files[@]}"; do
    if [[ "$f" == *.gz ]]; then
        content=$(zcat "$f")
    else
        content=$(cat "$f")
    fi

    result=$(echo "$content" | awk '
        /^Start-Date:/  { start = $2 }
        /^Commandline:/ && /(apt(-get)?|aptitude)[[:space:]]+(dist-upgrade|full-upgrade|safe-upgrade|upgrade)([[:space:]]|$)/ { last = start }
        END { if (last) print last }
    ')

    if [ -n "$result" ]; then
        last_dist_upgrade="$result"
        break
    fi
done

printf "%s \"Debian version\" - %-6s | Last update: %s\n" \
    "$code" "$version" "$last_dist_upgrade"