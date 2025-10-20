#!/bin/bash
# File: scan.sh
# Purpose: Run nmap scan, update scan_results.md and hosts.md for MkDocs

set -e

DOCS_DIR="/home/cos/material/mkdocs_dev_material/docs"
SCRIPTS_DIR="/home/cos/material/mkdocs_dev_material/scripts"
HOSTS_FILE="$DOCS_DIR/hosts.md"
SCAN_FILE="$DOCS_DIR/scan_results.md"
SUBNET="192.168.1.0/24"
NMAP_ARGS="-sS -O -Pn -p 22,53,80,111,135,139,445,443,8000,8080"

TMP_SCAN_XML=$(mktemp)
TMP_HOSTS=$(mktemp)
TMP_NOTES=$(mktemp)

echo "🛰️  Scanning $SUBNET..."
nmap $NMAP_ARGS $SUBNET -oX "$TMP_SCAN_XML" > /dev/null

# Convert detailed scan
python3 "$SCRIPTS_DIR/nmap_xml_to_md.py" --input "$TMP_SCAN_XML" --output "$SCAN_FILE" 2>/dev/null || true

# ------------------------
# Extract existing notes safely
# ------------------------
if [[ -f "$HOSTS_FILE" ]]; then
  echo "💾 Extracting existing notes..."
  grep '^|' "$HOSTS_FILE" | tail -n +3 | while IFS='|' read -r _ _ _ _ _ _ note _ count; do
    note=$(echo "$note" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    ip=$(echo "$_") # We'll overwrite in rebuild loop
    echo "$ip,$note"
  done > "$TMP_NOTES"
else
  > "$TMP_NOTES"
fi

# ------------------------
# Rebuild hosts.md
# ------------------------
echo "🧩 Building hosts table..."

{
  echo "# Hosts"
  echo
  echo "| Notes | Hostname | OS | Status | Link | # |"
  echo "|-------|----------|----|--------|------|---|"
} > "$TMP_HOSTS"

count=1
xmlstarlet sel -t \
  -m "//host[status/@state='up']" \
  -v "concat(address[@addrtype='ipv4']/@addr, '|', hostnames/hostname[1]/@name, '|', os/osmatch[1]/@name)" -n \
  "$TMP_SCAN_XML" | sort -u | while IFS='|' read -r ip hostname os; do
    [[ -z "$ip" ]] && continue
    hostname=${hostname:-Unknown}
    # Strip trailing .lan if present
    hostname=$(echo "$hostname" | sed -E 's/\.lan$//I')
    os=${os:-Unknown}
    status="Online"

    # Pick first open web port for the link
    port=$(xmlstarlet sel -t -m "//host[address/@addr='$ip']/ports/port[state/@state='open']/@portid" -v . -n "$TMP_SCAN_XML" | grep -E '80|443|8000|8080' | head -n1)
    if [[ -n "$port" ]]; then
        link="http://$ip:$port"
    else
        link="http://$ip"
    fi

    # Lookup note for this IP from CSV
    note=$(grep -m1 "^$ip," "$TMP_NOTES" | cut -d',' -f2-)
    note=${note:-""}

    echo "| $note | $hostname | $os | $status | [$link]($link) | $count |" >> "$TMP_HOSTS"
    count=$((count+1))
done

# Backup & replace
if [[ -f "$HOSTS_FILE" ]]; then
  cp "$HOSTS_FILE" "$HOSTS_FILE.bak"
  echo "🗂️  Backup saved: $HOSTS_FILE.bak"
fi

mv "$TMP_HOSTS" "$HOSTS_FILE"
chown cos:cos "$HOSTS_FILE"
chmod 644 "$HOSTS_FILE"

rm -f "$TMP_SCAN_XML" "$TMP_NOTES"

echo "✅ Done! Hosts updated, notes preserved."
