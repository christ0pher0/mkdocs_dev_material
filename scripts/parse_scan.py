#!/usr/bin/env python3
import re
import os
from ipaddress import ip_address
from datetime import datetime

WORKDIR = os.path.expanduser("/home/cos/material/mkdocs_dev_material")
SCAN_MD = os.path.join(WORKDIR, "docs/scan_results.md")
HOSTS_MD = os.path.join(WORKDIR, "docs/hosts.md")

# Load previous notes from hosts.md
previous_notes = {}
if os.path.exists(HOSTS_MD):
    with open(HOSTS_MD, "r") as f:
        lines = f.readlines()
    for line in lines[3:]:  # skip header + separator + timestamp line
        cols = [c.strip() for c in line.strip().split("|")]
        if len(cols) >= 6:
            previous_notes[cols[1]] = cols[5]

hosts = []

# Parse scan_results.md
with open(SCAN_MD, "r") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("| IP Address") or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) < 5:
            continue

        ip = parts[0]
        hostname = parts[1].replace(".lan", "") if parts[1] else ip
        os_info = parts[2] if len(parts) > 2 else ""
        mac = parts[4]

        # skip IPs below 192.168.1.1
        try:
            if ip_address(ip) < ip_address("192.168.1.1"):
                continue
        except ValueError:
            continue

        notes = previous_notes.get(hostname, "------")

        hosts.append({
            "hostname": hostname,
            "ip": ip,
            "mac": mac,
            "os": os_info,
            "status": "Online",
            "notes": notes
        })

# Sort hosts by IP
hosts.sort(key=lambda h: ip_address(h["ip"]))

# Write hosts.md with timestamp
timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
with open(HOSTS_MD, "w") as f:
    f.write(f"# Hosts\n")
    f.write(f"_Last update: {timestamp}_\n\n")
    f.write("| # | Hostname | IP Address | MAC Address | OS | Status | Notes |\n")
    f.write("|---|----------|------------|------------|----|--------|-------|\n")
    for i, h in enumerate(hosts, start=1):
        f.write(f"| {i} | {h['hostname']} | {h['ip']} | {h['mac']} | {h['os']} | {h['status']} | {h['notes']} |\n")

print(f"Hosts Markdown updated: {HOSTS_MD}")
