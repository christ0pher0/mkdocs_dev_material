
# Home Lab Network Setup

## Network Topology Sequence Diagram

1. ONT (Optical Network Terminal) connects to Router
2. Router connects to Firewall
3. Firewall connects to Managed Switch
4. Managed Switch connects to:
   - Wi-Fi Mesh AP
   - TrueNAS Server
   - Proxmox Node 1
   - Proxmox Node 2
   - Proxmox Node 3
   - Docker Host Machine
   - Servers
   - IoT Devices
   - Guest Network
   - VLANs

