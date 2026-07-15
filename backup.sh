#!/bin/bash
# Description: Check backup freshness by inspecting logrotate status files on NAS mount
# Type: local check
# Output: <code> "Backup" - <date><age> \n <detail>
# Codes: 0 = fresh (<=1d), 1 = warning (<=7d), 2 = stale (>7d)

result=""
code=2

check_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    local all_lines=$(ls -ltr --time-style=long-iso "$path/server/var/lib/"*/logrotate/status 2>/dev/null)

    if [[ -n "$all_lines" ]]; then
      local newest=$(echo "$all_lines" | tail -1)
      local raw_date=$(echo "$newest" | awk '{print $6}')
      local raw_time=$(echo "$newest" | awk '{print $7}')
      local file_epoch=$(date -d "${raw_date} ${raw_time}" +%s 2>/dev/null)
      local now_epoch=$(date +%s)
      local age_days=$(( (now_epoch - file_epoch) / 86400 ))
      local formatted_date=$(echo "$raw_date" | awk -F- '{print $3"/"$2"/"$1}')

      if   [[ $age_days -le 1 ]]; then code=0
      elif [[ $age_days -le 7 ]]; then code=1
      else                             code=2
      fi

      local detail=$(echo "$all_lines" | awk 'BEGIN { now = systime() } {
        split($6, date, "-")
        split($7, t, ":")
        epoch = mktime(date[1] " " date[2] " " date[3] " " t[1] " " t[2] " 00")
        days = int((now - epoch) / 86400)
        if (days < 7) {
          if (days == 0) age_str = ""
          else age_str = " (" days "d)"
        } else if (days < 30) age_str = " (" int(days / 7) "w)"
        else age_str = " (" int(days / 30) "m)"
        entry = date[3]"/"date[2]"/"date[1] " " $8 age_str
        if (NR == 1) printf "%s", entry
        else printf "\\n%s", entry
      }')

      if   [[ $age_days -eq 0 ]];  then summary_age=""
      elif [[ $age_days -lt 7 ]];  then summary_age=" (${age_days}d)"
      elif [[ $age_days -lt 30 ]]; then summary_age=" ($(( age_days / 7 ))w)"
      else                              summary_age=" ($(( age_days / 30 ))m)"
      fi

      result="${formatted_date}${summary_age}\\n${detail}"
      return 0
    fi
  fi
  return 1
}

for path in "/media/nas" "/mnt/nas"; do
  check_path "$path" && break
done

if [[ -n "$result" ]]; then
  echo "$code \"Backup\" - $result"
else
  echo "2 \"Backup\" - Backup directory not found"
fi