#!/usr/bin/env python3
import os
from ipaddress import ip_address

WORKDIR = os.path.expanduser("~/material/mkdocs_dev_material")
HOSTS_MD = os.path.join(WORKDIR, "docs/hosts.md")
INVENTORY_FILE = os.path.expanduser("~/ansible_dev/inventory_auto")

# Groups dict
groups = {
    "deb": [],
    "rpm": [],
    "pi": [],
    "windows": [],
    "bsd": [],
    "media": [],
    "misc": [],
    "mobile": []  # new group for macOS/iOS/Android
}

# Mapping from OS info to group
linux_groups = {"Linux": "deb"}  # default mapping for detection
mobile_os_keywords = ["macOS", "iOS", "Android"]

# Parse hosts.md
with open(HOSTS_MD, "r") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("|") is False:
            continue
        if line.startswith("| # |"):  # skip header
            continue
        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) < 7:
            continue
        hostname = parts[1].replace(".lan", "") if parts[1] else parts[0]
        ip = parts[2]
        os_info = parts[4]

        # skip IPs below 192.168.1.1
        try:
            if ip_address(ip) < ip_address("192.168.1.1"):
                continue
        except ValueError:
            continue

        # Determine group
        assigned_group = None
        os_lower = os_info.lower() if os_info else ""
        if "windows" in os_lower:
            assigned_group = "windows"
        elif "freebsd" in os_lower or "bsd" in os_lower:
            assigned_group = "bsd"
        elif any(x.lower() in os_lower for x in mobile_os_keywords):
            assigned_group = "mobile"
        elif "raspberry" in hostname.lower() or "pi" in hostname.lower():
            assigned_group = "pi"
        elif "linux" in os_lower:
            # Heuristic: if IP in your previous mapping, can decide deb/rpm
            # For now, fallback to deb
            assigned_group = "deb"
        else:
            assigned_group = "misc"

        if assigned_group not in groups:
            groups[assigned_group] = []

        groups[assigned_group].append(
            f"{hostname} ansible_host={ip} ansible_user=cos ansible_ssh_private_key_file=/home/cos/.ssh/id_ed25519"
        )

# Build linux:children combining deb, rpm, pi
linux_children = ["deb", "rpm", "pi"]

# Write inventory
with open(INVENTORY_FILE, "w") as f:
    for group, hosts in groups.items():
        if not hosts:
            continue
        f.write(f"[{group}]\n")
        for h in hosts:
            f.write(f"{h}\n")
        f.write("\n")

    # Add linux:children
    f.write("[linux:children]\n")
    for lg in linux_children:
        f.write(f"{lg}\n")
    f.write("\n")

print(f"Ansible inventory regenerated: {INVENTORY_FILE}")
