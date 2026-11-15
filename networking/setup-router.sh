#!/usr/bin/env bash
# Configure NAT Router + DHCP/DNS Server (Distro-Agnostic & Modern)
# Must be run as root

set -euo pipefail

#--- Help and Guard Rails
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root. Exiting." >&2
  exit 1
fi

#--- Utility: Distro & Package Manager Detection
detect_pkg_manager() {
  if command -v apt-get >/dev/null; then
    PACKAGER="apt"
  elif command -v dnf >/dev/null; then
    PACKAGER="dnf"
  elif command -v pacman >/dev/null; then
    PACKAGER="pacman"
  elif command -v zypper >/dev/null; then
    PACKAGER="zypper"
  else
    echo "Error: Supported package manager (apt, dnf, zypper, pacman) not found." >&2
    exit 1
  fi
}

#--- Utility: Install Packages Agnostically
install_packages() {
  local pkgs=("$@")
  echo "Installing packages (${pkgs[*]}) using $PACKAGER..."
  case "$PACKAGER" in
  apt)
    DEBIAN_FRONTEND=noninteractive apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
    ;;
  dnf)
    dnf install -y "${pkgs[@]}"
    ;;
  pacman)
    pacman -Sy --noconfirm "${pkgs[@]}"
    ;;
  zypper)
    zypper --non-interactive install "${pkgs[@]}"
    ;;
  esac
}

#--- Helper to prompt with a default value
prompt() {
  local var_name="$1" prompt_text="$2" default="$3"
  local input
  read -r -p "$prompt_text [$default]: " input
  eval "$var_name=\"\${input:-\$default}\""
}

echo "============================================="
echo "   MODERN AGNOSTIC NAT + DHCP ROUTER SETUP   "
echo "============================================="

# Detect Package Manager
detect_pkg_manager

# Gathering Network Parameters
prompt WAN_IF "Enter your WAN (Internet) interface" "eth0"
prompt LAN_IF "Enter your LAN (Private) interface" "eth1"
prompt LAN_IP "Enter LAN Gateway IP address" "192.168.1.1"
prompt LAN_NET "Enter LAN Network subnet (CIDR format)" "192.168.1.0/24"
prompt DHCP_START "Enter DHCP range start IP" "192.168.1.10"
prompt DHCP_END "Enter DHCP range end IP" "192.168.1.100"
prompt DNS_SERVERS "Enter Upstream DNS servers (comma-separated)" "1.1.1.1,8.8.8.8"

echo
echo "1) Enabling IPv4 Forwarding..."
mkdir -p /etc/sysctl.d
echo "net.ipv4.ip_forward = 1" >/etc/sysctl.d/99-router-forward.conf
sysctl -p /etc/sysctl.d/99-router-forward.conf || sysctl --system

echo
echo "2) Assigning IP Address to LAN Interface ($LAN_IF)..."
# Set LAN gateway interface IP
ip addr replace "$LAN_IP/24" dev "$LAN_IF" || true
ip link set "$LAN_IF" up

echo
echo "3) Setting up Firewall & NAT using nftables..."
# Ensure nftables is installed
if ! command -v nft >/dev/null; then
  install_packages nftables
fi

# Create and apply modern nftables rulesets (supports fast masquerade & routing)
cat <<EOF >/etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority filter; policy accept;
        # Allow internal traffic & established connections
        iifname "lo" accept
        ct state established,related accept
    }

    chain forward {
        type filter hook forward priority filter; policy drop;
        # Forward LAN to WAN
        iifname "$LAN_IF" oifname "$WAN_IF" accept
        # Allow established back in
        iifname "$WAN_IF" oifname "$LAN_IF" ct state established,related accept
    }
}

table ip nat {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        # Modern Masquerade for outbound LAN traffic
        oifname "$WAN_IF" ip saddr $LAN_NET masquerade
    }
}
EOF

nft -f /etc/nftables.conf
systemctl enable nftables || true
systemctl restart nftables || true

echo
echo "4) Configuring DHCP and DNS using dnsmasq..."
# Install dnsmasq (highly efficient combined DNS & DHCP)
if ! command -v dnsmasq >/dev/null; then
  install_packages dnsmasq
fi

# Deconflict with Systemd-Resolved if present (Standard on modern Ubuntu/Systemd OS)
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
  echo "De-conflicting Systemd-Resolved on port 53..."
  # If local resolver is on, instruct it not to grab Port 53, or rely on Dnsmasq
  mkdir -p /etc/systemd/resolved.conf.d || true
  cat <<EOF >/etc/systemd/resolved.conf.d/dnsmasq.conf
[Resolve]
DNSStubListener=no
EOF
  systemctl restart systemd-resolved || true
fi

# Make a backup of any current dnsmasq config
[ -f /etc/dnsmasq.conf ] && mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak

# Setup brand new optimized Dnsmasq Config
cat <<EOF >/etc/dnsmasq.conf
# Interfaces to listen on
interface=$LAN_IF
bind-interfaces

# DHCP range and lease time
dhcp-range=$DHCP_START,$DHCP_END,255.255.255.0,12h

# Gateway (Router)
dhcp-option=3,$LAN_IP

# Upstream DNS
$(for dns in ${DNS_SERVERS//,/ }; do echo "server=$dns"; done)
# DNS servers to hand out to DHCP clients
dhcp-option=6,$LAN_IP

# Set DHCP Lease store
dhcp-leasefile=/var/lib/misc/dnsmasq.leases

# Logging
log-facility=/var/log/dnsmasq.log
log-queries
log-dhcp
EOF

# Restart/Activate Service
systemctl enable dnsmasq
systemctl restart dnsmasq

echo
echo "=== SETUP COMPLETE! ==="
echo "WAN Link:       $WAN_IF"
echo "LAN Link:       $LAN_IF ($LAN_IP)"
echo "LAN Subnet:     $LAN_NET"
echo "DHCP Pool:      $DHCP_START → $DHCP_END"
echo "Upstream DNS:   $DNS_SERVERS"
echo "============================================="
