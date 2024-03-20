#!/bin/bash

# Проверяем, были ли предоставлены IP-адрес и уникальный номер
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <IP-адрес> <Уникальный номер>"
    exit 1
fi

# Определения
USER_IP="$1"
UNIQUE_NUMBER="$2"
CONTAINER_NAME="vpn-serv$UNIQUE_NUMBER"
ip_address_gate="10.0.4.200"
CERT_DIR="/usr/local/etc/xray"
CONFIG_FILE="$CERT_DIR/config.json"

# Запрашиваем пароль у пользователя и сохраняем его в переменную
read -sp "Введите пароль для нового пользователя в контейнере и нажмите [Enter]: " CONTAINER_PASSWORD
echo ""  # Добавляем новую строку после ввода пароля

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

# Проброс портов внутри контейнера
#EXTERNAL_PORT=$((8220 + UNIQUE_NUMBER))
#INTERNAL_PORT=22
#echo "Проброс порта с $EXTERNAL_PORT на $INTERNAL_PORT для $CONTAINER_NAME ..."
#lxc config device add "$CONTAINER_NAME" ssh-port$UNIQUE_NUMBER proxy listen=tcp:0.0.0.0:$EXTERNAL_PORT connect=tcp:127.0.0.1:$INTERNAL_PORT

# Проброс портов внутри контейнера
EXTERNAL_vpn_PORT=$((442 + UNIQUE_NUMBER))
INTERNAL_vpn_PORT=$((442 + UNIQUE_NUMBER))
echo "Проброс порта с $EXTERNAL_vpn_PORT на $INTERNAL_vpn_PORT для $CONTAINER_NAME ..."
lxc config device add "$CONTAINER_NAME" vpn-port$UNIQUE_NUMBER proxy listen=tcp:0.0.0.0:$EXTERNAL_vpn_PORT connect=tcp:127.0.0.1:$INTERNAL_vpn_PORT


# Установка openssh-server внутри контейнера
echo "Установка ПО для $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- apt-get update
lxc exec "$CONTAINER_NAME" -- apt-get install -y openssh-server openssl curl wget nginx

# Настройка разрешений для root подключения через SSH
echo "Настройка SSH для разрешения входа root в $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- bash -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"

# Перезапуск сервиса SSH для применения настроек
echo "Перезапуск SSH в $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- systemctl restart sshd

# Установка пароля для пользователя 'root' внутри контейнера
echo "Установка пароля для пользователя в контейнере $CONTAINER_NAME ..."
echo "root:$CONTAINER_PASSWORD" | lxc exec "$CONTAINER_NAME" -- chpasswd

# Добавление шага установки 3X-UI
echo "Установка 3X-UI в $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- bash -c "echo -e 'y\n' | curl -s https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh | bash"

# Создание директории для SSL сертификатов внутри контейнера
echo "Создание директории для SSL сертификатов в $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- mkdir -p /etc/nginx/ssl

# Генерация самоподписанного SSL сертификата для $CONTAINER_NAME
echo "Генерация самоподписанного SSL сертификата для $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- bash -c "openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx-selfsigned.key -out /etc/nginx/ssl/nginx-selfsigned.crt -subj '/C=US/ST=Denial/L=Springfield/O=Dis/CN='"

# Настройка Nginx для использования SSL
echo "Настройка Nginx для использования SSL в $CONTAINER_NAME ..."
NGINX_CONF_PATH="/etc/nginx/sites-available/default"
lxc exec "$CONTAINER_NAME" -- bash -c "echo 'server {
    listen 10443 ssl;
    listen [::]:10443 ssl;

    ssl_certificate /etc/nginx/ssl/nginx-selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:2053;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}' > $NGINX_CONF_PATH"

echo "Перезапуск Nginx в $CONTAINER_NAME ..."
lxc exec "$CONTAINER_NAME" -- systemctl restart nginx

# Проброс порта из хост-машины в контейнер
lxc config device add "$CONTAINER_NAME" web-port10443 proxy listen=tcp:0.0.0.0:10443 connect=tcp:127.0.0.1:10443

# Вывод информации для настройки клиента
echo "Для подключения к VLESS серверу используйте следующие настройки:"
echo "IP-адрес: $USER_IP"
echo "При создании VLESS в панели управления, используйте порт: $EXTERNAL_vpn_PORT"
echo "Доступ в панель управления через https://$USER_IP:10443" # Используйте HTTPS для доступа

echo "Настройка $CONTAINER_NAME завершена."
