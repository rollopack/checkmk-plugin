#!/bin/bash

# Legge il contenuto del file /etc/debian_version
version=$(cat /etc/debian_version)

# Estrae il numero principale dalla versione (ad esempio, "11" da "11.4")
main_version=$(echo "$version" | cut -d'.' -f1)

# Controlla la versione e imposta il valore di "code"
if [[ $main_version -eq 11 ]]; then
    code=1  # Versione precedente (OLD STABLE)
elif [[ $main_version -lt 11 ]]; then
    code=2  # Versione obsoleta
else
    code=0  # Versione aggiornata
fi

# Ottiene la data dell'ultimo upgrade da /var/log/apt/history.log*
# Legge i file dal più recente al più vecchio e si ferma al primo match.
last_dist_upgrade="N/A"

# Ordine: history.log → history.log.1.gz → history.log.2.gz → ...
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

# Stampa l'output con printf per allineare le colonne
printf "%s \"Debian version\" - %-6s | Last update: %s\n" \
    "$code" "$version" "$last_dist_upgrade"
