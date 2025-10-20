#!/usr/bin/env python3
import re
import os
import argparse
from ipaddress import ip_address

# -------------------------
# CONFIG
# -------------------------
WORKDIR = os.path.expanduser("~/material/mkdocs_dev_material")
SCAN_MD = os.path.join(WORKDIR, "docs/scan_results.md")
HOSTS_MD = os.path.join(WORKDIR, "docs/hosts.md")

# -------------------------
# Parse command-line args
# -------------------------
parser = argparse.ArgumentParser(description="Parse scan_results.md into hosts.md")
parser.add_argument("--input", default=SCAN_MD, help="Input scan_results.md")
parser.add_argument("--output", default=HOSTS_MD, help="Output hosts.md")
args = parser.parse_args()

# -------------------------
# Load previous notes
# -------------------------
previous_notes = {}
if os.path.exists(args.output):
    with open(args.output, "r") as f:
        lines = f.readlines()
    for line in lines[2:]:  # skip header and separator
        cols = [c.strip() for c in line.strip().split("|")]
        if len(cols) >= 7:
            hostname = cols[1]
            notes = cols[6]
            previous_notes[hostname] = notes

# -------------------------
# Parse scan_results.md
# -------------------------
hosts = []
hosts_missing_info = []

with open(args.input, "r") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("| IP Address") or line.startswith("#"):
            continue

        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) < 5:
            continue

        ip = parts[0].strip()
        hostname = parts[1].replace(".lan", "").strip()
        mac = parts[4].strip()
        open_ports = parts[3].strip()

        # skip anything below 192.168.1.1
        try:
            ip_obj = ip_address(ip)
            if ip_obj < ip_address("192.168.1.1"):
                continue
        except ValueError:
            ip_obj = None

        # Determine link
        link = ""
        if re.search(r"80/open|443/open", open_ports):
            link = f"http://{ip}"

        # Notes
        notes = previous_notes.get(hostname, "------")

        host_entry = {
            "hostname": hostname,
            "ip": ip,
            "mac": mac,
            "status": "Online",
            "link": link,
            "notes": notes
        }

        if not ip or not mac:
            hosts_missing_info.append(host_entry)
        else:
            hosts.append(host_entry)

# -------------------------
# Sort hosts
# -------------------------
def ip_sort_key(host):
    try:
        return ip_address(host["ip"])
    except Exception:
        return ip_address("255.255.255.255")  # place invalid IPs at end

hosts.sort(key=ip_sort_key)
hosts_missing_info.sort(key=lambda x: x["hostname"] or "")

# -------------------------
# Combine lists
# -------------------------
all_hosts = hosts + hosts_missing_info

# -------------------------
# Write Markdown table
# -------------------------
with open(args.output, "w") as f:
    f.write("# Hosts\n\n")
    f.write("| # | Hostname | IP Address | MAC Address | Status | Link | Notes |\n")
    f.write("|---|----------|------------|------------|--------|------|-------|\n")
    for i, host in enumerate(all_hosts, start=1):
        f.write(f"| {i} | {host['hostname']} | {host['ip']} | {host['mac']} | {host['status']} | {host['link']} | {host['notes']} |\n")

print(f"Hosts updated: {args.output}")
