#!/usr/bin/env python3
"""
nmap_xml_to_md.py
Parse nmap -oX output and create a Markdown table.

Usage:
  python3 nmap_xml_to_md.py --input /tmp/nmap_scan.xml --output /home/cos/material/mkdocs_dev_material/docs/scan_results.md
"""

import argparse
import xml.etree.ElementTree as ET
from datetime import datetime
import html

def parse_nmap_xml(path):
    tree = ET.parse(path)
    root = tree.getroot()
    hosts = []
    for host in root.findall('host'):
        # get ip and mac
        addresses = host.findall('address')
        ip = ""
        mac = ""
        for a in addresses:
            addr = a.get('addr')
            atype = a.get('addrtype')
            if atype == 'ipv4' or atype == 'ipv6':
                ip = addr
            elif atype == 'mac':
                mac = addr

        # hostname (if any)
        hostname = ""
        hnames = host.find('hostnames')
        if hnames is not None:
            h = hnames.find('hostname')
            if h is not None:
                hostname = h.get('name', '')

        # OS (best-match)
        os_name = ""
        os = host.find('os')
        if os is not None:
            match = os.find('osmatch')
            if match is not None:
                os_name = match.get('name', '')

        # open ports - collect as "port/service (state)"
        port_list = []
        ports = host.find('ports')
        if ports is not None:
            for p in ports.findall('port'):
                state = p.find('state')
                if state is not None and state.get('state') == 'open':
                    portnum = p.get('portid')
                    proto = p.get('protocol')
                    svc = ""
                    service = p.find('service')
                    if service is not None:
                        svc = service.get('name', '')
                    port_list.append(f"{portnum}/{proto}{(' '+svc) if svc else ''}")

        # fallback: up/down
        status = host.find('status')
        if status is not None:
            st = status.get('state')
        else:
            st = 'unknown'

        hosts.append({
            'ip': ip,
            'hostname': hostname,
            'os': os_name,
            'ports': ", ".join(port_list) if port_list else "",
            'mac': mac,
            'state': st
        })
    return hosts

def write_md(hosts, outpath):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    header = f"# Network Scan Results\n\n_Last update: {now}_\n\n"
    header += "| IP Address | Hostname | Operating System | Open Ports | MAC Address |\n"
    header += "|------------|----------|------------------|------------|-------------|\n"
    lines = [header]
    for h in sorted(hosts, key=lambda x: x['ip'] or ''):
        ip = h['ip'] or ""
        hostname = html.escape(h['hostname'] or "")
        os_ = html.escape(h['os'] or "")
        ports = html.escape(h['ports'] or "")
        mac = h['mac'] or ""
        lines.append(f"| {ip} | {hostname} | {os_} | {ports} | {mac} |\n")
    with open(outpath, "w") as f:
        f.writelines(lines)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", "-i", required=True, help="Nmap XML input file")
    parser.add_argument("--output", "-o", required=True, help="Markdown output file")
    args = parser.parse_args()
    hosts = parse_nmap_xml(args.input)
    write_md(hosts, args.output)

if __name__ == "__main__":
    main()
