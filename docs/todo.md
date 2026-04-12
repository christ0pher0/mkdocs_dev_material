# Homelab Todo & Roadmap
_Last updated: 2026-04-10_

---

## Critical / Security
- [ ] FreeNAS 2019 → TrueNAS Community Edition — EOL OS on 45TB of data
### Backup Strategy (eld)
- [ ] Migrate eld to Ubuntu 26.04
- [ ] Deploy Restic — automated backups from FreeNAS (Tier 1)
- [ ] Configure 2x CRU bays on eld for rotating manual drives (Tier 2)
- [ ] Establish offsite drive rotation schedule (Tier 3)
- [ ] Expand backup coverage — currently only Patreon O-Z backed up, A-N missing
- [ ] Expand eld storage — 3TB internal nearly full (10% free)
- [ ] Upgrade eld RAM to 32GB DDR3 before migration

---

## In Progress
- [ ] Inventory 6 waiting systems — match hardware to roles
- [ ] Complete IP renumbering (Rocky/Alma/RHEL .51-.53 → .80-.82, Pis, TVs etc.)
- [ ] Remove alea_iacta_est (plex-plexpass_2) jail from FreeNAS — experimental, not needed

---

## Planned Projects

### Local AI Assistant
- [ ] Deploy Ollama — local LLM backend on GPU node
- [ ] Deploy Open WebUI — chat interface with multi-model support
- [ ] Create sysadmin assistant — fed network context doc, knows the whole lab
- [ ] Create homelab advisor — planning and research personality
- [ ] Create casual assistant — general chat, different vibe
- [ ] Each character gets: name, avatar, system prompt, model
- [ ] Add Whisper — local speech to text
- [ ] Add Piper — local text to speech, multiple voice models
- [ ] Feed MkDocs docs as RAG knowledge base
- [ ] Feed Ansible inventory and playbooks as context
- [ ] Name them — continuing Poe/Spanish wine theme 🍷

### GPU Node (GTX 1080 8GB)
- [ ] Pick host system from waiting hardware (Ryzen 5 1600 twin preferred)
- [ ] Add as Proxmox second node with PCIe GPU passthrough
- [ ] Deploy Ollama — use GTX 1080 Ti (11GB VRAM) over 1080 (8GB) for better model support
- [ ] Deploy Tdarr — NVENC hardware transcoding for mediastack
- [ ] Consider Stable Diffusion (ComfyUI or Automatic1111)
- [ ] Consider Sunshine — game streaming server to TVs
- [ ] Note: Pascal NVENC = 1 transcode stream, no AV1 encoding

### 3D Printing
- [ ] Design or source Pi rack — check Printables.com, size for Pi count
- [ ] Flash pi3-deb (RPi B) with latest RetroPie Bookworm image — upgrade possible
- [x] pi4-deb (RPi 2B) — flashed DietPi, onboarded ✅ 2026-04-12
- [ ] Obico (formerly The Spaghetti Detective) — AI failure detection, remote monitoring
- [ ] Evaluate Klipper + Moonraker + Mainsail/Fluidd as OctoPrint alternative for Ender 3 V2
- [ ] Add OctoPrint Pi for Ender 3 V1
- [ ] Automate print monitoring via Home Assistant integration
- [ ] Elegoo Mars 3 — evaluate Chitubox vs Lychee slicer
- [ ] Flashforge Dreamer — evaluate FlashPrint vs Simplify3D

### eld-win → Ubuntu 26.04
- [ ] Wait for Ubuntu 26.04 LTS release
- [ ] Fresh install, onboard with onboard_host.yml
- [ ] Assign new role (TBD from projects below)

### Kubernetes
- [ ] Evaluate k3s vs full k8s
- [ ] Plan migration from Docker Swarm (swarm01/02/03)
- [ ] Consider dedicated k8s nodes from waiting hardware
- [ ] Investigate ArgoCD for GitOps deployments

### argos-deb (ewaste RPi 4 IoT station)
- [x] Flash Bookworm 64-bit, onboard via Ansible ✅ 2026-04-12
- [x] Set DHCP reservation → .127 ✅ 2026-04-12
- [x] Verify 7" touchscreen works on Bookworm ✅ works out of the box
- [ ] Test RPi Camera V2.1
- [ ] Research Sixfab EC25-A 4G LTE setup — needs SIM card (Hologram.io recommended)
- [ ] Research Adafruit RFM9x LoRa setup — potential LoRa gateway for long range sensors
- [ ] Decide role — mobile node, HA kiosk, camera, LoRa gateway, or all of the above
- [ ] Home Assistant — already running on ha-net (192.168.1.125) ✅
- [ ] Configure HA backups — currently none configured ⚠️
- [ ] Disable WiFi on ha-net — use ethernet only (currently both active)
- [x] Set DHCP reservation for ha-net ethernet MAC (e4:5f:01:65:56:ee) → .125 ✅ 2026-04-12
- [ ] Explore Ansible URI module to manage HA via REST API
- [ ] Install ESPHome add-on — for flashing/managing ESP8266/ESP32 IoT devices
- [ ] Install Music Assistant add-on — integrates with Plex/media stack
- [ ] Document installed add-ons and backup situation
- [ ] Connect smart home devices to HA
- [ ] Decide host for Zigbee/Z-Wave coordinator (pi2 candidate)

### Secrets & Identity
- [ ] Vaultwarden (Bitwarden) — self-hosted password manager
- [ ] Vault (HashiCorp) — secrets management for Ansible/k8s
- [ ] Authelia — already in mediastack app list, evaluate for broader use
- [ ] Authentik — alternative to Authelia, more features

### Monitoring Expansion
- [ ] Zabbix — network and service monitoring with alerting
- [ ] Netdata — real-time per-host monitoring
- [ ] InfluxDB + Telegraf — time series metrics
- [ ] Loki — log aggregation alongside Grafana
- [ ] Already have: Grafana, Prometheus, node-exporter, PVE-exporter

### Storage & Backup
- [ ] Restic — backup solution for VMs, configs, and critical data
- [ ] Plan backup strategy for 45TB NAS
- [ ] Evaluate OpenMediaVault as FreeNAS alternative (lighter weight)
- [ ] Immich — self-hosted Google Photos alternative — deploy on Proxmox VM or docker-deb (Pi 2B too slow for ML processing)

### CI/CD & Dev
- [ ] Gitea — already suspected on git-ansible, confirm and document
- [ ] GitLab — heavier but full CI/CD pipelines
- [ ] Jenkins or Drone — build automation
- [ ] ArgoCD — Kubernetes GitOps
- [ ] Terraform — IaC for Proxmox provisioning
- [ ] Packer — machine image builds

### Network
- [ ] Clarify Flint2 + Netgate topology — consolidate or keep both
- [ ] Evaluate VLANs for IoT/media/server segmentation
- [ ] Unbound — local DNS resolver
- [ ] Traefik — reverse proxy with auto HTTPS, Docker-native, replaces SWAG
- [ ] WireGuard — already running in mediastack, evaluate for wider use
- [ ] DDNS-Updater — if exposing services externally

### Documentation
- [ ] Expand MkDocs site with Ansible playbook docs
- [ ] Document Docker Swarm setup
- [ ] Document Proxmox VM/LXC layout
- [ ] BookStack or Wiki.js — evaluate as MkDocs replacement for richer docs

---

## Mediastack — Current Stack

| App            | Port  | Status      |
|----------------|-------|-------------|
| Sonarr         | 8989  | ✅ Running  |
| Radarr         | 7878  | ✅ Running  |
| Lidarr         | 8686  | ✅ Running  |
| Mylar3         | 8091  | ✅ Running  |
| SABnzbd        | 8090  | ✅ Running  |
| Prowlarr       | 9696  | ✅ Running  |
| Seerr          | 5055  | ✅ Running  |
| Komga          | 8085  | ✅ Running  |
| Audiobookshelf | 13378 | ✅ Running  |
| Romm           | 8998  | ✅ Running  |
| WireGuard VPN  | 8080  | ✅ Running  |
| MariaDB        | —     | ✅ Running  |

## Mediastack — To Add
- [ ] Authelia — authentication layer for all services
- [ ] Bazarr — subtitle automation for Sonarr/Radarr
- [ ] Homepage or Heimdall — dashboard
- [ ] Tdarr — transcoding (needs GPU node first)
- [ ] Gluetun — VPN container routing
- [ ] FlareSolverr — Cloudflare bypass for indexers
- [ ] Traefik — replace SWAG as reverse proxy
- [ ] Unpackerr — auto extract downloads
- [ ] Portainer — Docker management UI
- [ ] DDNS-Updater — dynamic DNS
- [ ] qBittorrent — torrent client
- [ ] Whisparr — adult media management
- [ ] Tautulli — Plex analytics

## Mediastack — Cleanup
- [ ] Review Lidarr MediaCover cache growth (currently 6.5GB)

---

## Apps to Investigate Further
- [ ] BookStack — documentation platform
- [ ] Wiki.js — modern wiki engine
- [ ] Ghost — blogging platform
- [ ] WordPress — CMS
- [ ] Hugo / Jekyll — static site generators
- [ ] Vagrant — VM environment management

---

## Maintenance Backlog
- [ ] Enable SSH on freenas-bsd and run dmidecode for hardware inventory
- [ ] Add fail2ban to homelab_baseline.yml
- [ ] Add chrony LXC skip to sync_time.yml
- [ ] Update check_services.yml to reflect current services
- [x] ~~Remove duplicate mediastack-deb from inventory_auto~~ ✅ 2026-04-10
- [x] ~~Remove overseerr config dir (replaced by seerr)~~ ✅ 2026-04-10
- [ ] Update fail2ban.yml — add pause before verify task (timing fix)
- [ ] Clarify MariaDB and nginx role on git-ansible-deb
- [ ] Create docs/images/hw/ directory in MkDocs project
- [ ] Save proxmox-deb photo to docs/images/hw/proxmox-deb.jpg — photo taken
- [ ] Confirm git-ansible physical host specs with dmidecode
- [ ] Run Get-ComputerInfo on eld-win for hardware inventory
- [ ] Inventory offsite ThinkStation Proxmox node — specs, storage, role
- [ ] Add ThinkStation to Tailscale
- [ ] Add ThinkStation to Ansible inventory
- [ ] Take photos of all remaining hosts
- [ ] Import all hardware into Snipe-IT (192.168.1.20)

---

## Hardware Wishlist
- [x] GL-MT6000 Flint 2 — purchased, in use as router

---

## Completed ✅
- [x] Deleted frodo user from rocky-rpm, alma-rpm, plow-rpm — 2026-04-09
- [x] fail2ban deployed fleet-wide with 192.168.1.0/24 whitelist — 2026-04-09
- [x] Fleet packages updated — 2026-04-09
- [x] mediastack-deb root disk expanded 30GB → 164GB — 2026-04-09
- [x] docker-deb broken packages fixed — 2026-04-09
- [x] chrony disabled on LXC containers (snipeit, pihole) — 2026-04-09
- [x] plow-rpm xrdp conflict resolved — 2026-04-09
- [x] batocera /overlay/base false alarm resolved — 2026-04-09
- [x] Tailscale installed on git-ansible-deb (100.68.195.68) — 2026-04-10
- [x] git-ansible-deb passwordless sudo configured — 2026-04-10
- [x] mediastack-deb onboarded and SSH hardened — 2026-04-10
- [x] fail2ban playbook cleaned up (batocera/git-ansible excluded) — 2026-04-10
- [x] FreeNAS hardware fully inventoried — BIOS, mobo, RAM, ZFS pool topology — 2026-04-12
- [x] eld-win hardware fully inventoried — mobo, CPU, RAM, storage — 2026-04-12
- [x] amontillado-win hardware fully inventoried — 2026-04-12
- [x] Hardware inventory MkDocs page live with photos — 2026-04-12
- [x] pi1-deb onboarded (Raspbian Bookworm, .120) — 2026-04-12
- [x] pi2-deb onboarded (DietPi, .121) — 2026-04-12
- [x] pi4-deb onboarded (DietPi RPi 2B, .126) — 2026-04-12
- [x] argos-deb onboarded (RPi 4 ewaste, Bookworm, .127) — 2026-04-12
- [x] ha-net documented (HAOS 17.2, RPi 4, .125) — 2026-04-12
- [x] inventory_auto cleaned — duplicates removed, legacy group added — 2026-04-12
- [x] onboard_host.yml fixed — hostname fallback, SSH ignore_errors, duplicate entry fix — 2026-04-12
- [x] 8 Pis identified, photographed, and documented — 2026-04-12
- [x] argos-deb named — hundred-eyed giant, ewaste RPi 4 with LTE/LoRa/camera/touchscreen — 2026-04-12

---

## Package Baseline (managed by onboard_host.yml)
tmux, plocate, screen, cifs-utils, tree, vim, inxi, screenfetch,
curl, wget, git, htop, net-tools, unzip, apt-utils
