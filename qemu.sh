#!/bin/bash
# Description: Monitor QEMU/KVM virtual machines — reports state, memory usage, CPU count, CPU time per VM
# Type: local check
# Output: <code> VM memory_usage=<pct>;80;90;0;100|cpus=<n>;;;0;|cpu_time=<s>;;;0; <status_text>
# Codes: 0 = running, 1 = warning (non-running/non-shut), 2 = critical (shut off)
# License: GPL v2

export LIBVIRT_DEFAULT_URI="qemu:///system"
export LC_ALL=C

if ! which virsh >/dev/null; then
    echo "3 VM virsh_not_found=1;;;0;1 virsh not found. Ensure libvirt is installed."
    exit 1
fi

virsh list --all | grep -v -E '^( Id| -)' | grep -v '^$' | while read -r line; do
    ID=$(echo "$line" | awk '{print $1}')
    NAME=$(echo "$line" | awk '{print $2}')
    STATE=$(echo "$line" | awk '{print $3}')

    if [ -z "$NAME" ] || [ "$NAME" = "Name" ] || [ "$NAME" = "Nome" ]; then
        continue
    fi

    DOMINFO=$(virsh dominfo "$NAME" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "3 VM - Error retrieving dominfo for ${NAME}"
        continue
    fi

    USED_MEMORY=$(echo "$DOMINFO" | grep 'Used memory' | awk '{print $3}')
    MAX_MEMORY=$(echo "$DOMINFO" | grep 'Max memory' | awk '{print $3}')
    CPUS=$(echo "$DOMINFO" | grep 'CPU(s)' | awk '{print $2}')
    CPU_TIME=$(echo "$DOMINFO" | grep 'CPU time' | awk '{print $3}' | tr -d 's')

    USED_MEMORY_MB=0
    MAX_MEMORY_MB=0
    [ -n "$USED_MEMORY" ] && USED_MEMORY_MB=$((USED_MEMORY / 1024))
    [ -n "$MAX_MEMORY" ] && MAX_MEMORY_MB=$((MAX_MEMORY / 1024))

    CPUS=${CPUS:-0}
    CPU_TIME=${CPU_TIME:-0}

    DOMSTATE=$(virsh domstate --reason "$NAME" 2>/dev/null)
    [ $? -ne 0 ] && DOMSTATE="unknown"

    STATUS=0
    STATUS_TEXT="OK"
    if [ "$STATE" = "shut" ]; then
        STATUS=2
        STATUS_TEXT="CRITICAL - VM is shut off"
    elif [ "$STATE" != "running" ]; then
        STATUS=1
        STATUS_TEXT="WARNING - VM is in state ${STATE}"
    fi

    MEMORY_USAGE_PERCENT=0
    if [ "$MAX_MEMORY_MB" -gt 0 ]; then
        MEMORY_USAGE_PERCENT=$(awk -v used="$USED_MEMORY_MB" -v max="$MAX_MEMORY_MB" 'BEGIN {printf "%.2f", (used / max) * 100}')
    fi

    echo "${STATUS} VM memory_usage=${MEMORY_USAGE_PERCENT};80;90;0;100|cpus=${CPUS};;;0;|cpu_time=${CPU_TIME};;;0; ${STATUS_TEXT} - VM Name: ${NAME}, Memory Usage: ${MEMORY_USAGE_PERCENT}% (${USED_MEMORY_MB}/${MAX_MEMORY_MB} MB), State: ${DOMSTATE}, CPUs: ${CPUS}, CPU Time: ${CPU_TIME}s"
done

exit 0