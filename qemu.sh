#!/bin/bash
# Script per Checkmk 2.4 come local check per monitorare VM QEMU/KVM
# Autore: Rolland Gabriel
# Versione: 2.0.4
# Data: 06/05/2025
# Licenza: GPL v2

# Descrizione:
# Questo script genera un output in formato local check per Checkmk 2.4.
# Utilizza virsh domstate e dominfo per ottenere nome, stato e risorse delle VM.
# Gestisce l'output in italiano di virsh e non richiede configurazioni lato server.
# Evidenzia il Memory_Usage come informazione principale.
# Formatta il CPU Time in giorni, ore, minuti, secondi.

# Forza l'output di virsh in inglese per uniformità
export LIBVIRT_DEFAULT_URI="qemu:///system"
export LC_ALL=C

# Verifica se virsh è disponibile
if ! which virsh >/dev/null; then
    echo "3 VM virsh_not_found=1;;;0;1 virsh non trovato. Assicurati che libvirt-bin sia installato."
    exit 1
fi

# Elenca tutte le VM (attive e non attive)
virsh list --all | grep -v -E '^( Id| -)' | grep -v '^$' | while read -r line; do
    # Estrai ID, Nome e Stato dalla riga
    ID=$(echo "$line" | awk '{print $1}')
    NAME=$(echo "$line" | awk '{print $2}')
    STATE=$(echo "$line" | awk '{print $3}')

    # Ignora righe non valide
    if [ -z "$NAME" ] || [ "$NAME" = "Name" ] || [ "$NAME" = "Nome" ]; then
        continue
    fi

    # Ottieni informazioni dettagliate con virsh dominfo
    DOMINFO=$(virsh dominfo "$NAME" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "3 VM - Error retrieving dominfo for ${NAME}"
        continue
    fi

    # Estrai informazioni rilevanti da dominfo
    USED_MEMORY=$(echo "$DOMINFO" | grep 'Used memory' | awk '{print $3}')
    MAX_MEMORY=$(echo "$DOMINFO" | grep 'Max memory' | awk '{print $3}')
    CPUS=$(echo "$DOMINFO" | grep 'CPU(s)' | awk '{print $2}')
    CPU_TIME=$(echo "$DOMINFO" | grep 'CPU time' | awk '{print $3}' | tr -d 's')

    # Converti memoria in MB e gestisci valori mancanti
    USED_MEMORY_MB=0
    MAX_MEMORY_MB=0
    [ -n "$USED_MEMORY" ] && USED_MEMORY_MB=$((USED_MEMORY / 1024))
    [ -n "$MAX_MEMORY" ] && MAX_MEMORY_MB=$((MAX_MEMORY / 1024))

    # Gestisci valori mancanti per CPU e CPU Time
    CPUS=${CPUS:-0}
    CPU_TIME=${CPU_TIME:-0}

    # Ottieni stato dettagliato con virsh domstate
    DOMSTATE=$(virsh domstate --reason "$NAME" 2>/dev/null)
    [ $? -ne 0 ] && DOMSTATE="unknown"

    # Determina lo stato per Checkmk
    STATUS=0
    STATUS_TEXT="OK"
    if [ "$STATE" = "shut" ]; then
        STATUS=2
        STATUS_TEXT="CRITICAL - VM is shut off"
    elif [ "$STATE" != "running" ]; then
        STATUS=1
        STATUS_TEXT="WARNING - VM is in state ${STATE}"
    fi

    # Calcola percentuale di utilizzo memoria
    MEMORY_USAGE_PERCENT=0
    if [ "$MAX_MEMORY_MB" -gt 0 ]; then
        # Usa awk per calcoli più robusti
        MEMORY_USAGE_PERCENT=$(awk -v used="$USED_MEMORY_MB" -v max="$MAX_MEMORY_MB" 'BEGIN {printf "%.2f", (used / max) * 100}')
    fi

    # Formatta l'output per Checkmk, con Memory_Usage come informazione principale
    echo "${STATUS} VM memory_usage=${MEMORY_USAGE_PERCENT};80;90;0;100|cpus=${CPUS};;;0;|cpu_time=${CPU_TIME};;;0; ${STATUS_TEXT} - VM Name: ${NAME}, Memory Usage: ${MEMORY_USAGE_PERCENT}% (${USED_MEMORY_MB}/${MAX_MEMORY_MB} MB), State: ${DOMSTATE}, CPUs: ${CPUS}, CPU Time: ${CPU_TIME}s"
done

exit 0
