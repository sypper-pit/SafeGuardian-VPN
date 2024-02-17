#!/bin/bash

# Проверяем, были ли предоставлены IP-адрес и уникальный номер
if [ "$#" -ne 2 ]; then
  echo "Использование: $0 <IP-адрес> <Уникальный номер>"
  exit 1
fi

# IP-адрес и уникальный номер, предоставленные в качестве аргументов
_ip_address="$1"
_unique_number="$2"

# Имя контейнера, включающее уникальный номер
_container_name="tor-over-ovpn-gate$_unique_number"

# Остальные переменные
_trans_port="9040"
_inc_if="eth1"

# IP-адрес для указания дефолтного GW и DNS
ip_address_gate="10.0.4.150"

# Проверяем, существует ли уже удаленный репозиторий ubuntu-minimal
if ! lxc remote list | grep -q "ubuntu-minimal"; then
  lxc remote add --protocol simplestreams ubuntu-minimal https://cloud-images.ubuntu.com/minimal/releases/
else
  echo "Источник образов Ubuntu Minimal уже добавлен."
fi

# Запускаем контейнер LXC с уникальным именем на базе Ubuntu Minimal
lxc launch ubuntu-minimal:jammy $_container_name -p user-profile

# Устанавливаем настройки сети в контейнере с учетом IP-адреса
lxc exec $_container_name -- bash -c "echo -e '[Match]\nName=eth1\n\n[Network]\nAddress=$_ip_address/24\nGateway=$ip_address_gate\nDNS=1.1.1.1\nDNS=10.0.4.200' > /etc/systemd/network/10-eth1.network"

# Перезапускаем systemd-networkd для применения настроек сети
lxc exec $_container_name -- systemctl restart systemd-networkd

# Обновляем список пакетов и устанавливаем необходимые пакеты
lxc exec $_container_name -- apt update
lxc exec $_container_name -- apt install -y tor iptables iptables-persistent curl

# Получить список текущих DNS-серверов
lxc exec $_container_name -- bash -c "cat /etc/resolv.conf"

# Изменить DNS-серверы
lxc exec $_container_name -- bash -c "echo -e 'nameserver 1.1.1.1\nnameserver 1.0.0.1' > /etc/resolv.conf"

# Проверить изменения
lxc exec $_container_name -- bash -c "cat /etc/resolv.conf"


# Проверяем работу Tor и соединение с внешним миром
lxc exec $_container_name -- torify curl ifconfig.io

# Проверяем статус Tor до внесения изменений в torrc
echo "Проверка статуса Tor до изменений..."
lxc exec $_container_name -- systemctl status tor

# Добавляем конфигурацию в torrc
lxc exec $_container_name -- bash -c "echo -e 'VirtualAddrNetworkIPv4 10.192.0.0/10\nAutomapHostsOnResolve 1\nTransPort $_ip_address:9040\nDNSPort $_ip_address:5353' >> /etc/tor/torrc"

# Перезапускаем Tor для применения новой конфигурации
lxc exec $_container_name -- systemctl restart tor

# Проверяем статус Tor после внесения изменений...
echo "Проверка статуса Tor после изменений..."
lxc exec $_container_name -- systemctl status tor

# Создаем и применяем правила iptables внутри контейнера

# Очистка всех существующих правил iptables
echo "Очистка всех существующих правил iptables..."
lxc exec $_container_name -- bash -c "iptables -F"
lxc exec $_container_name -- bash -c "iptables -t nat -F"

# Перенаправление входящего TCP трафика на порт для прозрачной работы Tor
echo "Перенаправление входящего TCP трафика на Tor TransPort ($_trans_port)..."
lxc exec $_container_name -- bash -c "iptables -t nat -A PREROUTING -i $_inc_if -p tcp --syn -j REDIRECT --to-ports $_trans_port"

# Сохраняем правила iptables
echo "Сохранение правил iptables..."
lxc exec $_container_name -- sh -c 'iptables-save > /etc/iptables/rules.v4'

# Отключаем роутинг
lxc exec $_container_name -- bash -c "echo 'net.ipv4.ip_forward = 0' | sudo tee -a /etc/sysctl.conf"

echo "Настройка $_container_name завершена."
