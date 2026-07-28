# 🛠️ sysadmin-automation-scripts

A consolidated repository containing my custom scripts, Ansible playbooks, and utilities for managing Proxmox, network setups, and system provisioning.

---

## 🌳 Repository Structure

```text
sysadmin-automation-scripts/
├── 📁 proxmox/                    # VM & Template Management
│   ├── vmdeployment.py           # Python deployment utility
│   ├── vmrecall.py               # Utility to recall/retrieve VMs
│   ├── multitemplates            # Multi-template configuration[cite: 3]
│   ├── multitemplate.yml         # Ansible playbook for templates[cite: 3]
│   ├── multitemplatewithtags.yml # Ansible playbook with tags[cite: 3]
│   └── vms_to_delete.yml         # Inventory/playbook for VM cleanup[cite: 3]
│
├── 📁 networking/                 # System & Routing Configurations
│   └── setup_nat_dhcp.sh         # NAT & DHCP configuration script
│
└── 📁 provisioning/                # User & System Provisioning
    ├── linux_user_creation.sh    # Linux user onboarding script[cite: 3]
    ├── windows_user_creation.ps1 # Windows user setup script[cite: 3]
    ├── run_win_user_boot.ps1    # Boot script for Windows setup[cite: 3]
    ├── user.sh                   # Helper script for user creation[cite: 3]
    └── user2.sh                  # Alternative helper script[cite: 3]
