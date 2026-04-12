#!/bin/bash
# scan_and_update_v2.sh - Improved network scan with /etc/hosts hostname resolution
set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# CONFIG
WORKDIR="/home/cos/material/mkdocs_dev_material"
DOCS_DIR="$WORKDIR/docs"
OUTPUT_XML="/tmp/nmap_scan.xml"
OUTPUT_MD="$DOCS_DIR/scan_results.md"
SUBNET="192.168.1.0/24"
NMAP_ARGS="-sS -O -Pn -T3 -p 22,53,80,111,135,139,443,445,554,3000,8000,8006,8080,8086,9090,9100,9221"

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
hosts_file = Path("/etc/hosts")

# Custom service name overrides
SERVICE_NAMES = {
    "22":   "ssh",
    "53":   "dns",
    "80":   "http",
    "111":  "rpcbind",
    "135":  "msrpc",
    "139":  "netbios",
    "443":  "https",
    "445":  "smb",
    "554":  "rtsp",
    "3000": "grafana",
    "8000": "http-alt",
    "8006": "proxmox",
    "8080": "http-proxy",
    "8086": "influxdb",
    "9090": "prometheus",
    "9100": "node-exporter",
    "9221": "pve-exporter",
}

# OS override based on hostname suffix
def get_os(hostname, detected_os):
    h = hostname.lower()
    if h.endswith('-deb'):
        return 'Debian/Ubuntu Linux'
    elif h.endswith('-rpm'):
        return 'RHEL/Rocky/Alma Linux'
    elif h.endswith('-win'):
        return 'Windows'
    elif h.endswith('-bsd'):
        return 'FreeBSD'
    elif h.endswith('-net'):
        return 'Network Device'
    elif h.endswith('-media'):
        return 'Media Device'
    elif h.endswith('-droid'):
        return 'Android'
    elif h.endswith('-mac'):
        return 'macOS'
    elif h.endswith('-vip'):
        return 'Virtual IP'
    else:
        return detected_os

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

def ip_key(ip):
    try:
        return tuple(int(p) for p in ip.split("."))
    except:
        return (0, 0, 0, 0)

# Build IP -> hostname map from /etc/hosts
hosts_map = {}
with hosts_file.open() as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) >= 2:
            ip = parts[0]
            hostname = parts[1]
            if re.match(r"^\d+\.\d+\.\d+\.\d+$", ip):
                hosts_map[ip] = hostname

# Parse nmap XML
tree = ET.parse(input_xml)
root = tree.getroot()
hosts = []

for host in root.findall("host"):
    addr_info = {}
    for a in host.findall("address"):
        addr_info[a.attrib.get("addrtype")] = a.attrib.get("addr")

    ip = addr_info.get("ipv4", "")
    mac = valid_mac(addr_info.get("mac", ""))

    # Use /etc/hosts for hostname first, fall back to nmap DNS, then unknown
    hostname = hosts_map.get(ip, "")
    if not hostname:
        hostnames = host.find("hostnames")
        if hostnames is not None:
            hn = hostnames.find("hostname")
            if hn is not None:
                hostname = clean_text(hn.attrib.get("name"))
    if not hostname:
        hostname = f"unknown-{ip}" if ip else "unknown"

    # OS detection with suffix override
    detected_os = "Unknown"
    os_elem = host.find("os")
    if os_elem is not None:
        osmatch = os_elem.find("osmatch")
        if osmatch is not None:
            detected_os = clean_text(osmatch.attrib.get("name", "Unknown"))
    os_name = get_os(hostname, detected_os)

    # Ports - only show open ports with friendly service names
    ports_list = []
    ports_elem = host.find("ports")
    if ports_elem is not None:
        for port in ports_elem.findall("port"):
            portid = port.attrib.get("portid", "")
            state_elem = port.find("state")
            state = state_elem.attrib.get("state", "") if state_elem is not None else ""
            if state != "open":
                continue
            service = SERVICE_NAMES.get(portid, "")
            if not service:
                service_elem = port.find("service")
                service = service_elem.attrib.get("name", "") if service_elem is not None else ""
            port_str = f"{portid}/{service}".strip("/")
            if port_str:
                ports_list.append(clean_text(port_str))

    hosts.append({
        "ip": ip,
        "hostname": hostname,
        "os": os_name,
        "ports": ", ".join(ports_list) if ports_list else "none detected",
        "mac": mac
    })

hosts.sort(key=lambda h: ip_key(h["ip"]))

with output_md.open("w") as f:
    f.write(f"# Network Scan Results\n\n")
    f.write(f"_Last updated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}_\n\n")
    f.write(f"_Hosts found: {len(hosts)}_\n\n")
    f.write("## Status\n\n")
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

print(f"✅ Scan complete. {len(hosts)} hosts found. Markdown updated: {output_md}")
EOF

echo "✅ Done."

