1) В начале нужно запустить:
lxd_conf.sh

2) запускаем предварительную конфигурацию: 
bash ./init.sh

Копируем нужные конфиги в папки для примера в:
wireguard/1/wg.conf
openvpn-pass/1/client.ovpn
openvpn-pass/1/passwd.txt
openvpn/1/client.ovpn

Как только всё скопировали(тут очень внимательно конфигурации должны отличатся, чтоб не получить ошибок) запускаем: 
bash ./setup.sh
