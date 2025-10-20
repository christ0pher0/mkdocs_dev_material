#!/usr/bin/env bash
#
# full_subnet_enrich_scan.sh
# Run local discovery (arp-scan / ip neigh), nmap service/os scan, reverse-dns,
# NBTS/mDNS when available, and produce docs/scan_results.md enriched summary.
#
# Requires: nmap (recommended), arp-scan (recommended), dig (bind9-dnsutils),
#           nbtscan (optional), avahi-browse (optional)
#
# Run as the user who can sudo when needed. Output goes to $DOCS_DIR/scan_results.md
set -euo pipefail

#######################################
# Configuration - edit to taste
#######################################
WORKDIR="${WORKDIR:-/home/cos/material/mkdocs_dev_material}"
DOCS_DIR="$WORKDIR/docs"
SUBNET="${SUBNET:-192.168.1.0/24}"
# ports we care about (tune as needed)
PORTS="${PORTS:-22,53,80,111,135,139,445,443,8000,8080}"
# nmap args (service/version + os detection)
NMAP_ARGS="${NMAP_ARGS:--sS -sV -O -T4 --open -p $PORTS}"
# temp files
TS=$(date +"%Y%m%d_%H%M%S")
TMPDIR="/tmp/subnet_scan_$TS"
mkdir -p "$TMPDIR"
XML_OUT="$TMPDIR/nmap_scan.xml"
ARP_OUT="$TMPDIR/arp_scan.txt"
IPNEIGH_OUT="$TMPDIR/ip_neigh.txt"
PTR_OUT="$TMPDIR/ptrs.txt"
NBTS_OUT="$TMPDIR/nbtscan.txt"
MDNS_OUT="$TMPDIR/mdns.txt"
SCAN_MD="$DOCS_DIR/scan_results.md"
LOG="$TMPDIR/scan.log"

#######################################
# Helpers
#######################################
log() { printf '%s %s\n' "$(date +"%Y-%m-%d %H:%M:%S")" "$*" | tee -a "$LOG"; }

which_or_warn() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "WARN: $1 not found; skipping related step."
    return 1
  fi
  return 0
}

# find the interface for outbound traffic (used by arp-scan)
get_iface() {
  ip route get 8.8.8.8 2>/dev/null | awk '/dev/ { for(i=1;i<=NF;i++) if($i=="dev") print $(i+1) ; exit }'
}

#######################################
# Ensure docs dir exists
#######################################
mkdir -p "$DOCS_DIR"
log "Working dir: $WORKDIR. Docs dir: $DOCS_DIR. Temp dir: $TMPDIR"

#######################################
# 1) ARP-scan (best local MAC/vendor info)
#######################################
if which_or_warn arp-scan; then
  IFACE=$(get_iface || true)
  if [[ -n "$IFACE" ]]; then
    log "Running arp-scan on interface $IFACE (localnet)..."
    sudo arp-scan --interface="$IFACE" --localnet > "$ARP_OUT" 2>>"$LOG" || log "arp-scan completed with non-zero exit"
  else
    log "Could not determine interface; running arp-scan default"
    sudo arp-scan --localnet > "$ARP_OUT" 2>>"$LOG" || log "arp-scan completed with non-zero exit"
  fi
else
  log "Skipping arp-scan (not installed)."
  echo "" > "$ARP_OUT"
fi

#######################################
# 2) Kernel neighbor table (ip neigh)
#######################################
log "Capturing kernel neighbor table (ip neigh)..."
ip neigh show > "$IPNEIGH_OUT" 2>>"$LOG" || true

#######################################
# 3) Nmap scan (XML) - service + OS
#######################################
if which_or_warn nmap; then
  log "Running nmap: sudo nmap $NMAP_ARGS -oX $XML_OUT $SUBNET"
  sudo nmap $NMAP_ARGS -oX "$XML_OUT" "$SUBNET" 2>>"$LOG" || log "nmap completed with non-zero exit"
else
  log "ERROR: nmap missing; cannot proceed with service/os scan."
  exit 1
fi

#######################################
# 4) NBTSCAN (NetBIOS names) - optional
#######################################
if which_or_warn nbtscan; then
  log "Running nbtscan..."
  sudo nbtscan -q "$SUBNET" > "$NBTS_OUT" 2>>"$LOG" || true
else
  echo "" > "$NBTS_OUT"
fi

#######################################
# 5) mDNS/Zeroconf (avahi-browse) - optional
#######################################
if which_or_warn avahi-browse; then
  log "Running avahi-browse for mDNS entries (may take a few seconds)..."
  avahi-browse -a -t 2>/dev/null | sed -n 's/.*;hostname=.*//p' > "$MDNS_OUT" || true
else
  echo "" > "$MDNS_OUT"
fi

#######################################
# 6) Reverse PTR lookups for discovered IPs
#    We'll extract IPs from nmap xml first and query via dig
#######################################
if which_or_warn dig; then
  log "Extracting IPs from nmap XML and doing reverse DNS (PTR) lookups..."
  # parse IPs from xml safely
  python3 - <<'PY' > "$PTR_OUT"
import xml.etree.ElementTree as ET, sys
xml = "$XML_OUT"
ips = set()
try:
    tree = ET.parse(xml)
    for host in tree.findall("host"):
        for addr in host.findall("address"):
            if addr.get("addrtype") == "ipv4":
                ips.add(addr.get("addr"))
except Exception as e:
    pass
for ip in sorted(ips):
    print(ip)
PY
  # run dig -x in parallel-ish (xargs)
  rm -f "$PTR_OUT.tmp"
  cat "$PTR_OUT" | xargs -n1 -P20 -I{} sh -c 'dig +short -x {} | sed -n "1p" | awk "{print \"{}|\" \$0}"' >> "$PTR_OUT.tmp" || true
  # ensure every IP is present even if no PTR
  cat "$PTR_OUT" | while read -r ip; do
    if ! grep -q "^$ip|" "$PTR_OUT.tmp" 2>/dev/null; then
      echo "$ip|" >> "$PTR_OUT.tmp"
    fi
  done
  mv "$PTR_OUT.tmp" "$PTR_OUT"
else
  log "dig not found; skipping PTR lookups."
  echo "" > "$PTR_OUT"
fi

#######################################
# 7) Parse & merge sources -> Markdown
#    We'll hand off to an embedded Python block to parse nmap XML + arp + ip neigh + ptr + nbtscan + mdns
#######################################
log "Merging data and writing $SCAN_MD ..."

python3 - <<'PY'
import xml.etree.ElementTree as ET
import ipaddress
from pathlib import Path
from datetime import datetime

# Paths from environment (passed via heredoc)
XML = Path("$XML_OUT")
ARP = Path("$ARP_OUT")
IPNEIGH = Path("$IPNEIGH_OUT")
PTRS = Path("$PTR_OUT")
NBTS = Path("$NBTS_OUT")
MDNS = Path("$MDNS_OUT")
OUT = Path("$SCAN_MD")

def parse_arp_scan(path):
    d = {}
    try:
        for line in path.read_text().splitlines():
            # typical arp-scan: "192.168.1.1    94:83:C4:AA:EE:FF    Vendor Name"
            parts = line.split()
            if len(parts) >= 2 and parts[0].count('.')==3 and ':' in parts[1]:
                ip = parts[0].strip()
                mac = parts[1].strip()
                vendor = " ".join(parts[2:]).strip() if len(parts) > 2 else ""
                d[ip] = {"mac": mac, "vendor": vendor}
    except Exception:
        pass
    return d

def parse_ip_neigh(path):
    d = {}
    try:
        for line in path.read_text().splitlines():
            # example: "192.168.1.1 dev eth0 lladdr 94:83:C4:AA:EE:FF REACHABLE"
            toks = line.split()
            if not toks: continue
            ip = toks[0]
            mac = ""
            state = ""
            if "lladdr" in toks:
                i = toks.index("lladdr")
                mac = toks[i+1] if i+1 < len(toks) else ""
            # state is last tok
            state = toks[-1]
            if ip.count('.')==3:
                d[ip] = {"mac": mac, "state": state}
    except Exception:
        pass
    return d

def parse_ptrs(path):
    d = {}
    try:
        for line in path.read_text().splitlines():
            if not line.strip(): continue
            if "|" in line:
                ip, name = line.split("|",1)
                d[ip.strip()] = name.strip().rstrip(".")
    except Exception:
        pass
    return d

def parse_nbtscan(path):
    d = {}
    try:
        for line in path.read_text().splitlines():
            # nbtscan output often: "192.168.1.5  HOSTNAME   <00> UNIQUE   ... "
            parts = line.split()
            if parts and parts[0].count(".")==3:
                ip = parts[0]
                # find candidate hostname (next token that's not empty)
                if len(parts) >= 2:
                    name = parts[1]
                    d[ip] = name
    except Exception:
        pass
    return d

def parse_mdns(path):
    d = {}
    try:
        for line in path.read_text().splitlines():
            if not line.strip(): continue
            # best-effort; many formats - we try to find ip and hostname tokens
            # leave empty - we won't rely heavily on mdns here
            pass
    except Exception:
        pass
    return d

def parse_nmap_xml(path):
    hosts = {}
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        for host in root.findall("host"):
            ip = ""
            mac = ""
            hostname = ""
            osname = ""
            ports = []
            for addr in host.findall("address"):
                if addr.get("addrtype") == "ipv4":
                    ip = addr.get("addr")
                if addr.get("addrtype") == "mac":
                    mac = addr.get("addr")
            hostnames = host.find("hostnames")
            if hostnames is not None:
                hlist = hostnames.findall("hostname")
                if hlist:
                    hostname = hlist[0].attrib.get("name","")
            os_elem = host.find("os")
            if os_elem is not None:
                m = os_elem.find("osmatch")
                if m is not None:
                    osname = m.attrib.get("name","")
            ports_elem = host.find("ports")
            if ports_elem is not None:
                for p in ports_elem.findall("port"):
                    state = p.find("state")
                    service = p.find("service")
                    portid = p.attrib.get("portid","")
                    proto = p.attrib.get("protocol","")
                    st = state.attrib.get("state","") if state is not None else ""
                    svc = service.attrib.get("name","") if service is not None else ""
                    ports.append(f"{portid}/{proto} {st} {svc}".strip())
            if ip:
                hosts[ip] = {
                    "ip": ip,
                    "hostname": hostname,
                    "os": osname,
                    "ports": ", ".join(ports),
                    "mac": mac
                }
    except Exception:
        pass
    return hosts

arp_data = parse_arp_scan(ARP)
neigh_data = parse_ip_neigh(IPNEIGH)
ptr_data = parse_ptrs(PTRS)
nbt_data = parse_nbtscan(NBTS)
mdns_data = parse_mdns(MDNS)
nmap_hosts = parse_nmap_xml(XML)

# union of IPs seen across sources
ips = set()
ips.update(nmap_hosts.keys())
ips.update(arp_data.keys())
ips.update(neigh_data.keys())
ips.update(ptr_data.keys())
ips.update(nbt_data.keys())

def choose_hostname(ip):
    # priority: nmap hostname, PTR, nbtscan, mdns, ip
    if ip in nmap_hosts and nmap_hosts[ip].get("hostname"):
        return nmap_hosts[ip]["hostname"]
    if ip in ptr_data and ptr_data[ip]:
        return ptr_data[ip]
    if ip in nbt_data and nbt_data[ip]:
        return nbt_data[ip]
    # mdns not parsed in-depth; fallback to ip
    return ""

rows = []
for ip in sorted(ips, key=lambda x: ipaddress.ip_address(x)):
    row = {
        "ip": ip,
        "hostname": choose_hostname(ip) or "",
        "os": nmap_hosts.get(ip, {}).get("os",""),
        "ports": nmap_hosts.get(ip, {}).get("ports",""),
        "mac": nmap_hosts.get(ip, {}).get("mac",""),
        "vendor": "",
        "state": neigh_data.get(ip,{}).get("state","")
    }
    # fill mac from arp or neigh if missing
    if not row["mac"]:
        if ip in arp_data and arp_data[ip].get("mac"):
            row["mac"] = arp_data[ip]["mac"]
            row["vendor"] = arp_data[ip].get("vendor","")
        elif ip in neigh_data and neigh_data[ip].get("mac"):
            row["mac"] = neigh_data[ip]["mac"]
    # vendor from arp if not present
    if not row["vendor"] and ip in arp_data:
        row["vendor"] = arp_data[ip].get("vendor","")
    rows.append(row)

# write markdown file with timestamp and table
now = datetime.now().strftime("%a %b %d %I:%M:%S %p %Z %Y")
with OUT.open("w") as f:
    f.write(f"_Last update: {now}_\n\n")
    f.write("| IP Address | Hostname | Operating System | Open Ports | MAC Address | Vendor | State |\n")
    f.write("|------------|----------|------------------|------------|-------------|--------|-------|\n")
    for r in rows:
        f.write(f"| {r['ip']} | {r['hostname']} | {r['os']} | {r['ports']} | {r['mac']} | {r['vendor']} | {r['state']} |\n")
print("WROTE", OUT)
PY

log "Finished writing $SCAN_MD"
log "Raw outputs in $TMPDIR (keep for debugging)."
log "Scan complete."
