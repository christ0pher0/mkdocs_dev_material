#!/bin/bash
# File: scan_and_update.sh
# Purpose: Scan network and update Markdown tables for MkDocs

USER_HOME="/home/cos"
DOCS_DIR="$USER_HOME/material/mkdocs_dev_material/docs"
SCAN_FILE="$DOCS_DIR/scan_results.md"
HOSTS_FILE="$DOCS_DIR/hosts.md"
NETWORK="192.168.1.0/24"

echo "🛰️ Scanning $NETWORK..."
nmap -O -sS -p 22,80,443,139,445,8080 "$NETWORK" -oG - | awk '
/Up$/{ip=$2}
/Ports:/{sub(/.*Ports: /,""); ports=$0}
/OS details:/{os=$3 " " $4 " " $5}
/Nmap scan report for/{name=$5}
/MAC Address:/{mac=$3}
/Host:/{
  if(ip) {
    print "| " ip " | " name " | " os " | " ports " | " mac " |"
    ip=""; name=""; os=""; ports=""; mac="";
  }
}' > "$SCAN_FILE"

# Append update time
echo "_Last update: $(date)_" >> "$SCAN_FILE"

echo "📄 Generating $HOSTS_FILE..."

{
  echo "# Hosts"
  echo
  echo "| Notes | Hostname | OS | Status | Link | # |"
  echo "|-------|----------|----|--------|------|---|"
  awk -F'|' '
    NR > 2 && NF >= 6 {
      gsub(/^ +| +$/, "", $2);  # Hostname
      gsub(/^ +| +$/, "", $3);  # OS
      gsub(/^ +| +$/, "", $1);  # IP
      if ($2 != "Hostname" && $2 != "") {
        printf("| | %s | %s | Online | [http://%s](http://%s) | %d |\n", $2, $3, $1, $1, NR-2);
      }
    }
  ' "$SCAN_FILE" | sort -t'|' -k2,2
} > "$HOSTS_FILE"

# Fix ownership/permissions
chown cos:cos "$SCAN_FILE" "$HOSTS_FILE" 2>/dev/null
chmod 644 "$SCAN_FILE" "$HOSTS_FILE"

echo "✅ Updated $SCAN_FILE and $HOSTS_FILE"
