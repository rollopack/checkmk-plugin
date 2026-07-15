#!/bin/bash
# Description: Check VM backup status — inspects latest backup log and lists backup data files
# Type: local check
# Output: <code> "VM - Backup" - <file_info>
# Codes: 0 = "Finished successfully", 1 = otherwise

path="/mnt/nas/VM/"

latest_dir=$(ls -td "$path"*/ | head -1)

latest_log=$(find "$latest_dir" -name "*.log" -type f -printf "%T@ %p\n" | sort -n | tail -1 | awk '{print $2}')

last_line=$(tail -n 1 "$latest_log")

if [[ "$last_line" == *"Finished successfully"* ]]; then
  code=0
else
  code=1
fi

files=""
first_file=true
for f in $(find "$latest_dir" -name "*.data" -type f -printf "%T@ %p\n" | sort -nr | awk '{print $2}'); do
  if [ -f "$f" ]; then
    creation_date=$(stat -c %y "$f" | cut -d' ' -f1)
    size_gb=$(du -BG "$f" | cut -f1)
    file_name=$(basename "$f")
    if $first_file; then
      files+="$creation_date $file_name ($size_gb)\n"
      files+="$creation_date $file_name ($size_gb)\n"
      first_file=false
    else
      files+="$creation_date $file_name ($size_gb)\n"
    fi
  fi
done

echo "$code \"VM - Backup\" - $files";