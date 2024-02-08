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

    `lxc config device add desktop1 eth-ssh proxy listen=tcp:0.0.0.0:2222 connect=tcp:127.0.0.1:22`
### To connect specifically to the container, use port 2222 and the IP of your main host.

If you need to forward a port, for example, for VNC (install VNC in the container) and execute:

    `lxc config device add desktop1 eth-vnc proxy listen=tcp:0.0.0.0:5900 connect=tcp:127.0.0.1:5900`

Further steps follow the same pattern.

***Attention:*** When port forwarding, be sure to specify unique names `eth-<name>` 

___

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
