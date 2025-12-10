#!/bin/bash
# launcher.sh - FIXED formatting Tor proxy launcher
# Ubuntu 24.04 + LXD 5.21.4

set -euo pipefail
export LC_ALL=C.UTF-8
export TZ=${TZ:-UTC}

clear

# Цвета (экранированные для heredoc)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
NC=$(tput sgr0)

log() { echo "[$(date +%H:%M:%S)] $1"; }
success() { echo "${GREEN}✓ $1${NC}"; }
warn() { echo "${YELLOW}⚠ $1${NC}"; }
error() { echo "${RED}✗ $1${NC}"; exit 1; }

print_banner() {
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                TOR TRANSPARENT PROXY LAUNCHER                ║
║                 Ubuntu 24.04 + LXD 5.21.4                    ║
╚══════════════════════════════════════════════════════════════╝
EOF
}

show_menu() {
    clear
    print_banner
    cat << EOF

${GREEN}1.${NC} Install & Setup Tor Gateways (tor-gw.sh)
${GREEN}2.${NC} Install Tun Clients (tun-gw.sh) 
${GREEN}3.${NC} Full setup (1+2)
${GREEN}4.${NC} Status check
${GREEN}5.${NC} Test connectivity
${GREEN}6.${NC} Cleanup all
${GREEN}7.${NC} Exit

EOF
    read -rp "Choose option (1-7): " choice
}

check_scripts() {
    log "Checking scripts..."
    for script in tor-gw.sh tun-gw.sh; do
        if [[ ! -f "$script" ]]; then
            error "Missing $script - download first"
        fi
        chmod +x "$script" 2>/dev/null || true
    done
    success "Scripts ready"
}

status() {
    log "Infrastructure status:"
    printf "\n%s\n" "${BLUE}Containers:${NC}"
    lxc list --fancy 2>/dev/null || echo "No containers found"
    
    printf "\n%s\n" "${BLUE}Bridges:${NC}"
    lxc network list | grep -E "(br-tor|lxdbr0)" || echo "No bridges"
    
    printf "\n%s\n" "${BLUE}Tor status:${NC}"
    for ct in tor-gw*; do
        if lxc info "$ct" >/dev/null 2>&1; then
            status=$(lxc exec "$ct" -- systemctl is-active tor 2>/dev/null || echo "unknown")
            state=$(lxc ls --fancy | grep "$ct" | awk '{print $2}')
            printf "%s %-12s %s\n" "$state" "$ct" "$status"
        fi
    done | column -t
}

install_tor_gw() {
    read -rp "Number of Tor gateways (1-10) [1]: " -e -i "1" count
    if [[ ! "$count" =~ ^[1-9]$|^10$ ]]; then
        error "Invalid count (1-10)"
    fi
    
    log "Installing $count Tor gateways..."
    echo "$count" | ./tor-gw.sh
    success "$count Tor gateways ready!"
}

install_tun_gw() {
    read -rp "Number of Tun clients (1-10) [1]: " -e -i "1" count
    if [[ ! "$count" =~ ^[1-9]$|^10$ ]]; then
        error "Invalid count (1-10)"
    fi
    
    log "Installing $count Tun clients..."
    ./tun-gw.sh "$count"
    success "$count Tun clients connected!"
}

full_setup() {
    read -rp "Number of pairs (1-10) [1]: " -e -i "1" count
    if [[ ! "$count" =~ ^[1-9]$|^10$ ]]; then
        error "Invalid count (1-10)"
    fi
    
    log "Full setup: $count pairs (Tor + Tun)"
    echo "$count" | ./tor-gw.sh
    echo "$count" | ./tun-gw.sh
    success "Complete infrastructure ready!"
}

test_connectivity() {
    log "Testing connectivity..."
    tun_count=$(lxc list | grep tun-gw | wc -l)
    
    if [[ $tun_count -eq 0 ]]; then
        warn "No tun-gw containers - install first"
        return 1
    fi
    
    for i in $(seq 0 $((tun_count-1))); do
        tun_ct="tun-gw${i}"
        if lxc info "$tun_ct" >/dev/null 2>&1; then
            printf "\n${BLUE}--- Testing %s ---${NC}\n" "$tun_ct"
            
            if lxc exec "$tun_ct" -- timeout 10 curl -s ifconfig.me 2>/dev/null; then
                success "TCP OK"
            else
                warn "TCP failed"
            fi
            
            if lxc exec "$tun_ct" -- timeout 5 nslookup google.com >/dev/null 2>&1; then
                success "DNS OK"
            else
                warn "DNS failed"
            fi
            
            if lxc exec "$tun_ct" -- timeout 5 ping -c2 8.8.8.8 >/dev/null 2>&1; then
                success "Ping OK"
            else
                warn "Ping failed"
            fi
        fi
    done
}

cleanup_all() {
    read -rp "${YELLOW}⚠️  Delete ALL containers/bridges? (y/N): ${NC}" confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { warn "Aborted"; return; }
    
    log "🧹 Full cleanup started..."
    
    # 1. Stop ALL containers
    log "Stopping containers..."
    mapfile -t containers < <(lxc list --format csv | cut -d, -f1 | grep -E "(tor-gw|tun-gw)")
    for ct in "${containers[@]}"; do
        if lxc info "$ct" >/dev/null 2>&1; then
            lxc stop "$ct" || true
            success "Stopped $ct"
        fi
    done
    
    # 2. Remove network devices FIRST
    log "Removing network devices..."
    for ct in "${containers[@]}"; do
        if lxc info "$ct" >/dev/null 2>&1; then
            lxc config device remove "$ct" eth0 2>/dev/null || true
            lxc config device remove "$ct" eth1 2>/dev/null || true
        fi
    done
    
    # 3. Delete containers
    log "Deleting containers..."
    for ct in "${containers[@]}"; do
        if lxc info "$ct" >/dev/null 2>&1; then
            lxc delete "$ct" --force
            success "Deleted $ct"
        fi
    done
    
    # 4. ✅ FIXED: Delete bridges WITHOUT --force
    log "Deleting bridges..."
    mapfile -t bridges < <(lxc network list --format csv | cut -d, -f1 | grep "^br-tor")
    for bridge in "${bridges[@]}"; do
        if lxc network show "$bridge" >/dev/null 2>&1; then
            # Stop network first
            lxc network stop "$bridge" 2>/dev/null || true
            sleep 2
            lxc network delete "$bridge"
            success "Deleted $bridge"
        fi
    done
    
    # 5. Clean LXD iptables chains
    log "Cleaning iptables..."
    iptables -t nat -F 2>/dev/null || true
    iptables -t filter -F 2>/dev/null || true
    iptables -X 2>/dev/null || true
    
    # 6. Final verification
    log "Verification..."
    remaining_containers=$(lxc list | grep -c -E "(tor-gw|tun-gw)")
    remaining_bridges=$(lxc network list | grep -c "br-tor")
    
    if [[ $remaining_containers -eq 0 && $remaining_bridges -eq 0 ]]; then
        success "✅ COMPLETE CLEANUP SUCCESS!"
        echo "System ready for new setup"
    else
        warn "⚠️  $remaining_containers containers, $remaining_bridges bridges remain"
        lxc list | grep -E "(tor-gw|tun-gw)"
        lxc network list | grep br-tor
    fi
}


# Основной цикл
main() {
    check_scripts
    
    while true; do
        show_menu
        
        case $choice in
            1) install_tor_gw ;;
            2) install_tun_gw ;;
            3) full_setup ;;
            4) status ;;
            5) test_connectivity ;;
            6) cleanup_all ;;
            7) echo "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) warn "Invalid option (1-7)" ;;
        esac
        
        read -rp "${YELLOW}Press Enter to continue...${NC}"
    done
}

main "$@"
