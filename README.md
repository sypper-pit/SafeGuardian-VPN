# SafeGuardian VPN - An Advanced Whonix Alternative Based on LXC Containers

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
- WireGuard: `wireguard/1/wg.conf`
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

___
# SafeGuardian VPN - Расширенный Аналог Whonix на основе LXC контейнеров

## Запускается на ubuntu
вас необходимо на хосте иметь ubuntu 22.04

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
- WireGuard: `wireguard/1/wg.conf`
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

### Просмотр всех ip (запускается на основном хосте)
`lxc ls`

**Все ip gateway для desktop**: 
    10.0.4.200 - это tor (стоит по умолчанию)
остальные смотрите из списка.
