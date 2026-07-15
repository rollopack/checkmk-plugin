#!/bin/bash
# Description: Check IMAP service availability by connecting via telnet and parsing the banner
# Type: local check
# Output: <code> "IMAP" - <server_text> \n [<capability>]
# Codes: 0 = OK, 2 = CRITICAL, 3 = UNKNOWN

output=$( { sleep 2; echo -e "A001 CAPABILITY\r\nA002 LOGOUT\r\n"; } \
          | telnet localhost imap 2>/dev/null \
          | grep "^\*" | head -n 1 )

if [[ -z "$output" ]]; then
  echo "3 \"IMAP\" - No response from IMAP server or connection failed"
  exit 3
fi

status=$(echo "$output" | awk '{print $2}')
text=$(echo "$output" | sed -n 's/^\* OK \[.*\] \(.*\)$/\1/p')

if [[ -z "$text" ]]; then
  text=$(echo "$output" | cut -d' ' -f4-)
else
  text=$(echo "$text" | cut -d' ' -f2-)
fi

brackets=$(echo "$output" | sed -n 's/^\* OK \[\(.*\)\] .*$/[\1]/p')

if [[ "$status" == "OK" ]]; then
  code=0
else
  code=2
fi

echo "$code \"IMAP\" - $text \n $brackets"
exit $code