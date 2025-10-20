```mermaid
classDiagram
    class ONT
    class Router
    class Firewall
    class Switch
    class WiFi
    class TrueNAS
    class Proxmox1
    class Proxmox2
    class Proxmox3
    class Docker
    class Servers
    class IoT
    class Guest
    class VLANs

    ONT --> Router : Fiber Signal
    Router --> Firewall
    Firewall --> Switch
    Switch --> WiFi
    Switch --> TrueNAS
    Switch --> Proxmox1
    Switch --> Proxmox2
    Switch --> Proxmox3
    Switch --> Docker
    Switch --> Servers
    Switch --> IoT
    Switch --> Guest
    Switch --> VLANs
```
