#!/usr/bin/env python3
"""
generate_network_diagram.py
Reads inventory_auto and generates a Mermaid graph LR
for the mkdocs network diagram page.
"""

import re
import sys
from datetime import datetime
from pathlib import Path

INVENTORY_FILE = Path("/home/cos/ansible_dev/inventory_auto")
OUTPUT_FILE = Path("/home/cos/material/mkdocs_dev_material/docs/network_diagram.md")

GROUP_META = {
    "linux":   {"label": "Linux",   "os": "Linux"},
    "bsd":     {"label": "BSD",     "os": "BSD"},
    "windows": {"label": "Windows", "os": "Windows"},
    "network": {"label": "Network", "os": "Network Device"},
    "android": {"label": "Android", "os": "Android"},
    "tv":      {"label": "TV",      "os": "Smart TV"},
    "control": {"label": "Control", "os": "Linux"},
}

def parse_inventory(path):
    groups = {}
    current_group = None
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            group_match = re.match(r"^\[(.+)\]$", line)
            if group_match:
                current_group = group_match.group(1)
                groups[current_group] = []
            elif current_group:
                host_match = re.match(r"^(\S+)\s+ansible_host=(\S+)", line)
                if host_match:
                    groups[current_group].append((host_match.group(1), host_match.group(2)))
    return groups

def sanitize(name):
    return re.sub(r"[^a-zA-Z0-9_]", "_", name)

def generate_diagram(groups):
    lines = []
    lines.append("```mermaid")
    lines.append("graph LR")
    lines.append("")

    # Top level infrastructure
    lines.append("    ONT[ONT]")
    lines.append("    Router[Router]")
    lines.append("    Firewall[Firewall]")
    lines.append("    Switch[Switch]")
    lines.append("")
    lines.append("    ONT -->|Fiber Signal| Router")
    lines.append("    Router --> Firewall")
    lines.append("    Firewall --> Switch")
    lines.append("")

    # Group nodes and host nodes
    for group, hosts in groups.items():
        if not hosts:
            continue
        meta = GROUP_META.get(group, {"label": group.title(), "os": group.title()})
        group_node = "GRP_" + sanitize(group)
        group_label = meta["label"]
        lines.append(f"    {group_node}[{group_label}]")
        lines.append(f"    Switch --> {group_node}")
        lines.append("")

        for hostname, ip in hosts:
            safe = sanitize(hostname)
            os_label = meta["os"]
            lines.append(f'    {safe}["{hostname}<br/>{ip}<br/>{os_label}"]')
            lines.append(f"    {group_node} --> {safe}")
        lines.append("")

    # Styling
    lines.append("    classDef infra fill:#4a4a8a,stroke:#9999cc,color:#fff")
    lines.append("    classDef group fill:#2d6a4f,stroke:#74c69d,color:#fff")
    lines.append("    classDef linux fill:#1d3557,stroke:#457b9d,color:#fff")
    lines.append("    classDef windows fill:#6d3a3a,stroke:#c1666b,color:#fff")
    lines.append("    classDef bsd fill:#5c4a1e,stroke:#d4a017,color:#fff")
    lines.append("    classDef network fill:#3a3a3a,stroke:#888,color:#fff")
    lines.append("    classDef other fill:#4a2d5a,stroke:#9b72cf,color:#fff")
    lines.append("")
    lines.append("    class ONT,Router,Firewall,Switch infra")

    # Assign group and host styles
    for group, hosts in groups.items():
        if not hosts:
            continue
        group_node = "GRP_" + sanitize(group)
        lines.append(f"    class {group_node} group")
        style = {
            "linux": "linux", "control": "linux",
            "windows": "windows",
            "bsd": "bsd",
            "network": "network", "tv": "network",
        }.get(group, "other")
        for hostname, ip in hosts:
            lines.append(f"    class {sanitize(hostname)} {style}")

    lines.append("```")
    return "\n".join(lines)

def main():
    if not INVENTORY_FILE.exists():
        print(f"Error: inventory file not found at {INVENTORY_FILE}", file=sys.stderr)
        sys.exit(1)

    groups = parse_inventory(INVENTORY_FILE)
    diagram = generate_diagram(groups)

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    content = f"# Network Diagram\n\n_Last update: {timestamp}_\n\n{diagram}\n"

    OUTPUT_FILE.write_text(content)
    print(f"Network diagram written to {OUTPUT_FILE}")
    for group, hosts in groups.items():
        print(f"  {group}: {len(hosts)} hosts")

if __name__ == "__main__":
    main()

