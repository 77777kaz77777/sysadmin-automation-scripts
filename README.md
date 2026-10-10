# 🛠️ sysadmin-automation-scripts

A consolidated repository containing my custom scripts, Ansible playbooks, and utilities for managing Proxmox, network setups, and system provisioning.

---

## 🌳 Repository Structure

<!-- START_SECTION:tree -->

### 📁 networking/ (Networking Automation)

| File                                                                      | Description                        |
| ------------------------------------------------------------------------- | ---------------------------------- |
| <a href="networking/setup_nat_dhcp.sh"><code>setup_nat_dhcp.sh</code></a> | Configure NAT router + DHCP server |

### 📁 provisioning/ (User Provisioning & Bootstrapping)

| File                                                                                          | Description                                                                                                          |
| --------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| <a href="provisioning/New-WindowsAdminUser.ps1"><code>New-WindowsAdminUser.ps1</code></a>     | Interactively provisions a local Windows administrative account and decommissions default/temporary profiles safely. |
| <a href="provisioning/create_user_interactive.sh"><code>create_user_interactive.sh</code></a> | Safely creates a user account, configures passwords, and optionally grants administrative privileges.                |
| <a href="provisioning/create_users_from_csv.sh"><code>create_users_from_csv.sh</code></a>     | Reads a CSV file (username,password) and provisions user accounts safely.                                            |
| <a href="provisioning/initial_user_onboarding.sh"><code>initial_user_onboarding.sh</code></a> | First-Boot Linux User Onboarding Utility                                                                             |

### 📁 proxmox/ (Proxmox Virtual Environment Scripts)

| File                                                                                                         | Description                                                                  |
| ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| <a href="proxmox/clone_and_start_vms.yml"><code>clone_and_start_vms.yml</code></a>                           | Ansible playbook to clone and start Proxmox VMs idempotently                 |
| <a href="proxmox/proxmox_clone_and_tag_vms.yml"><code>proxmox_clone_and_tag_vms.yml</code></a>               | Ansible playbook to safely clone, tag, and start Proxmox VMs                 |
| <a href="proxmox/proxmox_multi_vm_template_deploy.yml"><code>proxmox_multi_vm_template_deploy.yml</code></a> | Ansible playbook to bulk clone and start Proxmox VMs from Multiple Templates |
| <a href="proxmox/pve_assign_vm_permissions.py"><code>pve_assign_vm_permissions.py</code></a>                 | Assigns Proxmox permissions to users based on a CSV mapping via SSH.         |
| <a href="proxmox/pve_destroy_vms.yml"><code>pve_destroy_vms.yml</code></a>                                   | Ansible playbook to safely decommission and purge Proxmox VMs                |
| <a href="proxmox/pve_revoke_vm_permissions.py"><code>pve_revoke_vm_permissions.py</code></a>                 | Revokes Proxmox permissions/roles from users based on a CSV mapping via SSH. |

<!-- END_SECTION:tree -->
