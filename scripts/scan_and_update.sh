#!/bin/bash
# scan_and_update.sh - Full network scan with progress and markdown output
# Preserves hosts.md notes
set -euo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# CONFIG
WORKDIR="/home/cos/material/mkdocs_dev_material"
DOCS_DIR="$WORKDIR/docs"
OUTPUT_XML="/tmp/nmap_scan.xml"
OUTPUT_MD="$DOCS_DIR/scan_results.md"
SUBNET="192.168.1.0/24"
NMAP_ARGS="-sS -O -Pn -T4 --open -p 22,53,80,111,135,139,445,443,8000,8080"

mkdir -p "$DOCS_DIR"

# Step 1: Run nmap scan
echo "🛰️  Scanning $SUBNET ..."
sudo nmap $NMAP_ARGS -oX "$OUTPUT_XML" "$SUBNET"

# Step 2: Parse XML and build Markdown with progress
echo "📄  Generating markdown..."

python3 - <<'EOF'
import xml.etree.ElementTree as ET
import sys
from pathlib import Path
import datetime

input_xml = Path("/tmp/nmap_scan.xml")
output_md = Path("/home/cos/material/mkdocs_dev_material/docs/scan_results.md")

tree = ET.parse(input_xml)
root = tree.getroot()

hosts = []
for host in root.findall("host"):
    addr_info = {a.attrib["addrtype"]: a.attrib["addr"] for a in host.findall("address")}
    ip = addr_info.get("ipv4", "")
    mac = addr_info.get("mac", "")
    
    # Hostname
    hostname = ""
    hostnames = host.find("hostnames")
    if hostnames is not None:
        hlist = hostnames.findall("hostname")
        if hlist:
            hostname = hlist[0].attrib.get("name", "")
    
    # OS
    os_name = ""
    os_elem = host.find("os/osmatch")
    if os_elem is not None:
        os_name = os_elem.attrib.get("name", "")
    
    # Ports
    ports = []
    ports_elem = host.find("ports")
    if ports_elem is not None:
        for port in ports_elem.findall("port"):
            state = port.find("state")
            service = port.find("service")
            port_str = f"{port.attrib.get('portid')}/{port.attrib.get('protocol')} {state.attrib.get('state') if state is not None else ''}"
            if service is not None:
                port_str += f" {service.attrib.get('name','')}"
            ports.append(port_str)
    
    hosts.append({
        "ip": ip,
        "hostname": hostname,
        "os": os_name,
        "ports": ", ".join(ports),
        "mac": mac
    })

total = len(hosts)
with output_md.open("w") as f:
    f.write("| IP Address | Hostname | Operating System | Open Ports | MAC Address |\n")
    f.write("|------------|----------|-----------------|------------|-------------|\n")
    for i, h in enumerate(hosts, start=1):
        f.write(f"| {h['ip']} | {h['hostname']} | {h['os']} | {h['ports']} | {h['mac']} |\n")
        # Progress percentage
        percent = int(i / total * 100)
        print(f"\rProgress: {percent}% ({i}/{total})", end="", flush=True)
    print(f"\n_Last update: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}_")
EOF

echo "✅ Scan complete. Markdown updated at $OUTPUT_MD"
