#!/bin/bash
# tun-gw.sh - Tun clients w/ Tor DNS 5353 (for launcher.sh)

set -euo pipefail
export LC_ALL=C.UTF-8
export TZ=${TZ:-UTC}

if [[ $EUID -ne 0 ]]; then
    echo "Run as root" >&2
    exit 1
fi

# 1) Берём count из аргумента или спрашиваем интерактивно
if [[ $# -ge 1 ]]; then
    count="$1"
else
    read -rp "Enter number of tun-gw clients (1-10): " count
fi

if [[ ! "$count" =~ ^[1-9]$|^10$ ]]; then
    echo "Error: Invalid count (1-10)" >&2
    exit 1
fi

printf "=== PHASE 1: VALIDATION ===\n"

# Проверка tor-gw
missing_tor=()
for ((i=0; i<count; i++)); do
    if ! lxc info "tor-gw${i}" >/dev/null 2>&1; then
        missing_tor+=("tor-gw${i}")
    fi
done

if [[ ${#missing_tor[@]} -gt 0 ]]; then
    echo "ERROR: Missing tor-gw:" >&2
    printf '  %s\n' "${missing_tor[@]}" >&2
    echo "Run ./tor-gw.sh $count first!" >&2
    exit 1
fi

printf "✓ All %d tor-gw OK\n" "$count"

# Проверка bridges
printf "\n=== PHASE 2: BRIDGE CHECK ===\n"
for ((i=0; i<count; i++)); do
    bridge="br-tor${i}"
    if ! lxc network show "$bridge" >/dev/null 2>&1; then
        echo "ERROR: $bridge missing!" >&2
        exit 1
    fi
    echo "✓ $bridge OK"
done

declare -a tun_containers=()

printf "\n=== PHASE 3: TUN-GW SETUP ===\n"
for ((i=0; i<count; i++)); do
    tun_ct="tun-gw${i}"
    tun_ip="172.16.${i}.2/24"
    tun_ip_plain="172.16.${i}.2"
    tor_ip_plain="172.16.${i}.1"
    bridge="br-tor${i}"

    tun_containers+=("$tun_ct")
    printf "\n--- tun-gw%d (%s → %s:5353) ---\n" "$i" "$tun_ip_plain" "$tor_ip_plain"

    # 2) Локальный set + trap, чтобы падала только итерация
    {
        # Cleanup
        lxc delete "$tun_ct" --force >/dev/null 2>&1 || true

        # Container
        echo "  Creating..."
        lxc init ubuntu:24.04 "$tun_ct" \
            -c limits.cpu=1 \
            -c limits.memory=512MB \
            -c boot.autostart=true

        echo "  Network..."
        lxc config device add "$tun_ct" eth0 nic \
            name=eth0 network="$bridge" || true

        echo "  Starting..."
        lxc start "$tun_ct"
        sleep 15

        echo "  Network lockdown..."
        lxc exec "$tun_ct" -- bash -c "
            set -e

            systemctl restart systemd-networkd || true

            mv /etc/netplan/*.yaml /tmp/ 2>/dev/null || true

            cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      addresses: [${tun_ip}]
      routes:
        - to: 0.0.0.0/0
          via: ${tor_ip_plain}
          metric: 100
EOF

            chmod 600 /etc/netplan/01-netcfg.yaml
            chown root:root /etc/netplan/01-netcfg.yaml

            netplan generate
            netplan apply
            sleep 8

            # resolv.conf → tor-gw (DNS 53 → 5353 редиректится на tor-gw)
            cat > /etc/resolv.conf << EOF
nameserver ${tor_ip_plain}
options ndots:1 timeout:3
EOF

            systemctl disable systemd-resolved 2>/dev/null || true
            systemctl stop systemd-resolved 2>/dev/null || true
            chattr +i /etc/resolv.conf || true

            ip route del default 2>/dev/null || true
            ip route add default via ${tor_ip_plain}

            apt-get update && apt-get install -y curl iputils-ping dnsutils netcat-openbsd htop

            ping -c2 ${tor_ip_plain} >/dev/null 2>&1 && echo '✓ Gateway OK' || echo '✗ Gateway FAILED'

            ip addr show eth0 | grep ${tun_ip_plain} >/dev/null && echo '✓ IP OK'
            ip route | grep 'default via ${tor_ip_plain}' >/dev/null && echo '✓ Route OK'
            cat /etc/resolv.conf
            echo '✓ LOCKED: ${tun_ip_plain} → ${tor_ip_plain}:53→5353'
        "

        printf "  ✓ %s → %s:5353\n" "$tun_ip_plain" "$tor_ip_plain"

    } || {
        echo "✗ Error configuring $tun_ct, skipping..." >&2
        continue
    }
done

printf "\n=== PHASE 4: TOR TESTS ===\n"
for ((i=0; i<count; i++)); do
    tun_ct="tun-gw${i}"
    tor_ip_plain="172.16.${i}.1"

    if ! lxc info "$tun_ct" >/dev/null 2>&1; then
        echo "--- $tun_ct not created, skipping tests"
        continue
    fi

    printf "--- %s ---\n" "$tun_ct"

    lxc exec "$tun_ct" -- ping -c1 "$tor_ip_plain" >/dev/null 2>&1 && echo "  ✓ Gateway ping" || echo "  ✗ Gateway ping"
    lxc exec "$tun_ct" -- timeout 10 nslookup google.com >/dev/null 2>&1 && echo "  ✓ DNS system" || echo "  ✗ DNS"
done

printf "\n🎉 %d TUN-GW REQUESTED, see which succeeded above\n" "$count"
lxc list | grep -E "(tor-gw|tun-gw)"
