#!/bin/bash

# Timeout aumentato a 3 secondi per maggiore affidabilità
output=$( { sleep 2; echo -e "A001 CAPABILITY\r\nA002 LOGOUT\r\n"; } \
          | telnet localhost imap 2>/dev/null \
          | grep "^\*" | head -n 1 )

# Se non c'è output, return UNKNOWN
if [[ -z "$output" ]]; then
  echo "3 \"IMAP\" - Nessuna risposta dal server IMAP o connessione fallita"
  exit 3
fi

# Parsing
status=$(echo "$output" | awk '{print $2}')
text=$(echo "$output" | sed -n 's/^\* OK \[.*\] \(.*\)$/\1/p')

# Se non trovato, fallback (es. output diverso)
if [[ -z "$text" ]]; then
  text=$(echo "$output" | cut -d' ' -f4-)
else
  # Se trovato, rimuovo la prima parola (nome del server) dal testo estratto
  text=$(echo "$text" | cut -d' ' -f2-)
fi

brackets=$(echo "$output" | sed -n 's/^\* OK \[\(.*\)\] .*$/[\1]/p')

# Codice uscita
if [[ "$status" == "OK" ]]; then
  code=0
else
  code=2
fi

# Output finale con detail separato da '\n'
echo "$code \"IMAP\" - $text \n $brackets"
exit $code
