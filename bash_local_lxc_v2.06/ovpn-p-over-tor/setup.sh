#!/bin/bash

# Проверяем, были ли предоставлены IP-адрес и уникальный номер
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <IP-адрес> <Уникальный номер>"
    exit 1
fi

# IP-адрес и уникальный номер, предоставленные в качестве аргументов
USER_IP="$1"
UNIQUE_NUMBER="$2"

# Имя контейнера, включающее уникальный номер
CONTAINER_NAME="ovpn-p-over-tor-gate$UNIQUE_NUMBER"

# IP-адрес для указания дефолтного GW и DNS
ip_address_gate="10.0.4.200"

# Пути к файлам конфигурации и аутентификации OpenVPN
OVPN_CONFIG="$(pwd)/$UNIQUE_NUMBER/client.ovpn"
OVPN_AUTH="$(pwd)/$UNIQUE_NUMBER/passwd.txt"

# Проверяем, существует ли профиль user-profile
if ! lxc profile show user-profile > /dev/null 2>&1; then
    echo "Создание нового профиля user-profile..."
    lxc profile create user-profile
    lxc profile set user-profile user.network_mode ""
    echo "config: {}
description: Custom profile for user
devices:
  eth1:
    name: eth1
    network: lan0
    type: nic
  root:
    path: /
    pool: default
    type: disk" | lxc profile edit user-profile
else
    echo "Профиль user-profile уже существует."
fi

# Проверка наличия файлов конфигурации и аутентификации OpenVPN
if [ ! -f "$OVPN_CONFIG" ]; then
    echo "Файл конфигурации OpenVPN $OVPN_CONFIG не найден."
    exit 1
fi

if [ ! -f "$OVPN_AUTH" ]; then
    echo "Файл аутентификации OpenVPN $OVPN_AUTH не найден."
    exit 1
fi

# Создание и настройка контейнера с учетом уникального номера
echo "Создание и настройка контейнера $CONTAINER_NAME..."
lxc launch images:debian/12 "$CONTAINER_NAME"
sleep 5

# Настройка сетевых интерфейсов для контейнера
echo "Настройка сетевых интерфейсов для $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- bash -c "echo -e '[Network]\nDHCP=no' > /etc/systemd/network/10-static-eth1.network"
lxc exec "$CONTAINER_NAME" -- bash -c "echo -e '[Match]\nName=eth1\n\n[Network]\nAddress=$USER_IP/24\nGateway=$ip_address_gate\nDNS=$ip_address_gate\nDNS=1.1.1.1' > /etc/systemd/network/10-static-eth1.network"
lxc exec "$CONTAINER_NAME" -- systemctl restart systemd-networkd

# Установка OpenVPN и debconf-utils в контейнере
lxc exec "$CONTAINER_NAME" -- apt update
lxc exec "$CONTAINER_NAME" -- apt install -y openvpn iptables debconf-utils

# Предварительная конфигурация iptables-persistent
lxc exec "$CONTAINER_NAME" -- bash -c "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections"
lxc exec "$CONTAINER_NAME" -- bash -c "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections"

# Установка iptables-persistent без взаимодействия
lxc exec "$CONTAINER_NAME" -- apt install -y iptables-persistent

# Копирование файлов конфигурации и аутентификации OpenVPN в контейнер
lxc file push "$OVPN_CONFIG" "$CONTAINER_NAME/etc/openvpn/client.conf"
lxc file push "$OVPN_AUTH" "$CONTAINER_NAME/etc/openvpn/passwd.txt"

# Обновление конфигурации OpenVPN для использования файла аутентификации
lxc exec "$CONTAINER_NAME" -- sed -i 's|auth-user-pass|auth-user-pass /etc/openvpn/passwd.txt|' /etc/openvpn/client.conf

# Запуск и включение OpenVPN
lxc exec "$CONTAINER_NAME" -- systemctl start openvpn@client
lxc exec "$CONTAINER_NAME" -- systemctl enable openvpn@client

# Включение NAT и перенаправление трафика для контейнера
lxc exec "$CONTAINER_NAME" -- bash -c "echo net.ipv4.ip_forward=1 > /etc/sysctl.d/99-forwarding.conf"
lxc exec "$CONTAINER_NAME" -- sysctl -p /etc/sysctl.d/99-forwarding.conf
lxc exec "$CONTAINER_NAME" -- iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
lxc exec "$CONTAINER_NAME" -- iptables -A FORWARD -s 10.0.4.0/24 -i eth1 -o tun0 -j ACCEPT
lxc exec "$CONTAINER_NAME" -- iptables -A FORWARD -d 10.0.4.0/24 -i tun0 -o eth1 -j ACCEPT
lxc exec "$CONTAINER_NAME" -- iptables -A FORWARD -i eth1 -o eth0 -j REJECT
lxc exec "$CONTAINER_NAME" -- iptables -A FORWARD -i eth0 -o eth1 -j REJECT
lxc exec "$CONTAINER_NAME" -- sh -c 'iptables-save > /etc/iptables/rules.v4'

echo "Настройка $CONTAINER_NAME завершена."
