#!/bin/bash
# scan_and_update.sh - Reliable network scan with clean markdown output
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

echo "🛰️ Scanning $SUBNET ..."

sudo nmap $NMAP_ARGS -oX "$OUTPUT_XML" "$SUBNET"

echo "📄 Generating markdown..."

python3 - <<'EOF'
import xml.etree.ElementTree as ET
from pathlib import Path
import datetime
import re

input_xml = Path("/tmp/nmap_scan.xml")
output_md = Path("/home/cos/material/mkdocs_dev_material/docs/scan_results.md")

def clean_text(text):
    if not text:
        return ""
    return str(text).replace("\n", " ").replace("|", " ").strip()

def valid_mac(mac):
    if not mac:
        return ""
    mac = mac.strip()
    if re.match(r"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$", mac):
        return mac
    return ""

tree = ET.parse(input_xml)
root = tree.getroot()

hosts = []

for host in root.findall("host"):
    addr_info = {}
    for a in host.findall("address"):
        addr_info[a.attrib.get("addrtype")] = a.attrib.get("addr")

    ip = addr_info.get("ipv4", "")
    mac = valid_mac(addr_info.get("mac", ""))

    # Hostname
    hostname = ""
    hostnames = host.find("hostnames")
    if hostnames is not None:
        hn = hostnames.find("hostname")
        if hn is not None:
            hostname = clean_text(hn.attrib.get("name"))

    if not hostname:
        hostname = f"unknown-{ip}" if ip else "unknown"

    # OS detection (safe fallback)
    os_name = "Unknown"
    os_elem = host.find("os")
    if os_elem is not None:
        osmatch = os_elem.find("osmatch")
        if osmatch is not None:
            os_name = clean_text(osmatch.attrib.get("name", "Unknown"))

    # Ports
    ports_list = []
    ports_elem = host.find("ports")
    if ports_elem is not None:
        for port in ports_elem.findall("port"):
            portid = port.attrib.get("portid", "")
            proto = port.attrib.get("protocol", "")

            state_elem = port.find("state")
            state = state_elem.attrib.get("state", "") if state_elem is not None else ""

            service_elem = port.find("service")
            service = service_elem.attrib.get("name", "") if service_elem is not None else ""

            port_str = f"{portid}/{proto} {state} {service}".strip()
            if port_str:
                ports_list.append(clean_text(port_str))

    hosts.append({
        "ip": ip,
        "hostname": hostname,
        "os": os_name,
        "ports": ", ".join(ports_list),
        "mac": mac
    })

# Sort safely by IP
def ip_key(ip):
    try:
        return tuple(int(p) for p in ip.split("."))
    except:
        return (0,0,0,0)

hosts.sort(key=lambda h: ip_key(h["ip"]))

with output_md.open("w") as f:
    f.write(f"# Network Scan Results\n\n")
    f.write(f"_Last updated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}_\n\n")

    f.write("| IP Address | Hostname | Operating System | Open Ports | MAC Address |\n")
    f.write("|------------|----------|-----------------|------------|-------------|\n")

    for h in hosts:
        f.write(
            f"| {clean_text(h['ip'])} | "
            f"{clean_text(h['hostname'])} | "
            f"{clean_text(h['os'])} | "
            f"{clean_text(h['ports'])} | "
            f"{clean_text(h['mac'])} |\n"
        )

print(f"✅ Scan complete. Markdown updated: {output_md}")
EOF

echo "✅ Done."
