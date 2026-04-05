#!/bin/bash

# Input and output paths
INPUT_FILE="/home/cos/material/mkdocs_dev_material/docs/hosts.md"
OUTPUT_FILE="/home/cos/ansible_dev/hosts_inventory"

# Create or overwrite the inventory file
echo "[all]" > "$OUTPUT_FILE"

# Parse Hostname and IP Address using awk
awk -F '|' 'NR > 2 {
    hostname = $3; ip = $4;
    gsub(/^[ \t]+|[ \t]+$/, "", hostname);
    gsub(/^[ \t]+|[ \t]+$/, "", ip);
    if (hostname != "" && ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/)
        print hostname " ansible_host=" ip;
}' "$INPUT_FILE" >> "$OUTPUT_FILE"

echo "✅ Inventory created at: $OUTPUT_FILE"


