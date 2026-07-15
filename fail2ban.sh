#!/bin/bash

version=$(fail2ban-client -V 2>/dev/null)

total_banned=0
details=""

if [[ "$version" =~ ^1\.(1[0-9]|[2-9])\. ]] || [[ "$version" =~ ^[2-9]\. ]]; then
  output=$(sudo fail2ban-client status --all 2>&1)
  if echo "$output" | grep -q "Failed to access socket path"; then
    echo "2 \"Fail2ban\" - CRITICAL - Fail2ban is not running"
    exit 2
  fi

  jail=""
  while IFS= read -r line; do
    jail_match=$(echo "$line" | sed -n 's/^[[:space:]]*|- Jail: *//p')
    if [[ -n "$jail_match" ]]; then
      jail="$jail_match"
      continue
    fi

    banned_match=$(echo "$line" | sed -n 's/^[[:space:]]*|.*|- Currently banned:[[:space:]]*//p')
    if [[ -n "$banned_match" ]] && [[ -n "$jail" ]]; then
      total_banned=$((total_banned + banned_match))
    fi

    ip_match=$(echo "$line" | sed -n 's/^[[:space:]]*|.*`- Banned IP list:[[:space:]]*//p')
    if [[ -n "$ip_match" ]] && [[ -n "$jail" ]]; then
      if [[ -n "$ip_match" ]]; then
        if [[ -z "$details" ]]; then
          details="${jail}: ${ip_match}"
        else
          details="${details}\\n${jail}: ${ip_match}"
        fi
      fi
    fi
  done < <(echo "$output")
else
  status_output=$(sudo fail2ban-client status 2>&1)
  if echo "$status_output" | grep -q "Failed to access socket path"; then
    echo "2 \"Fail2ban\" - CRITICAL - Fail2ban is not running"
    exit 2
  fi

  jail_list=$(echo "$status_output" | sed -n 's/^.*Jail list:[[:space:]]*//p' | tr ',' ' ')

  for jail in $jail_list; do
    jail_output=$(sudo fail2ban-client status "$jail" 2>&1)

    banned_match=$(echo "$jail_output" | sed -n 's/^[[:space:]]*|- Currently banned:[[:space:]]*//p')
    if [[ -n "$banned_match" ]]; then
      total_banned=$((total_banned + banned_match))
    fi

    ip_match=$(echo "$jail_output" | sed -n 's/^[[:space:]]*`- Banned IP list:[[:space:]]*//p')
    if [[ -n "$ip_match" ]]; then
      if [[ -z "$details" ]]; then
        details="${jail}: ${ip_match}"
      else
        details="${details}\\n${jail}: ${ip_match}"
      fi
    fi
  done
fi

echo "0 \"Fail2ban\" - Currently banned: ${total_banned} \\n ${details}"
exit 0