# 🛠️ Sysadmin Automation Scripts

[![Lint checks](https://github.com/77777kaz77777/sysadmin-automation-scripts/actions/workflows/lint-checks.yml/badge.svg)](https://github.com/77777kaz77777/sysadmin-automation-scripts/actions/workflows/lint-checks.yml)
[![Secret scan](https://github.com/77777kaz77777/sysadmin-automation-scripts/actions/workflows/gitleaks-secret-scan.yml/badge.svg)](https://github.com/77777kaz77777/sysadmin-automation-scripts/actions/workflows/gitleaks-secret-scan.yml)
[![License: MIT](https://img.shields.io/github/license/77777kaz77777/sysadmin-automation-scripts)](LICENSE)

Scripts and Ansible playbooks for user provisioning, network setup, and managing Proxmox VMs and clusters. Covers Linux (Bash, Python) and Windows (PowerShell).

## What's in Here

| Folder                           | What's in it                                                                                                                                                  |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`proxmox/`](proxmox/)           | Ansible playbooks to clone, tag, start, and remove VMs; Python scripts to grant or revoke VM permissions from a CSV; a bootstrap script for new cluster nodes |
| [`provisioning/`](provisioning/) | Create Linux users interactively or in bulk from a CSV, first-boot onboarding, and a Windows local admin account script                                       |
| [`networking/`](networking/)     | Turn a Linux machine into a NAT router with DHCP and DNS                                                                                                      |

Every push is formatted automatically and checked with ShellCheck, ansible-lint, PSScriptAnalyzer, and Gitleaks.

> **Read a script before running it.** Most of these need root or administrator rights and change users, networks, or VMs.


---

## 🌳 Repository Structure

<!-- START_SECTION:tree -->

### 📁 networking/ (Networking Automation)

| File                                                                  | Description                                                       |
| --------------------------------------------------------------------- | ----------------------------------------------------------------- |
| <a href="networking/setup-router.sh"><code>setup-router.sh</code></a> | Configure NAT Router + DHCP/DNS Server (Distro-Agnostic & Modern) |

### 📁 provisioning/ (User Provisioning & Bootstrapping)

| File                                                                                          | Description                                                                                                          |
| --------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| <a href="provisioning/New-WindowsAdminUser.ps1"><code>New-WindowsAdminUser.ps1</code></a>     | Interactively provisions a local Windows administrative account and decommissions default/temporary profiles safely. |
| <a href="provisioning/create_user_interactive.sh"><code>create_user_interactive.sh</code></a> | Safely creates a user account, configures passwords, and optionally grants administrative privileges.                |
| <a href="provisioning/create_users_from_csv.sh"><code>create_users_from_csv.sh</code></a>     | Reads a CSV file (username,password) and provisions user accounts safely.                                            |
| <a href="provisioning/initial_user_onboarding.sh"><code>initial_user_onboarding.sh</code></a> | First-Boot Linux User Onboarding Utility                                                                             |

### 📁 proxmox/ (Proxmox Virtual Environment Scripts)

| File                                                                                                         | Description                                                                                                                |
| ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| <a href="proxmox/clone_and_start_vms.yml"><code>clone_and_start_vms.yml</code></a>                           | Ansible playbook to clone and start Proxmox VMs idempotently                                                               |
| <a href="proxmox/proxmox_clone_and_tag_vms.yml"><code>proxmox_clone_and_tag_vms.yml</code></a>               | Ansible playbook to safely clone, tag, and start Proxmox VMs                                                               |
| <a href="proxmox/proxmox_multi_vm_template_deploy.yml"><code>proxmox_multi_vm_template_deploy.yml</code></a> | Ansible playbook to bulk clone and start Proxmox VMs from Multiple Templates                                               |
| <a href="proxmox/pve_assign_vm_permissions.py"><code>pve_assign_vm_permissions.py</code></a>                 | Assigns Proxmox permissions to users based on a CSV mapping via SSH.                                                       |
| <a href="proxmox/pve_destroy_vms.yml"><code>pve_destroy_vms.yml</code></a>                                   | Ansible playbook to safely decommission and purge Proxmox VMs                                                              |
| <a href="proxmox/pve_revoke_vm_permissions.py"><code>pve_revoke_vm_permissions.py</code></a>                 | Revokes Proxmox permissions/roles from users based on a CSV mapping via SSH.                                               |
| <a href="proxmox/setup-secondary-node.sh"><code>setup-secondary-node.sh</code></a>                           | Bootstraps a fresh Proxmox VE install as a secondary node and joins it to the existing cluster (run straight from GitHub). |

<!-- END_SECTION:tree -->
