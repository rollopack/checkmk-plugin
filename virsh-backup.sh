#!/bin/bash

# Path dove cercare
path="/mnt/nas/VM/"

# Trova la cartella più recente in $path
latest_dir=$(ls -td "$path"*/ | head -1)

# Trova il file .log più recente nella cartella trovata
latest_log=$(find "$latest_dir" -name "*.log" -type f -printf "%T@ %p\n" | sort -n | tail -1 | awk '{print $2}')

# Leggi l'ultima riga del file log
last_line=$(tail -n 1 "$latest_log")

# Imposta $code in base all'ultima riga
if [[ "$last_line" == *"Finished successfully"* ]]; then
  code=0
else
  code=1
fi

# Trova tutti i file .data nella stessa cartella del .log, ordina per data di modifica e aggiungi la data di creazione e la dimensione in GB
files=""
first_file=true
for f in $(find "$latest_dir" -name "*.data" -type f -printf "%T@ %p\n" | sort -nr | awk '{print $2}'); do
  if [ -f "$f" ]; then
    # Ottieni la data di creazione del file in formato yyyy-mm-dd
    creation_date=$(stat -c %y "$f" | cut -d' ' -f1)
    # Calcola la dimensione in GB
    size_gb=$(du -BG "$f" | cut -f1)
    # Estrai solo il nome del file (rimuovi il percorso)
    file_name=$(basename "$f")
    # Se è il primo file, inseriscilo due volte
    if $first_file; then
      files+="$creation_date $file_name ($size_gb)\n"
      files+="$creation_date $file_name ($size_gb)\n"
      first_file=false
    else
      # Aggiungi al risultato finale: data di creazione, nome file e dimensione
      files+="$creation_date $file_name ($size_gb)\n"
    fi
  fi
done

# Ritorna l'output richiesto racchiuso tra apici
echo "$code \"VM - Backup\" - $files";
