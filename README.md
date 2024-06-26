<img src='logo.png' width='200'>
<a href="https://www.producthunt.com/posts/safeguardian-vpn?utm_source=badge-featured&utm_medium=badge&utm_souce=badge-safeguardian&#0045;vpn" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=430245&theme=light" alt="SafeGuardian&#0045;VPN - Whonix&#0032;Alternative&#0032;Based&#0032;on&#0032;LXC&#0032;Containers | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" /></a> 


[telegram support](https://t.me/SafeGuardian_VPN)

# SafeGuardian VPN - An Advanced Whonix Alternative Based on LXC Containers 

## If you want help me. Send donats:

Dogecoin (DOGE): `D6kb8jcVXYTi82nsoACAYKYhtA5EJ4D9Jg`

Litecoin (LTC): `LfMJCyxxg65sA3X9XEze157D16ztszndqk`

Bitcoin (BTC): `bc1qttzg9yww3nv5dg2d5ja95txmt0mrw9dltfqj57`

Monero (XMR): `8AyWrMwPCxrcbcmVDj3Y5RCfcSQtBBVE2JK9qJ4WqrPpaoa3uNvLReQXPXGj7D5zEsMjBKeWWdyDD4gerqzTtKKS36zSfnM`

Ethereum (ETH): `0xbdfec67586a78e5d3b58dfb70aa181823c8deafa`

TRC-20 USDT: `TTZGfnhurU62VRRGYUHMPJ8q6U8rn5xG5a`

ERC-20 USDT: `0xbdfec67586a78e5d3b58dfb70aa181823c8deafa`


## Run on ubuntu
need ubuntu 22.04

## Overview
SafeGuardian VPN is a powerful tool for creating and managing VPN servers in LXC containers, inspired by the functionality of Whonix. This project offers flexible VPN connection settings with support for WireGuard, OpenVPN (with and without a password), and Tor, ensuring a high level of anonymity and security.

## Features
- **LXC Containers:** Isolated and lightweight containers for improved performance and security.
- **VPN Technology Support:** WireGuard, OpenVPN (with and without a password) and Tor.
- **Killswitch Functionality:** Ensures data security by automatically disconnecting the internet connection in case of VPN failure.

## Installation and Configuration

### 1. Initial Configuration
Run `bash ./lxd_conf.sh` to initialize LXD.

### 2. Preliminary Configuration
Execute `bash ./init.sh` to prepare the necessary settings.

### 3. VPN Configuration
Copy the VPN configuration files into the appropriate folders:
- WireGuard: `wireguard/1/wg-client.conf`
- OpenVPN with password: `openvpn-pass/1/client.ovpn` and `openvpn-pass/1/passwd.txt`
- OpenVPN without password: `openvpn/1/client.ovpn`

**Important:** Ensure that the configurations for each VPN are different to avoid errors.

passwd.txt:
```
<login>
<password>
```

### 4. Launch and Deployment
After copying all the necessary configuration files, run `bash ./setup.sh` to deploy the VPN containers.

## Conclusion
SafeGuardian VPN offers an advanced level of privacy and security, combining the best practices of Whonix and LXC containers. This project is ideal for users looking for a reliable and flexible VPN solution.

### Changing the Default Gateway
Instructions are in the change_gate folder.

### Viewing All IPs (Run on the Main Host)
`lxc ls`

**All IP Gateways for Desktop**: 
    10.0.4.200 - this is for Tor (set by default)
other IPs can be found in the list.

# Changing the IP Gateway
### This application only works for xfce4 (not added by default in desktop)
Copy the change_gate folder with files into your desktop1 container after installing xfce4.
    ****Execute:****
    
    `cd change_gate`
then

    `bash ./setup`


#### Or manually inside the container:
     `ip route del default`
then

     `ip route add default via 10.0.4.100`

___

To enter the container, use:

    `lxc exec desktop1 -- bash`

Then, you can install your applications for Debian 12 in the standard way through the console.

If you need to forward a port, for example, for SSH (install SSH in the container) and execute:
```
lxc config device add desktop1 eth-ssh proxy listen=tcp:0.0.0.0:2222 connect=tcp:127.0.0.1:22
```
### To connect specifically to the container, use port 2222 and the IP of your main host.

If you need to forward a port, for example, for VNC (install VNC in the container) and execute:
```
lxc config device add desktop1 eth-vnc proxy listen=tcp:0.0.0.0:5900 connect=tcp:127.0.0.1:5900
```
Further steps follow the same pattern.

***Attention:*** When port forwarding, be sure to specify unique names `eth-<name>` 

___

___
# SafeGuardian VPN - Расширенный Аналог Whonix на основе LXC контейнеров

## Запускается на ubuntu
Вам необходимо на хосте иметь ubuntu 22.04

## Обзор
SafeGuardian VPN – это мощный инструмент для создания и управления VPN-серверами в LXC контейнерах, вдохновленный функциональностью Whonix. Проект предоставляет гибкость настройки VPN-подключений с поддержкой WireGuard, OpenVPN (с паролем и без), и Tor, обеспечивая высокий уровень анонимности и безопасности.

## Особенности
- **LXC Контейнеры:** Изолированные и легковесные контейнеры для улучшенной производительности и безопасности.
- **Поддержка VPN Технологий:** WireGuard, OpenVPN (с паролем и без) и Tor.
- **Killswitch Функционал:** Гарантирует безопасность данных, автоматически отключая интернет-соединение в случае сбоя VPN.

## Установка и Настройка

### 1. Начальная Конфигурация
Запустите `bash ./lxd_conf.sh` для инициализации LXD.

### 2. Предварительная Конфигурация
Выполните `bash ./init.sh` для подготовки необходимых настроек.

### 3. Конфигурация VPN
Скопируйте конфигурационные файлы VPN в соответствующие папки:
- WireGuard: `wireguard/1/wg-client.conf`
- OpenVPN с паролем: `openvpn-pass/1/client.ovpn` и `openvpn-pass/1/passwd.txt`
- OpenVPN без пароля: `openvpn/1/client.ovpn`

**Важно:** Убедитесь, что конфигурации для каждого VPN отличаются, чтобы избежать ошибок.

passwd.txt:
```
<login>
<password>
```

### 4. Запуск и Развертывание
После копирования всех необходимых файлов конфигурации, запустите `bash ./setup.sh` для развертывания контейнеров VPN.

## Заключение
SafeGuardian VPN предлагает продвинутый уровень конфиденциальности и безопасности, объединяя лучшие практики Whonix и LXC контейнеров. Этот проект идеален для пользователей, которые ищут надежное и гибкое VPN-решение.

### Смена default gateway
Инструкция в папке change_gate


# Смена ip gateway
### Приложение работает только для xfce4 (в desktop по умолчанию не добавлено)
Скопируйте папку с фаилами change_gate в ваш контейнер desktop1 предварительно установив xfce4
    ****выполните:****
    
    `cd change_gate`
затем

    `bash ./setup`


#### или в ручную внутри контейнера:
     `ip route del default`
затем

     `ip route add default via 10.0.4.100`

___

Чтоб зайти в контейнер используйте:

    `lxc exec desktop1 -- bash`

Далее уже можно ставить стандартным способом через консоль ваши приложения как для debian 12

Если вам нудно пробросить порт на пример для ssh (установите ssh в контейнере) и выполните:

    `lxc config device add desktop1 eth-ssh proxy listen=tcp:0.0.0.0:2222 connect=tcp:127.0.0.1:22`
### для подключения именно к контейнеру используйте порт 2222 ip вашего основного хоста

Если вам нудно пробросить порт на пример для VNC (установите vnc в контейнере) и выполните:

    `lxc config device add desktop1 eth-vnc proxy listen=tcp:0.0.0.0:5900 connect=tcp:127.0.0.1:5900`

Дальше всё по аналогии.

***Внимание:*** при перебросе портов обязательно указывайте уникальные имена `eth-<name>` 

### Просмотр всех ip (запускается на основном хосте)
`lxc ls`

**Все ip gateway для desktop**: 
    10.0.4.200 - это tor (стоит по умолчанию)
остальные смотрите из списка.
