#!/usr/bin/env bash
# Bootstraps a fresh Proxmox VE install as a secondary node and joins it to the existing cluster (run straight from GitHub).
#
# Usage (on the NEW node, as root, right after installing Proxmox VE):
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/77777kaz77777/sysadmin-automation-scripts/main/proxmox/setup-secondary-node.sh)
#
# Every prompt can be pre-answered with an environment variable, e.g.:
#
#   PRIMARY_IP=192.168.1.10 JOIN_CLUSTER=yes \
#     bash <(curl -fsSL https://raw.githubusercontent.com/77777kaz77777/sysadmin-automation-scripts/main/proxmox/setup-secondary-node.sh)
#
# Variables (all optional):
#   PRIMARY_IP        IP/hostname of an existing cluster node (the primary)
#   JOIN_CLUSTER      yes/no - join the primary's cluster with `pvecm add`
#   LINK0             Corosync link0 address for THIS node (defaults to its main IP)
#   GITHUB_USER       Import this GitHub user's public SSH keys into root (default: 77777kaz77777)
#   IMPORT_SSH_KEYS   yes/no
#   TIMEZONE          e.g. America/Toronto
#   REMOVE_NAG        yes/no - hide the "No valid subscription" popup
#   INSTALL_ANSIBLE   yes/no - needed for the playbooks in this repo
#   REPO_DIR          Where to clone this repo on the node (default: /opt/sysadmin-automation-scripts)
#   NONINTERACTIVE    yes - never prompt, use defaults / env values

set -euo pipefail

REPO_URL="https://github.com/77777kaz77777/sysadmin-automation-scripts.git"
REPO_DIR="${REPO_DIR:-/opt/sysadmin-automation-scripts}"
LOG_FILE="/var/log/secondary-node-setup.log"
NONINTERACTIVE="${NONINTERACTIVE:-no}"

#--- Output helpers
info() { printf '\e[1;34m==>\e[0m %s\n' "$*"; }
ok() { printf '\e[1;32m ✔\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m !\e[0m %s\n' "$*" >&2; }
die() {
  printf '\e[1;31m ✘\e[0m %s\n' "$*" >&2
  exit 1
}

#--- Prompt helpers (read from /dev/tty so `curl | bash` still works)
can_prompt() { [[ "$NONINTERACTIVE" != "yes" ]] && [[ -r /dev/tty ]]; }

# ask VAR "Question" "default" -> keeps an existing env value, otherwise prompts
ask() {
  local var="$1" question="$2" default="${3:-}" reply
  if [[ -n "${!var:-}" ]]; then return; fi
  if can_prompt; then
    read -r -p "$question${default:+ [$default]}: " reply </dev/tty || true
    printf -v "$var" '%s' "${reply:-$default}"
  else
    printf -v "$var" '%s' "$default"
  fi
}

# ask_yn VAR "Question" yes|no -> normalises the answer to yes/no
ask_yn() {
  local var="$1" question="$2" default="$3"
  ask "$var" "$question (yes/no)" "$default"
  case "${!var,,}" in
  y | yes) printf -v "$var" yes ;;
  *) printf -v "$var" no ;;
  esac
}

#--- Guard rails
[[ $EUID -eq 0 ]] || die "Run this as root (on a fresh Proxmox node you are root by default)."
command -v pveversion >/dev/null || die "This doesn't look like a Proxmox VE host (pveversion not found)."

exec > >(tee -a "$LOG_FILE") 2>&1
info "Logging to $LOG_FILE"
info "Proxmox: $(pveversion)"

# shellcheck disable=SC1091
. /etc/os-release
CODENAME="${VERSION_CODENAME:?could not detect Debian codename}"
NODE_NAME="$(hostname -s)"
NODE_IP="$(hostname --ip-address 2>/dev/null | awk '{print $1}')"

echo
echo "=============================================="
echo "   PROXMOX SECONDARY NODE SETUP ($NODE_NAME)"
echo "=============================================="
echo

#--- Gather answers up front so the rest can run unattended
ask TIMEZONE "Timezone" "$(timedatectl show -p Timezone --value 2>/dev/null || echo America/Toronto)"
ask_yn REMOVE_NAG "Hide the 'No valid subscription' popup?" yes
ask_yn INSTALL_ANSIBLE "Install Ansible (for the playbooks in this repo)?" yes
ask_yn IMPORT_SSH_KEYS "Import SSH public keys from GitHub into root?" yes
if [[ "$IMPORT_SSH_KEYS" == yes ]]; then
  ask GITHUB_USER "GitHub username to pull keys from" "77777kaz77777"
fi
ask_yn JOIN_CLUSTER "Join this node to the primary node's cluster now?" yes
if [[ "$JOIN_CLUSTER" == yes ]]; then
  ask PRIMARY_IP "IP/hostname of the primary node" ""
  [[ -n "${PRIMARY_IP:-}" ]] || die "PRIMARY_IP is required to join a cluster."
  ask LINK0 "Corosync link0 address for THIS node" "$NODE_IP"
fi

#--- 1) Repositories: enterprise -> no-subscription
info "1) Switching apt repositories to pve-no-subscription ($CODENAME)"

disable_repo_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if [[ "$f" == *.sources ]]; then
    # deb822 format (PVE 9+)
    if grep -q '^Enabled:' "$f"; then
      sed -i 's/^Enabled:.*/Enabled: false/' "$f"
    else
      echo "Enabled: false" >>"$f"
    fi
  else
    sed -i 's/^\s*deb /# deb /' "$f"
  fi
  ok "Disabled $(basename "$f")"
}

for f in /etc/apt/sources.list.d/pve-enterprise.{list,sources} \
  /etc/apt/sources.list.d/ceph.{list,sources}; do
  # Only disable ceph files that point at the enterprise repo
  if [[ "$f" == *ceph* ]] && ! grep -qs 'enterprise.proxmox.com' "$f"; then continue; fi
  disable_repo_file "$f"
done

if [[ -d /etc/apt/sources.list.d ]] && ls /etc/apt/sources.list.d/*.sources >/dev/null 2>&1; then
  # Newer installs use deb822 files
  cat >/etc/apt/sources.list.d/pve-no-subscription.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: $CODENAME
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
  rm -f /etc/apt/sources.list.d/pve-no-subscription.list
else
  echo "deb http://download.proxmox.com/debian/pve $CODENAME pve-no-subscription" \
    >/etc/apt/sources.list.d/pve-no-subscription.list
fi
ok "pve-no-subscription repo configured"

#--- 2) Update the system
info "2) Updating packages (this can take a while)"
export DEBIAN_FRONTEND=noninteractive
APT_OPTS=(-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)
apt-get update
apt-get "${APT_OPTS[@]}" dist-upgrade

#--- 3) Base tooling
info "3) Installing base tools"
PKGS=(curl wget git vim htop btop tmux jq rsync nfs-common chrony ethtool lm-sensors smartmontools)
[[ "$INSTALL_ANSIBLE" == yes ]] && PKGS+=(ansible)
# Skip anything this Debian release doesn't ship instead of failing the whole run
AVAILABLE=()
for p in "${PKGS[@]}"; do
  if apt-cache show "$p" >/dev/null 2>&1; then AVAILABLE+=("$p"); else warn "Package not available, skipping: $p"; fi
done
apt-get "${APT_OPTS[@]}" install "${AVAILABLE[@]}"
systemctl enable --now chrony >/dev/null 2>&1 || true

#--- 4) Timezone
info "4) Setting timezone to $TIMEZONE"
timedatectl set-timezone "$TIMEZONE" || warn "Could not set timezone '$TIMEZONE'"

#--- 5) Subscription nag
if [[ "$REMOVE_NAG" == yes ]]; then
  info "5) Removing subscription popup (persists across updates)"
  cat >/etc/apt/apt.conf.d/no-nag-script <<'EOF'
DPkg::Post-Invoke { "if [ -s /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ] && ! grep -q -F 'NoMoreNagging' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; then sed -i '/.*data\.status.*{/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; fi"; };
EOF
  apt-get "${APT_OPTS[@]}" --reinstall install proxmox-widget-toolkit >/dev/null
  ok "Popup removed (clear your browser cache if you still see it)"
else
  info "5) Leaving subscription popup alone"
fi

#--- 6) SSH keys from GitHub
if [[ "$IMPORT_SSH_KEYS" == yes ]]; then
  info "6) Importing SSH keys for github.com/$GITHUB_USER"
  install -d -m 700 /root/.ssh
  touch /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  if keys="$(curl -fsSL "https://github.com/${GITHUB_USER}.keys")" && [[ -n "$keys" ]]; then
    added=0
    while IFS= read -r key; do
      [[ -z "$key" ]] && continue
      if ! grep -qxF "$key" /root/.ssh/authorized_keys; then
        echo "$key" >>/root/.ssh/authorized_keys
        added=$((added + 1))
      fi
    done <<<"$keys"
    ok "Added $added new key(s)"
  else
    warn "No keys found for GitHub user '$GITHUB_USER'"
  fi
else
  info "6) Skipping SSH key import"
fi

#--- 7) Clone this repo onto the node
info "7) Syncing $REPO_URL -> $REPO_DIR"
if [[ -d "$REPO_DIR/.git" ]]; then
  git -C "$REPO_DIR" pull --ff-only || warn "Could not update existing clone at $REPO_DIR"
else
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
fi
ok "Repo available at $REPO_DIR"

#--- 8) Join the cluster
if [[ "$JOIN_CLUSTER" == yes ]]; then
  info "8) Joining cluster via $PRIMARY_IP"
  join_ok=yes

  if [[ -f /etc/pve/corosync.conf ]]; then
    warn "This node is already part of a cluster - skipping join."
    join_ok=no
  fi

  if [[ "$join_ok" == yes ]] && { [[ $(qm list 2>/dev/null | wc -l) -gt 1 ]] || [[ $(pct list 2>/dev/null | wc -l) -gt 1 ]]; }; then
    warn "This node already has VMs/containers. A node must be empty to join a cluster - skipping."
    join_ok=no
  fi

  if [[ "$join_ok" == yes ]] && [[ -z "$NODE_IP" || "$NODE_IP" == 127.* ]]; then
    warn "'$NODE_NAME' resolves to '${NODE_IP:-nothing}'. Fix /etc/hosts so it maps to the node's LAN IP, then re-run."
    join_ok=no
  fi

  if [[ "$join_ok" == yes ]] && ! ping -c 1 -W 2 "$PRIMARY_IP" >/dev/null 2>&1; then
    warn "Cannot reach $PRIMARY_IP - skipping join. Check cabling/network and re-run."
    join_ok=no
  fi

  if [[ "$join_ok" == yes ]]; then
    JOIN_CMD=(pvecm add "$PRIMARY_IP")
    [[ -n "${LINK0:-}" ]] && JOIN_CMD+=(--link0 "$LINK0")
    echo "You'll be asked for the PRIMARY node's root password and to accept its fingerprint."
    if can_prompt; then
      "${JOIN_CMD[@]}" </dev/tty
    else
      warn "Cluster join needs a password prompt; run this manually: ${JOIN_CMD[*]}"
      join_ok=no
    fi
    if [[ "$join_ok" == yes ]]; then
      ok "Joined cluster - shared storage (e.g. NFS) from /etc/pve/storage.cfg is now visible here."
    fi
  fi
else
  info "8) Skipping cluster join (run later: pvecm add <primary-ip>)"
fi

#--- Summary
echo
echo "=============== SETUP COMPLETE ==============="
echo "Node:          $NODE_NAME (${NODE_IP:-unknown IP})"
echo "Repo:          $REPO_DIR"
echo "Cluster:       $(pvecm status 2>/dev/null | awk -F': *' '/^Name:/{print $2}' || true)"
echo "Web UI:        https://${NODE_IP:-<node-ip>}:8006"
echo "Log:           $LOG_FILE"
echo "=============================================="
if [[ -f /var/run/reboot-required ]] || [[ "$(uname -r)" != "$(find /boot -maxdepth 1 -name 'vmlinuz-*' | sort -V | tail -1 | sed 's|.*/vmlinuz-||')" ]]; then
  warn "A new kernel was installed - reboot when convenient."
fi
