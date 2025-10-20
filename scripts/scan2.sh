#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# scan_and_update.sh
# Wrapper to run nmap scan and update mkdocs markdown file

set -euo pipefail

# CONFIG - adjust as needed
WORKDIR="/home/cos/material/mkdocs_dev_material"
DOCS_DIR="$WORKDIR/docs"
OUTPUT_XML="/tmp/nmap_scan.xml"
OUTPUT_MD="$DOCS_DIR/scan_results.md"
SUBNET="192.168.1.0/24"      # change to your subnet
#NMAP_ARGS="-sS -O -Pn -p 22,53,80,111,135,139,445,443,8000,8080"  # tcp SYN scan + OS + common ports
NMAP_ARGS="-sS -O -Pn -T4 --open -p 22,53,80,111,135,139,445,443,8000,8080"
# -Pn: treat hosts as up (skip host discovery) -> change to remove if you want initial ping discovery
# You can adjust ports list as needed.

# ensure scripts dir exists
mkdir -p "$WORKDIR/scripts"

# run nmap
echo "Running nmap scan of $SUBNET ..."
# Use sudo if needed; -O requires root for OS detection
sudo nmap $NMAP_ARGS -oX "$OUTPUT_XML" "$SUBNET"

# parse xml -> markdown via python script (next file)
python3 "$WORKDIR/scripts/nmap_xml_to_md.py" --input "$OUTPUT_XML" --output "$OUTPUT_MD"

echo "Scan done. Markdown updated at $OUTPUT_MD"
