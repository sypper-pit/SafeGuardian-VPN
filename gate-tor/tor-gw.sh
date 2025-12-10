#!/bin/bash
# tor-gw.sh - Tor DNS on 5353 + iptables redirect
# Ubuntu 24.04 + LXD 5.21.4

set -euo pipefail
export LC_ALL=C.UTF-8
export TZ=${TZ:-UTC}

if [[ $EUID -ne 0 ]]; then
    echo "Run as root" >&2
    exit 1
fi

read -rp "Enter number of Tor gateways (1-10): " count
if [[ ! "$count" =~ ^[1-9]$|^10$ ]]; then
    echo "Error: Invalid count (1-10)" >&2
    exit 1
fi

printf "=== PHASE 1: BASE SYSTEM SETUP ===\n"

# LXD + bridges (без изменений)
if ! command -v lxc &> /dev/null; then
    echo "Installing LXD..."
    apt update
    apt install -y lxd lxc
    lxd init --auto
fi

printf "\n=== PHASE 2: NETWORK BRIDGES ===\n"
if ! lxc network list | grep -q lxdbr0; then
    echo "Creating lxdbr0..."
    lxc network create lxdbr0 ipv4.nat=true ipv4.address=10.0.0.1/24 ipv4.dhcp=true
else
    echo "✓ lxdbr0 exists"
fi

declare -a tor_containers=()

printf "\n=== PHASE 3: TOR-GW CONTAINERS ===\n"
for ((i=0; i<count; i++)); do
    tor_ct="tor-gw${i}"
    tor_ip="172.16.${i}.1/24"
    tor_ip_plain="172.16.${i}.1"
    bridge="br-tor${i}"

    tor_containers+=("$tor_ct")
    printf "\n--- tor-gw%d (%s) ---\n" "$i" "$tor_ip_plain"

    # Cleanup + bridge (без изменений)
    echo "  Cleaning up..."
    lxc delete "$tor_ct" --force >/dev/null 2>&1 || true
    
    if lxc network show "$bridge" >/dev/null 2>&1; then
        echo "  Bridge $bridge normalizing..."
        lxc network set "$bridge" ipv4.address=none 2>/dev/null || true
        lxc network set "$bridge" ipv4.nat=false 2>/dev/null || true
    else
        echo "  Creating bridge $bridge..."
        lxc network create "$bridge" ipv4.address=none ipv4.nat=false ipv6.address=none ipv4.dhcp=false
    fi

    # Container + network (без изменений)
    echo "  Creating container..."
    lxc init ubuntu:24.04 "$tor_ct" -c limits.cpu=2 -c limits.memory=1GB -c boot.autostart=true
    lxc config set "$tor_ct" security.nesting=true
    lxc config device add "$tor_ct" eth0 nic name=eth0 network=lxdbr0 || true
    lxc config device add "$tor_ct" eth1 nic name=eth1 network="$bridge" || true
    lxc start "$tor_ct"
    sleep 20

    # Netplan (без изменений)
    echo "  Network config..."
    lxc exec "$tor_ct" -- bash -c "
        set -e
        mv /etc/netplan/*.yaml /tmp/ 2>/dev/null || true
        cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0: {dhcp4: true}
    eth1: {dhcp4: false, addresses: [${tor_ip}]}
EOF
        chmod 600 /etc/netplan/01-netcfg.yaml
        netplan generate && netplan apply
        sleep 5
        ip addr show eth1 | grep ${tor_ip_plain}
    "
    
    printf "  ✓ %s ready\n" "$tor_ip_plain"
done

# ✅ TOR DNS НА 5353 + IPTABLES
printf "\n=== PHASE 4: TOR DNS 5353 + PROXY ===\n"
for ((i=0; i<count; i++)); do
    tor_ct="${tor_containers[$i]}"
    tor_ip_plain="172.16.${i}.1"
    
    printf "=== %s ===\n" "$tor_ct"
    
    lxc exec "$tor_ct" -- bash -c "
        set -e
        export DEBIAN_FRONTEND=noninteractive
        
        apt-get update && apt-get upgrade -yq
        apt-get install -y tor iptables-persistent netfilter-persistent \
            dnsmasq iproute2 conntrack curl iputils-ping htop haveged
        
        systemctl enable --now haveged
        
        # ✅ TOR DNS НА ПОРТУ 5353
        cat > /etc/tor/torrc << EOF
Log notice file /var/log/tor/notices.log
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 0.0.0.0:9040
#TransListenAddr ${tor_ip_plain}
DNSPort 0.0.0.0:5353
#DNSListenAddr ${tor_ip_plain}
EOF
        
        systemctl restart tor && systemctl enable tor
        sleep 15
        
        # Проверка Tor DNS
        netstat -ln | grep 5353 && echo '✓ Tor DNS 5353 listening'
        
        if ! systemctl is-active --quiet tor; then
            echo '✗ Tor failed!' >&2
            journalctl -u tor -n 20
            exit 1
        fi
        
        # ✅ IPTABLES: DNS 53 → Tor 5353
        iptables -t nat -F
        iptables -t filter -F FORWARD
        iptables -P FORWARD DROP
        
        # Exclude local
        iptables -t nat -A PREROUTING -i eth1 -d 10.0.0.0/8 -j RETURN
        iptables -t nat -A PREROUTING -i eth1 -d 172.16.0.0/12 -j RETURN
        iptables -t nat -A PREROUTING -i eth1 -d 192.168.0.0/16 -j RETURN
        
        # ✅ DNS 53 → TOR 5353 (высокий приоритет)
        iptables -t nat -I PREROUTING 1 -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353
        iptables -t nat -I PREROUTING 2 -i eth1 -p tcp --dport 53 -j REDIRECT --to-ports 5353
        
        # TCP/UDP/ICMP → TransPort
        iptables -t nat -A PREROUTING -i eth1 -p tcp -j REDIRECT --to-ports 9040
        iptables -t nat -A PREROUTING -i eth1 -p udp -j REDIRECT --to-ports 9040  
        iptables -t nat -A PREROUTING -i eth1 -p icmp -j REDIRECT --to-ports 9040
        
        # Forward
        iptables -I FORWARD 1 -i eth1 -p tcp --dport 9040 -j ACCEPT
        iptables -I FORWARD 2 -i eth1 -p udp --dport 5353 -j ACCEPT
        iptables -I FORWARD 3 -i eth1 -p udp --dport 9040 -j ACCEPT
        iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        
        iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        
        sysctl -w net.ipv4.ip_forward=1
        
        # dnsmasq → Tor DNS 5353
        cat > /etc/dnsmasq.conf << EOF
interface=eth1
listen-address=${tor_ip_plain}
dhcp-range=172.16.${i}.10,172.16.${i}.254,12h
server=127.0.0.1#5353
no-resolv
EOF
        systemctl restart dnsmasq && systemctl enable dnsmasq
        
        echo 'nameserver 127.0.0.1' > /etc/resolv.conf
        netfilter-persistent save
        
        echo '✓ Tor DNS 5353 + Transparent Proxy READY'
    "
    
    printf "✓ tor-gw%d: DNS=5353\n" "$i"
done

printf "\n🎉 %d TOR GATEWAYS w/ DNS 5353 READY!\n" "$count"
printf "tun-gw.sh will use: nameserver 172.16.X.1#5353\n"
lxc list | grep tor-gw
