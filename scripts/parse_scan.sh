#!/bin/bash
# post_process_scan.sh
# Parse scan_results.md and create hosts table with persistent notes

set -euo pipefail

WORKDIR="/home/cos/material/mkdocs_dev_material"
SCAN_MD="$WORKDIR/docs/scan_results.md"
HOSTS_MD="$WORKDIR/docs/hosts.md"

# File to store previous notes
PREV_HOSTS="$WORKDIR/docs/hosts_notes_backup.md"

# Ensure previous notes backup exists
if [[ ! -f "$PREV_HOSTS" ]]; then
    touch "$PREV_HOSTS"
fi

# Read previous notes into associative array keyed by hostname or IP
declare -A NOTES
while IFS="|" read -r count hostname ip mac status link note; do
    key=$(echo "$hostname" | tr -d '[:space:]')
    NOTES["$key"]="$note"
done < <(tail -n +2 "$PREV_HOSTS" | sed 's/^[ \t]*//;s/[ \t]*$//')

# Start writing the new hosts table
{
echo "# Hosts"
echo ""
echo "| # | Hostname | IP Address | MAC Address | Status | Link | Notes |"
echo "|---|----------|------------|------------|--------|------|-------|"

# Counter
i=1

# Parse scan_results.md (skip header lines)
grep -E "^[0-9]" "$SCAN_MD" | while IFS="|" read -r ip hostname os ports mac; do
    hostname_clean=$(echo "$hostname" | sed 's/\.lan$//')
    ip=$(echo "$ip" | xargs)
    mac=$(echo "$mac" | xargs)

    # Status: on if nmap found any open port, off otherwise
    if [[ "$ports" =~ open ]]; then
        status="Online"
    else
        status="Offline"
    fi

    # Link: assume http if port 80 or 8000 is open
    link=""
    if [[ "$ports" =~ "80/tcp" || "$ports" =~ "8000/tcp" ]]; then
        link="[http://$ip](http://$ip)"
    fi

    # Retrieve persistent notes
    note="${NOTES[$hostname_clean]:-}"

    # Output row
    echo "| $i | $hostname_clean | $ip | $mac | $status | $link | $note |"

    ((i++))
done

} > "$HOSTS_MD"

# Backup new notes for next run
cp "$HOSTS_MD" "$PREV_HOSTS"

echo "Hosts table updated at $HOSTS_MD"
