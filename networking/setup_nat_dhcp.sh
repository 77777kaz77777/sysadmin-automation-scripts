#!/usr/bin/env bash
# Configure NAT router + DHCP server
# Must be run as root

set -e

#--- Helper to prompt with default
prompt() {
  local var_name="$1" prompt_text="$2" default="$3"
  read -p "$prompt_text [$default]: " input
  export "$var_name"="${input:-$default}"
}

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Exiting."
  exit 1
fi

echo "=== NAT + DHCP Setup ==="
# Replaced generic "ip" defaults with realistic network defaults
prompt WAN_IF "Enter your WAN interface name" "eth0"
prompt LAN_IF "Enter your LAN interface name" "eth1"
prompt LAN_NET "Enter your LAN network address" "192.168.1.0"
prompt NETMASK "Enter your LAN netmask" "255.255.255.0"
prompt DHCP_START "Enter DHCP range start IP" "192.168.1.10"
prompt DHCP_END "Enter DHCP range end IP" "192.168.1.100"
prompt GATEWAY "Enter LAN gateway IP" "192.168.1.1"
prompt DNS_SERVERS "Enter DNS servers (comma-separated)" "1.1.1.1, 8.8.8.8"

echo
echo "1) Enabling IPv4 forwarding..."
cat > /etc/sysctl.d/99-ip-forward.conf <<EOF
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/99-ip-forward.conf

echo
echo "Updating package lists..."
apt-get update -y

echo
echo "2) Flushing existing iptables rules..."
iptables -t nat -F
iptables -F FORWARD

echo "   Applying NAT rules..."
iptables -t nat -A POSTROUTING -s ${LAN_NET}/${NETMASK} -o "$WAN_IF" -j MASQUERADE
iptables -A FORWARD -i "$LAN_IF" -o "$WAN_IF" -j ACCEPT
# Updated from deprecated '-m state --state' to '-m conntrack --ctstate'
iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

echo "   Installing iptables-persistent to save rules..."
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
netfilter-persistent save

echo
echo "3) Installing and configuring ISC DHCP server..."
# Added noninteractive flag to prevent package installation prompts from hanging the script
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-server

# Write dhcpd.conf
cat > /etc/dhcp/dhcpd.conf <<EOF
default-lease-time 600;
max-lease-time 7200;

subnet ${LAN_NET} netmask ${NETMASK} {
  range ${DHCP_START} ${DHCP_END};
  option routers ${GATEWAY};
  option domain-name-servers ${DNS_SERVERS};
}
EOF

# Tell DHCP server which interface to listen on
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="'"${LAN_IF}"'"/' /etc/default/isc-dhcp-server

# Restart service instead of just enabling it (package installation starts the service with an unconfigured state and fails)
systemctl restart isc-dhcp-server
systemctl enable isc-dhcp-server

echo
echo "=== Done! ==="
echo "WAN: $WAN_IF"
echo "LAN: $LAN_IF ($LAN_NET/$NETMASK)"
echo "DHCP: $DHCP_START → $DHCP_END, gateway $GATEWAY"
echo "DNS: $DNS_SERVERS"
