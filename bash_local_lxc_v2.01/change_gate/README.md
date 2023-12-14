# Смена ip gateway
### Приложение работает только для xfce4 (в desktop по умолчанию не добавлено)

Чтоб зайти в контейнер используйте:

    `lxc exec desktop1 -- bash`

Далее уже можно ставить стандартным способом через консоль ваши приложения как для debian 12

Если вам нудно пробросить порт на пример для ssh (установите ssh в контейнере) и выполните:

    `lxc config device add desktop1 eth-ssh proxy listen=tcp:0.0.0.0:2222 connect=tcp:127.0.0.1:22`
### для подключения именно к контейнеру используйте порт 2222 ip вашего основного хоста

Если вам нудно пробросить порт на пример для VNC (установите vnc в контейнере) и выполните:

    `lxc config device add desktop1 eth-vnc proxy listen=tcp:0.0.0.0:5900 connect=tcp:127.0.0.1:5900`

Дальше всё по аналогии.

### Внимание: при прокидовании портов обязательно указывайте уникальные имена `eth-<name>` 