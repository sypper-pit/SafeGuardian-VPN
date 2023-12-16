1) First, you need to run:
lxd_conf.sh

2) Start the preliminary configuration: 
bash ./init.sh

3) Copy the necessary configuration files into the folders, for example:
wireguard/1/wg.conf
openvpn-pass/1/client.ovpn
openvpn-pass/1/passwd.txt
openvpn/1/client.ovpn

4) Once everything is copied (pay close attention here, the configurations must be different to avoid errors), run: 
bash ./setup.sh

***Switching***
The process is described in the change_gate folder.

___

1) В начале нужно запустить:
lxd_conf.sh

2) запускаем предварительную конфигурацию: 
bash ./init.sh

3) Копируем нужные конфиги в папки для примера в:
wireguard/1/wg.conf
openvpn-pass/1/client.ovpn
openvpn-pass/1/passwd.txt
openvpn/1/client.ovpn

4) Как только всё скопировали(тут очень внимательно конфигурации должны отличатся, чтоб не получить ошибок) запускаем: 
bash ./setup.sh

***Переключение***
Процесс описан в папке change_gate
