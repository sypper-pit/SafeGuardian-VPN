#!/bin/bash

# Проверяем, были ли предоставлены IP-адрес и уникальный номер
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <IP-адрес> <Уникальный номер>"
    exit 1
fi

# IP-адрес и уникальный номер, предоставленные в качестве аргументов
WG_GATE_IP="$1"
UNIQUE_NUMBER="$2"

# Имя контейнера и пути к файлам конфигурации
CONTAINER_NAME="wg-gate$UNIQUE_NUMBER"
CONFIG_DIR="$(pwd)/$UNIQUE_NUMBER"
WG_CONFIG="$CONFIG_DIR/wg-client.conf"

# Проверка наличия файла конфигурации WireGuard
if [ ! -f "$WG_CONFIG" ]; then
    echo "Файл конфигурации WireGuard $WG_CONFIG не найден."
    exit 1
fi

# Создание и настройка контейнера с учетом уникального номера
echo "Создание и настройка контейнера $CONTAINER_NAME..."
lxc launch images:debian/12 "$CONTAINER_NAME"
sleep 20

# Настройка сетевых интерфейсов для контейнера
lxc exec "$CONTAINER_NAME" -- bash -c "echo -e '[Match]\nName=eth1\n\n[Network]\nAddress=$WG_GATE_IP/24' > /etc/systemd/network/10-static-eth1.network"
lxc exec "$CONTAINER_NAME" -- systemctl restart systemd-networkd

# Установка WireGuard в контейнере
lxc exec "$CONTAINER_NAME" -- apt update
lxc exec "$CONTAINER_NAME" -- apt install -y wireguard iptables iptables-persistent

# Копирование файла конфигурации WireGuard в контейнер
lxc file push "$WG_CONFIG" "$CONTAINER_NAME/etc/wireguard/wg0.conf"

# Поднятие интерфейса WireGuard в контейнере
lxc exec "$CONTAINER_NAME" -- systemctl enable wg-quick@wg0
lxc exec "$CONTAINER_NAME" -- systemctl start wg-quick@wg0

# Включение NAT и перенаправление трафика через wg0 в контейнере
lxc exec "$CONTAINER_NAME" -- bash -c "echo net.ipv4.ip_forward=1 > /etc/sysctl.d/99-forwarding.conf"
lxc exec "$CONTAINER_NAME" -- sysctl -p /etc/sysctl.d/99-forwarding.conf
lxc exec "$CONTAINER_NAME" -- iptables -A FORWARD -s 10.0.4.0/24 -i eth1 -o wg0 -j ACCEPT
lxc exec "$CONTAINER_NAME" -- iptables -A FORWARD -d 10.0.4.0/24 -i wg0 -o eth1 -j ACCEPT
lxc exec "$CONTAINER_NAME" -- iptables -A FORWARD -i eth1 -o eth0 -j REJECT
lxc exec "$CONTAINER_NAME" -- iptables -A FORWARD -i eth0 -o eth1 -j REJECT
lxc exec "$CONTAINER_NAME" -- iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
lxc exec "$CONTAINER_NAME" -- sh -c 'iptables-save > /etc/iptables/rules.v4'

echo "Настройка $CONTAINER_NAME завершена."
