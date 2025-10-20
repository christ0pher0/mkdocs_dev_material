#!/bin/bash
# scan_and_update.sh - Full network scan with timestamp and markdown output
# Preserves hosts.md notes
set -euo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# CONFIG
WORKDIR="/home/cos/material/mkdocs_dev_material"
DOCS_DIR="$WORKDIR/docs"
OUTPUT_XML="/tmp/nmap_scan.xml"
OUTPUT_MD="$DOCS_DIR/scan_results.md"
SUBNET="192.168.1.0/24"
NMAP_ARGS="-sS -O -Pn -T4 -p 22,53,80,111,135,139,445,443,8000,8080"

mkdir -p "$DOCS_DIR"

# Step 1: Run nmap scan
echo "🛰️  Scanning $SUBNET ..."
sudo nmap $NMAP_ARGS -oX "$OUTPUT_XML" "$SUBNET"

# Step 2: Parse XML and build Markdown
echo "📄  Generating markdown..."

python3 - <<'EOF'
import xml.etree.ElementTree as ET
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

    # Hostname (fallback if missing)
    hostname = ""
    hostnames = host.find("hostnames")
    if hostnames is not None:
        hlist = hostnames.findall("hostname")
        if hlist:
            hostname = hlist[0].attrib.get("name", "")
    if not hostname:
        hostname = f"unknown-{ip}" if ip else "unknown"

    # OS detection
    os_name = ""
    os_elem = host.find("os/osmatch")
    if os_elem is not None:
        os_name = os_elem.attrib.get("name", "Unknown OS")

    # Ports
    ports = []
    ports_elem = host.find("ports")
    if ports_elem is not None:
        for port in ports_elem.findall("port"):
            state = port.find("state")
            service = port.find("service")
            port_str = f"{port.attrib.get('portid')}/{port.attrib.get('protocol')} {state.attrib.get('state', '')}"
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

hosts.sort(key=lambda h: tuple(int(p) for p in h["ip"].split(".")) if h["ip"] else (0,0,0,0))

with output_md.open("w") as f:
    f.write(f"# Network Scan Results\n\n_Last updated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}_\n\n")
    f.write("| IP Address | Hostname | Operating System | Open Ports | MAC Address |\n")
    f.write("|------------|----------|-----------------|------------|-------------|\n")
    for h in hosts:
        f.write(f"| {h['ip']} | {h['hostname']} | {h['os']} | {h['ports']} | {h['mac']} |\n")

print(f"✅ Scan complete. Markdown updated: {output_md}")
EOF

echo "✅ Done — Markdown updated with all hosts, including unnamed ones."
