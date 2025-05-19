
from graphviz import Digraph

# Create a new directed graph
dot = Digraph(comment='Home Lab Network Setup')

# Add nodes
dot.node('ONT', 'ONT')
dot.node('Router', 'Router')
dot.node('Firewall', 'Firewall')
dot.node('Switch', 'Managed Switch')
dot.node('WiFi', 'Wi-Fi Mesh AP')
dot.node('TrueNAS', 'TrueNAS Server')
dot.node('Proxmox1', 'Proxmox Node 1')
dot.node('Proxmox2', 'Proxmox Node 2')
dot.node('Proxmox3', 'Proxmox Node 3')
dot.node('Docker', 'Docker Host Machine')
dot.node('Servers', 'Servers')
dot.node('IoT', 'IoT Devices')
dot.node('Guest', 'Guest Network')
dot.node('VLANs', 'VLANs')

# Add edges
dot.edge('ONT', 'Router')
dot.edge('Router', 'Firewall')
dot.edge('Firewall', 'Switch')
dot.edge('Switch', 'WiFi')
dot.edge('Switch', 'TrueNAS')
dot.edge('Switch', 'Proxmox1')
dot.edge('Switch', 'Proxmox2')
dot.edge('Switch', 'Proxmox3')
dot.edge('Switch', 'Docker')
dot.edge('Switch', 'Servers')
dot.edge('Switch', 'IoT')
dot.edge('Switch', 'Guest')
dot.edge('Switch', 'VLANs')

# Save the diagram
dot.render('home_lab_network_setup', format='png')

# Create the Markdown content
markdown_content = """
# Home Lab Network Setup

![Home Lab Network Diagram](home_lab_network_setup.png)

## Components

- **ONT (Optical Network Terminal)**: The entry point for fiber optic internet.
- **Router**: Manages network traffic and provides basic firewall functions.
- **Firewall**: Provides advanced security features to protect the network.
- **Managed Switch**: Distributes network connections to various devices.
- **Wi-Fi Mesh AP**: Provides wireless network coverage throughout the home.
- **TrueNAS Server**: Network-attached storage for data storage and management.
- **Proxmox Nodes**: Three nodes for running virtual machines and containers.
- **Docker Host Machine**: Runs Docker containers for various applications.
- **Servers**: General-purpose servers for various tasks.
- **IoT Devices**: Internet of Things devices connected to the network.
- **Guest Network**: A separate network for guest devices.
- **VLANs**: Virtual LANs for network segmentation and organization.

## Network Flow

1. **ONT** receives the fiber optic internet signal.
2. The signal is passed to the **Router**.
3. The **Router** forwards the traffic to the **Firewall** for security processing.
4. The **Firewall** sends the traffic to the **Managed Switch**.
5. The **Managed Switch** distributes the traffic to various devices:
   - **Wi-Fi Mesh AP** for wireless coverage.
   - **TrueNAS Server** for data storage.
   - **Proxmox Nodes** for virtualization.
   - **Docker Host Machine** for containerized applications.
   - **Servers** for general tasks.
   - **IoT Devices** for smart home functions.
   - **Guest Network** for guest access.
   - **VLANs** for network segmentation.

This setup ensures a secure, efficient, and organized home lab network.
"""

# Save the Markdown content to a file
with open('home_lab_network_setup.md', 'w') as f:
    f.write(markdown_content)

print("Network diagram and Markdown file have been created successfully.")


