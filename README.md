# 🛠️ sysadmin-automation-scripts

A consolidated repository containing my custom scripts, Ansible playbooks, and utilities for managing Proxmox, network setups, and system provisioning.

---

## 🌳 Repository Structure
<!-- START_SECTION:tree -->
```text
sysadmin-automation-scripts/
├── 📁 proxmox/                    # VM & Template Management
│   ├── vmdeployment.py           # Python deployment utility
│   ├── vmrecall.py               # Utility to recall/retrieve VMs
│   ├── multitemplates            # Multi-template configuration
│   ├── multitemplate.yml         # Ansible playbook for templates
│   ├── multitemplatewithtags.yml # Ansible playbook with tags
│   └── vms_to_delete.yml         # Inventory/playbook for VM cleanup
│
├── 📁 networking/                 # System & Routing Configurations
│   └── setup_nat_dhcp.sh         # NAT & DHCP configuration script
│
└── 📁 provisioning/                # User & System Provisioning
    ├── linux_user_creation.sh    # Linux user onboarding script
    ├── windows_user_creation.ps1 # Windows user setup script
    ├── run_win_user_boot.ps1    # Boot script for Windows setup
    ├── user.sh                   # Helper script for user creation
    └── user2.sh                  # Alternative helper script
<!-- END_SECTION:tree -->
