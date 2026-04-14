# Network Context Document
_Paste this at the start of any new Claude session._
_Last updated: 2026-04-09_

---

## Network Overview

- **ISP:** FIOS (fiber ONT)
- **Router/Firewall:** GL.iNet Flint 2 (192.168.1.1) — OpenWrt-based, AdGuard Home enabled
- **Secondary firewall:** Netgate (192.168.1.6) — pfSense
- **Hypervisor:** Proxmox VE (192.168.1.2) — AMD Ryzen 5 1600, 56GB RAM (ASRock AB350M Pro4)
- **NAS:** FreeNAS 2019 (192.168.1.5) — 70TB pool, CIFS shares
- **Subnet:** 192.168.1.0/24
- **DNS:** AdGuard Home on router + PiHole (192.168.1.33)
- **Monitoring:** Grafana + Prometheus + node-exporter on 192.168.1.21
- **Ansible control node:** git-ansible-deb (192.168.1.3)
- **Tailscale tailnet:** coshaughnessy@

---

## IP Schema

| Range     | Purpose                          |
|-----------|----------------------------------|
| 1–19      | Infrastructure (router, Proxmox, NAS, network gear) |
| 20–49     | Debian/Ubuntu servers, VMs, LXCs |
| 50–69     | RPM servers (Rocky, Alma, RHEL)  |
| 100–119   | Windows workstations             |
| 120–139   | Raspberry Pis                    |
| 140–159   | TVs, media devices, Plex jails   |
| 160–179   | Peripherals, printers, IoT       |
| 200–249   | Mobile, Android devices          |
| 250+      | Special, reserved, virtual IPs   |

---

## Full Host Inventory

### Infrastructure (1–19)

| IP             | Hostname        | OS/Type         | Role                                | Status |
|----------------|-----------------|-----------------|-------------------------------------|--------|
| 192.168.1.1    | router-net      | GL.iNet Flint 2 | Router, AdGuard Home, WireGuard VPN | Online |
| 192.168.1.2    | proxmox-deb     | Debian 12 (PVE) | Proxmox VE hypervisor               | Online |
| 192.168.1.3    | git-ansible-deb | Ubuntu 24.04    | Ansible control node, MkDocs, Git   | Online |
| 192.168.1.5    | freenas-bsd     | FreeNAS (2019)  | NAS — 70TB CIFS shares              | Online |
| 192.168.1.6    | netgate-net     | pfSense         | Secondary firewall/router           | Online |

### Debian/Ubuntu Servers (20–49) — mostly Proxmox VMs/LXCs

| IP           | Hostname           | OS           | Virt  | Role                                        | Status |
|--------------|--------------------|--------------|-------|---------------------------------------------|--------|
| 192.168.1.20 | snipeit-deb        | Debian 12    | LXC   | Snipe-IT asset management                   | Online |
| 192.168.1.21 | grafana-docker-deb | Ubuntu 24.04 | LXC   | Grafana, Prometheus, Portainer, PVE-exporter| Online |
| 192.168.1.22 | swarm01-deb        | Ubuntu 24.04 | KVM   | Docker Swarm manager                        | Online |
| 192.168.1.23 | swarm02-deb        | Ubuntu 24.04 | KVM   | Docker Swarm worker                         | Online |
| 192.168.1.24 | swarm03-deb        | Ubuntu 24.04 | KVM   | Docker Swarm worker                         | Online |
| 192.168.1.25 | ubuntu-ansible-deb | Ubuntu 24.04 | KVM   | Ubuntu Ansible host (GUI)                   | Online |
| 192.168.1.26 | kasm-2404-deb      | Ubuntu 24.04 | KVM   | Kasm Workspaces                             | Online |
| 192.168.1.27 | urnst-deb          | Debian 13    | Physical | Ryzen 5 1600X — role TBD (Proxmox node 3 / PBS candidate) | Online |
| 192.168.1.32 | apache-deb         | Ubuntu 22.04 | LXC   | Apache web server                           | Online |
| 192.168.1.33 | pihole-book-deb    | Debian 12    | LXC   | Pi-hole DNS (1 core, 512MB RAM)             | Online |
| 192.168.1.34 | docker-deb         | Ubuntu 24.04 | KVM   | Docker host                                 | Online |
| 192.168.1.35 | 2404HV-deb         | Ubuntu 24.04 | HyperV| Hyper-V Ubuntu VM (i7-13700K, 12 cores)    | Online |
| 192.168.1.36 | mediastack-deb     | Ubuntu 24.04 | KVM   | Media stack — 12 Docker containers          | Online |

### RPM Servers (50–69) — pending renumber to 80–82

| IP (current) | IP (new)     | Hostname  | OS            | Virt  | Role                        | Status |
|--------------|--------------|-----------|---------------|-------|-----------------------------|--------|
| 192.168.1.51 | → .80        | rocky-rpm | Rocky 9.7     | KVM   | Rocky Linux test            | Online |
| 192.168.1.52 | → .81        | alma-rpm  | AlmaLinux 9.7 | KVM   | AlmaLinux test              | Online |
| 192.168.1.53 | → .82        | plow-rpm  | RHEL 9.6      | HyperV| RHEL VM (i7-13700K)        | Online |

### Windows Workstations (100–119)

| IP             | Hostname         | Notes                       | Status      |
|----------------|------------------|-----------------------------|-------------|
| 192.168.1.100  | amontillado-win  | Main Windows 11 desktop     | Online      |
| 192.168.1.101  | eld-win          | Windows workstation         | Online      |
| 192.168.1.102  | replacements-win | Windows workstation         | Unreachable |
| 192.168.1.103  | todash-win       | Windows workstation         | Online      |
| 192.168.1.104  | work-win         | Work laptop                 | Unreachable |
| 192.168.1.105  | fortunato-win    | Hyper-V Windows 11 VM       | Online      |

### Raspberry Pis (120–139)

| IP           | Hostname     | Notes                              | Status      |
|--------------|--------------|------------------------------------|-------------|
| 192.168.1.120| pi1-deb      | Raspberry Pi (→ from .75)          | Unreachable |
| 192.168.1.121| pi2-deb      | Raspberry Pi (→ from .124)         | Unreachable |
| 192.168.1.122| octopi-deb   | OctoPrint 3D printer (RPi ARMv7)   | Online      |
| 192.168.1.123| batocera-deb | Batocera retro gaming              | Online      |

### TVs / Media / Plex (140–159)

| IP           | Hostname             | Notes                        | Status      |
|--------------|----------------------|------------------------------|-------------|
| 192.168.1.140| tv1-media            | TV                           | Online      |
| 192.168.1.141| tv2-media            | TV                           | Online      |
| 192.168.1.142| lg-tv-net            | LG WebOS TV (→ from .105)    | Unreachable |
| 192.168.1.143| weltgeist-media      | Plex jail (FreeBSD/FreeNAS)  | Online      |
| 192.168.1.144| alea_iacta_est-media | Plex jail (FreeBSD/FreeNAS)  | Online      |
| 192.168.1.145| firetv-droid         | Amazon Fire TV (→ from .214) | Unreachable |

### Peripherals / IoT (160–179)

| IP           | Hostname         | Notes                  | Status      |
|--------------|------------------|------------------------|-------------|
| 192.168.1.162| dell-printer-net | Dell 2155cdn Color MFP | Unreachable |

### Mobile / Android (200–249)

| IP           | Hostname          | Notes                        | Status      |
|--------------|-------------------|------------------------------|-------------|
| 192.168.1.200| alexa-droid       | Amazon Echo                  | Unreachable |
| 192.168.1.201| pixel8-droid      | Google Pixel 8               | Unreachable |
| 192.168.1.202| fire-tablet-droid | Amazon Fire Tablet           | Online      |
| 192.168.1.203| roomba-droid      | iRobot Roomba                | Unreachable |

### Special / Virtual (250+)

| IP           | Hostname        | Notes                   |
|--------------|-----------------|-------------------------|
| 192.168.1.250| swarm-shared-vip| Docker Swarm shared VIP |

---

## Proxmox Host Detail (192.168.1.2)

**Hardware:** AMD Ryzen 5 1600 (6c/12t) | **RAM:** 56GB DDR4 2667 (4x DIMM: 16+16+16+8GB mixed)
**Motherboard:** ASRock AB350M Pro4 | Serial: M80-B1011000766
**BIOS:** AMI P10.43, updated 2025-06-24
**Kernel:** 6.8.12-20-pve

### Storage Pools

| Pool        | Type    | Used     | Total    | Use% |
|-------------|---------|----------|----------|------|
| local       | dir     | 5.72GB   | 93.93GB  | 6%   |
| local-lvm   | lvmthin | 62.6GB   | 816GB    | 8%   |
| ZFS_SDBC    | zfspool | 228GB    | 5456GB   | 4%   |
| DIR_SDA     | dir     | 208GB    | 5544GB   | 4%   |
| zfs-backups | dir     | 164GB    | 5391GB   | 3%   |

### VMs

| VMID | Name                  | Status  | CPU | RAM |
|------|-----------------------|---------|-----|-----|
| 102  | swarm01-manager       | running | 4   | 2GB |
| 103  | Replacements-11       | stopped | 4   | 4GB |
| 104  | swarm02-worker        | running | 4   | 2GB |
| 105  | swarm03-worker        | running | 4   | 2GB |
| 106  | gui-ubuntu-ansible    | running | 4   | 4GB |
| 107  | docker-deb            | running | 2   | 2GB |
| 108  | alma-rpm              | running | 1   | 2GB |
| 109  | rocky-rpm             | running | 1   | 2GB |
| 111  | kasm-2404-deb         | running | 2   | 4GB |
| 112  | mediastack-deb        | running | 4   | 4GB |
| 900  | ubuntu-24.04-template | stopped | 1   | 1GB |
| 901  | ubuntu-ansible        | running | 4   | 4GB |

### LXC Containers

| CTID | Name            | Status  | CPU | RAM   |
|------|-----------------|---------|-----|-------|
| 100  | apache-deb      | running | 2   | 4GB   |
| 101  | grafana-dock    | running | 2   | 4GB   |
| 110  | pihole-book-deb | running | 1   | 0.5GB |
| 500  | snipe-it        | running | 1   | 2GB   |

---

## mediastack-deb Detail (192.168.1.36)

Proxmox VM 112 | Ubuntu 24.04 | 4 cores | 4GB RAM
**⚠️ Root disk — expanded to 164GB, 17% used** | Tailscale: 100.127.236.79

### Docker Containers

| Container      | Port  | Purpose           |
|----------------|-------|-------------------|
| romm           | 8998  | ROM manager       |
| seerr          | 5055  | Media requests    |
| komga          | 8085  | Comics/ebooks     |
| mylar          | 8091  | Comics downloader |
| lidarr         | 8686  | Music mgmt        |
| radarr         | 7878  | Movie mgmt        |
| sabnzbd        | 8090  | Usenet downloader |
| sonarr         | 8989  | TV mgmt           |
| vpn            | 8080  | WireGuard VPN     |
| mariadb        | —     | DB for romm       |
| prowlarr       | 9696  | Indexer manager   |
| audiobookshelf | 13378 | Audiobooks        |

NAS CIFS mounts at `/mnt/plex/*`: Music420, Movies, Comics, AudioBooksPlex, Reading420, downloads, TV, Training, ROMs

---

## git-ansible-deb Detail (192.168.1.3)

Ubuntu 24.04 | Disk: 63GB, 35% used | Tailscale: 100.68.195.68
Ansible core 2.20.4 | Python 3.12.3
Services: MkDocs :8000, nginx :80, MariaDB :3306 (localhost)
Docs: `/home/cos/material/mkdocs_dev_material/docs/`
VS Code Server installed

---

## Tailscale Nodes

| git-ansible            | 100.68.195.68  | Linux   | Online  |
|------------------------|----------------|---------|---------|
| mediastack-deb         | 100.127.236.79 | Linux   | Online  |
| amontillado            | 100.126.7.50   | Windows | Online  |
| coe-thinkpad-p1-gen-4i | 100.81.219.113 | Linux   | Offline |
| pixel-8                | 100.110.116.11 | Android | Offline |

---

## Docker Swarm (.22–.24, VIP .250)

swarm01 (.22) — manager | swarm02 (.23) — worker | swarm03 (.24) — worker
All nodes have Ceph user — storage cluster likely configured

---

## Security Flags

| Issue | Affected Hosts |
|-------|---------------|
| fail2ban NOT installed | mediastack-deb, docker-deb, grafana-docker-deb, pihole-book-deb |
| chrony FAILED | snipeit-deb, pihole-book-deb |
| frodo user — empty password WARNING | rocky-rpm, alma-rpm, plow-rpm |
| FreeNAS 2019 EOL — no patches | 192.168.1.5 |
| Root disk 91% CRITICAL | mediastack-deb |
| /overlay/base 100% CRITICAL | batocera-deb |

---

## Known Issues / To Do

### Critical
- [x] ~~mediastack-deb root disk at 91% — expand VM disk or clean up Docker~~ ✅ 2026-04-09 — expanded to 164GB, now at 17% (127GB free)
- [x] ~~batocera-deb /overlay/base at 100%~~ ✅ 2026-04-09 — false alarm, this is the read-only Batocera OS squashfs image, expected behavior

### In Progress
- [x] ~~docker-deb — broken packages (udev/libudev1 mismatch)~~ ✅ 2026-04-09
- [ ] plow-rpm — xrdp/SELinux conflict blocking updates — decide: exclude xrdp or remove it
- [x] ~~git-ansible-deb — cannot sudo via Ansible~~ ✅ 2026-04-10 — passwordless sudo configured

### Security
- [x] ~~frodo user deleted from rocky-rpm, alma-rpm, plow-rpm~~ ✅ 2026-04-09
- [x] ~~fail2ban installed on mediastack-deb~~ ✅ 2026-04-09
- [x] ~~fail2ban — docker-deb still missing (blocked by broken packages)~~ ✅ 2026-04-09
- [x] ~~fail2ban — update whitelist from 192.168.1.100 to 192.168.1.0/24~~ ✅ 2026-04-09
- [x] ~~fail2ban — exclude batocera-deb in playbook~~ ✅ 2026-04-09
- [x] ~~fail2ban — exclude git-ansible-deb in playbook~~ ✅ 2026-04-09
- [x] ~~Fix chrony on snipeit-deb and pihole-book-deb~~ ✅ 2026-04-09 — disabled in LXC containers, time sync handled by Proxmox host
- [x] ~~Add Tailscale to git-ansible-deb~~ ✅ 2026-04-10 (100.68.195.68)

### Maintenance
- [x] ~~Most hosts updated via update_reboot_linux.yml~~ ✅ 2026-04-09
- [ ] Complete pending IP renumbering (Rocky/Alma/RHEL .51-.53 → .80-.82, Pis, TVs etc.)
- [ ] Fix duplicate mediastack-deb entry in inventory_auto
- [ ] Investigate pi1-deb and pi2-deb unreachable

### Long Term
- [ ] FreeNAS → TrueNAS Community Edition migration
- [ ] Clarify role of MariaDB and nginx on git-ansible-deb

---
_Generated from MkDocs docs + enum output | 2026-04-09_

