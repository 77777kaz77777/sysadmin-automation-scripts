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
│   ├── create_user_interactive.sh              # Safely creates a user account, configures passwords, and optionally grants administrative privileges.
│   ├── create_users_from_csv.sh                # Reads a CSV file (username,password) and provisions user accounts safely.
│   ├── initial_user_onboarding.sh              # First-Boot Linux User Onboarding Utility
│   ├── run win user creation on boot script    # Boot script for Windows setup
│   └── windows user creation                   # Windows user setup script
└── 📁 proxmox/
    ├── clone_and_start_vms.yml                 # Ansible playbook to clone and start Proxmox VMs idempotently
    ├── proxmox_clone_and_tag_vms.yml           # Ansible playbook to safely clone, tag, and start Proxmox VMs
    ├── proxmox_multi_vm_template_deploy.yml    # Ansible playbook to bulk clone and start Proxmox VMs from Multiple Templates
    ├── pve_assign_vm_permissions.py            # Assigns Proxmox permissions to users based on a CSV mapping via SSH.
    ├── pve_destroy_vms.yml                     # Ansible playbook to safely decommission and purge Proxmox VMs
    └── pve_revoke_vm_permissions.py            # Revokes Proxmox permissions/roles from users based on a CSV mapping via SSH.
```
<!-- END_SECTION:tree -->
