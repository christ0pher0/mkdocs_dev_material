#!/bin/bash

INPUT_FILE="/home/cos/material/mkdocs_dev_material/docs/hosts.md"
OUTPUT_FILE="/home/cos/ansible_dev/hosts_inventory"

# Clear temp files
> "$OUTPUT_FILE.tmp.deb"
> "$OUTPUT_FILE.tmp.rpm"
> "$OUTPUT_FILE.tmp.bsd"
> "$OUTPUT_FILE.tmp.pi"

# Parse and classify using awk
awk -F '|' 'NR > 2 {
    hostname = $3; ip = $4; os = $6;
    gsub(/^[ \t]+|[ \t]+$/, "", hostname);
    gsub(/^[ \t]+|[ \t]+$/, "", ip);
    gsub(/^[ \t]+|[ \t]+$/, "", os);

    if (hostname != "" && ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
        entry = hostname " ansible_host=" ip " ansible_user=cos ansible_ssh_private_key_file=~/.ssh/id_ed25519"
        if (os ~ /FreeBSD/) {
            print entry >> "'$OUTPUT_FILE.tmp.bsd'"
        } else if (hostname ~ /pi|octopi/) {
            print entry >> "'$OUTPUT_FILE.tmp.pi'"
        } else if (os ~ /Rocky|Alma|rpm/) {
            print entry >> "'$OUTPUT_FILE.tmp.rpm'"
        } else if (os ~ /Linux/) {
            print entry >> "'$OUTPUT_FILE.tmp.deb'"
        }
    }
}' "$INPUT_FILE"

# Assemble final inventory
{
    echo "[deb]"
    cat "$OUTPUT_FILE.tmp.deb"
    echo ""
    echo "[rpm]"
    cat "$OUTPUT_FILE.tmp.rpm"
    echo ""
    echo "[bsd]"
    cat "$OUTPUT_FILE.tmp.bsd"
    echo ""
    echo "[pi]"
    cat "$OUTPUT_FILE.tmp.pi"
    echo ""
    echo "[linux:children]"
    echo "deb"
    echo "rpm"
    echo "bsd"
    echo "pi"
} > "$OUTPUT_FILE"

# Cleanup
rm "$OUTPUT_FILE.tmp.deb" "$OUTPUT_FILE.tmp.rpm" "$OUTPUT_FILE.tmp.bsd" "$OUTPUT_FILE.tmp.pi"

echo "✅ Inventory created at: $OUTPUT_FILE"


