
#!/bin/bash

# Output file
OUTPUT_FILE="scan_results.md"

# Write Markdown table header
echo "| IP Address | Hostname | Operating System | Open Ports |" > "$OUTPUT_FILE"
echo "|------------|----------|------------------|------------|" >> "$OUTPUT_FILE"

# Run nmap scan
sudo nmap -O -sS -oX scan_output.xml 192.168.1.0/24

# Parse XML output using xmllint and format into Markdown
xmllint --xpath "//host" scan_output.xml | \
grep -oP '(?<=<address addr=")[^"]+|(?<=<hostname name=")[^"]+|(?<=<osmatch name=")[^"]+|(?<=<port protocol="tcp" portid=")[^"]+' | \
awk '
BEGIN { FS="\n"; RS=""; OFS=" | " }
{
    ip = $1
    hostname = ($2 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) ? "-" : $2
    os = ($3 ~ /^[0-9]+$/) ? "-" : $3
    ports = ""
    for (i=4; i<=NF; i++) ports = ports $i ","
    sub(/,$/, "", ports)
    print "| " ip, hostname, os, ports " |"
}' >> "$OUTPUT_FILE"

echo "Scan complete. Results saved to $OUTPUT_FILE"

