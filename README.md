# 🛠️ sysadmin-automation-scripts

A consolidated repository containing my custom scripts, Ansible playbooks, and utilities for managing Proxmox, network setups, and system provisioning.

---

## 🌳 Repository Structure
<!-- START_SECTION:tree -->
```text
sysadmin-automation-scripts/
├── 📁 networking/
│   └── setup_nat_dhcp.sh                       # Configure NAT router + DHCP server
├── 📁 provisioning/
│   ├──  user.sh                                # Helper script for linux user creation using CSV
│   ├── linux user creation                     # Linux user onboarding script
│   ├── run win user creation on boot script    # Boot script for Windows setup
│   ├── user2.sh                                # Helper script for linux user creation
│   └── windows user creation                   # Windows user setup script
└── 📁 proxmox/
    ├── clone_and_start_vms.yml                 # Ansible playbook to clone and start Proxmox VMs idempotently
    ├── multitemplatewithtags.yml               # Ansible playbook with tags
    ├── proxmox_multi_vm_template_deploy.yml    # Multi-template configuration
    ├── pve_assign_vm_permissions.py
    ├── vmrecall.py                             # Utility to recall/retrieve VMs
    └── vms_to_delete.yml                       # Inventory/playbook for VM
```
<!-- END_SECTION:tree -->
