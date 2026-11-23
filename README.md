# 🛠️ sysadmin-automation-scripts

A consolidated repository containing my custom scripts, Ansible playbooks, and utilities for managing Proxmox, network setups, and system provisioning.

---

## 🚀 Adding a Secondary Proxmox Node

After installing Proxmox VE on the new machine, log in as `root` (console or SSH) and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/77777kaz77777/sysadmin-automation-scripts/main/proxmox/setup-secondary-node.sh)
```

The script will:

1. Switch apt to the free `pve-no-subscription` repo, disabling the enterprise one (works for both `.list` and the newer `.sources` format).
2. Fully update the node and install base tools (git, htop, tmux, nfs-common, chrony, and optionally Ansible).
3. Set the timezone and, if you choose, hide the "No valid subscription" popup.
4. Import your SSH keys from `github.com/77777kaz77777.keys`.
5. Clone this repo to `/opt/sysadmin-automation-scripts` so the playbooks are on the node.
6. Join the primary node's cluster with `pvecm add` (it will ask for the primary's root password).

Every prompt can be pre-answered with an environment variable, for example:

```bash
PRIMARY_IP=192.168.1.10 TIMEZONE=America/Toronto \
  bash <(curl -fsSL https://raw.githubusercontent.com/77777kaz77777/sysadmin-automation-scripts/main/proxmox/setup-secondary-node.sh)
```

See the top of [`proxmox/setup-secondary-node.sh`](proxmox/setup-secondary-node.sh) for the full list.

**Before you run it:**

- The primary must already be in a cluster. If it isn't yet, run `pvecm create <cluster-name>` on the primary once.
- Give the new node a **unique hostname** and a **static IP** during the Proxmox install.
- The new node must have **no VMs or containers** on it yet.

---

## 🌳 Repository Structure

<!-- START_SECTION:tree -->
### 📁 networking/ (Networking Automation)

| File | Description |
|---|---|
| <a href="networking/setup-router.sh"><code>setup-router.sh</code></a> | Configure NAT Router + DHCP/DNS Server (Distro-Agnostic & Modern) |


### 📁 provisioning/ (User Provisioning & Bootstrapping)

| File | Description |
|---|---|
| <a href="provisioning/New-WindowsAdminUser.ps1"><code>New-WindowsAdminUser.ps1</code></a> | Interactively provisions a local Windows administrative account and decommissions default/temporary profiles safely. |
| <a href="provisioning/create_user_interactive.sh"><code>create_user_interactive.sh</code></a> | Safely creates a user account, configures passwords, and optionally grants administrative privileges. |
| <a href="provisioning/create_users_from_csv.sh"><code>create_users_from_csv.sh</code></a> | Reads a CSV file (username,password) and provisions user accounts safely. |
| <a href="provisioning/initial_user_onboarding.sh"><code>initial_user_onboarding.sh</code></a> | First-Boot Linux User Onboarding Utility |


### 📁 proxmox/ (Proxmox Virtual Environment Scripts)

| File | Description |
|---|---|
| <a href="proxmox/clone_and_start_vms.yml"><code>clone_and_start_vms.yml</code></a> | Ansible playbook to clone and start Proxmox VMs idempotently |
| <a href="proxmox/proxmox_clone_and_tag_vms.yml"><code>proxmox_clone_and_tag_vms.yml</code></a> | Ansible playbook to safely clone, tag, and start Proxmox VMs |
| <a href="proxmox/proxmox_multi_vm_template_deploy.yml"><code>proxmox_multi_vm_template_deploy.yml</code></a> | Ansible playbook to bulk clone and start Proxmox VMs from Multiple Templates |
| <a href="proxmox/pve_assign_vm_permissions.py"><code>pve_assign_vm_permissions.py</code></a> | Assigns Proxmox permissions to users based on a CSV mapping via SSH. |
| <a href="proxmox/pve_destroy_vms.yml"><code>pve_destroy_vms.yml</code></a> | Ansible playbook to safely decommission and purge Proxmox VMs |
| <a href="proxmox/pve_revoke_vm_permissions.py"><code>pve_revoke_vm_permissions.py</code></a> | Revokes Proxmox permissions/roles from users based on a CSV mapping via SSH. |
| <a href="proxmox/setup-secondary-node.sh"><code>setup-secondary-node.sh</code></a> | Bootstraps a fresh Proxmox VE install as a secondary node and joins it to the existing cluster (run straight from GitHub). |
<!-- END_SECTION:tree -->
