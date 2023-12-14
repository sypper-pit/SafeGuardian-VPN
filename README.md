# SafeGuardian VPN - Расширенный Аналог Whonix с LXC Контейнерами

## Обзор
SafeGuardian VPN – это мощный инструмент для создания и управления VPN-серверами в LXC контейнерах, вдохновленный функциональностью Whonix. Проект предоставляет гибкость настройки VPN-подключений с поддержкой WireGuard, OpenVPN (с паролем и без), и Tor, обеспечивая высокий уровень анонимности и безопасности.

## Особенности
- **LXC Контейнеры:** Изолированные и легковесные контейнеры для улучшенной производительности и безопасности.
- **Поддержка VPN Технологий:** WireGuard, OpenVPN (с паролем и без) и Tor.
- **Killswitch Функционал:** Гарантирует безопасность данных, автоматически отключая интернет-соединение в случае сбоя VPN.

## Установка и Настройка

### 1. Начальная Конфигурация
Запустите `lxd_conf.sh` для инициализации LXD.

### 2. Предварительная Конфигурация
Выполните `bash ./init.sh` для подготовки необходимых настроек.

### 3. Конфигурация VPN
Скопируйте конфигурационные файлы VPN в соответствующие папки:
- WireGuard: `wireguard/1/wg.conf`
- OpenVPN с паролем: `openvpn-pass/1/client.ovpn` и `openvpn-pass/1/passwd.txt`
- OpenVPN без пароля: `openvpn/1/client.ovpn`

**Важно:** Убедитесь, что конфигурации для каждого VPN отличаются, чтобы избежать ошибок.

### 4. Запуск и Развертывание
После копирования всех необходимых файлов конфигурации, запустите `bash ./setup.sh` для развертывания контейнеров VPN.

## Заключение
SafeGuardian VPN предлагает продвинутый уровень конфиденциальности и безопасности, объединяя лучшие практики Whonix и LXC контейнеров. Этот проект идеален для пользователей, которые ищут надежное и гибкое VPN-решение.
