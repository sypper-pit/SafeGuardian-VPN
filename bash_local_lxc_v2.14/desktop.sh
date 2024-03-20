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
CONTAINER_NAME="desktop$UNIQUE_NUMBER"

# IP-адрес для указания дефолтного GW и DNS
ip_address_gate="10.0.4.200"

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

# Создание контейнера с учетом уникального номера
echo "Создание контейнера $CONTAINER_NAME ..."
lxc launch images:debian/12 "$CONTAINER_NAME" -p user-profile
sleep 20

# Настройка сетевых интерфейсов для контейнера
echo "Настройка сетевых интерфейсов для $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- bash -c "echo -e '[Match]\nName=eth1\n\n[Network]\nAddress=$USER_IP/24\nGateway=$ip_address_gate\nDNS=$ip_address_gate' > /etc/systemd/network/10-static-eth1.network"
lxc exec "$CONTAINER_NAME" -- systemctl restart systemd-networkd

# Настройка DNS для контейнера
echo "Настройка DNS для $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- bash -c "mkdir -p /etc/systemd/resolved.conf.d && echo -e '[Resolve]\nDNS=10.0.4.200' > /etc/systemd/resolved.conf.d/dns.conf"

lxc exec "$CONTAINER_NAME" -- systemctl restart systemd-resolved

echo "Настройка $CONTAINER_NAME завершена."
