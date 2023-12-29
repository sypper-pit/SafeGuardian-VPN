import subprocess
import re
import urllib.request
import getpass

def is_valid_ip(ip):
    pattern = r'^\d{1,3}(\.\d{1,3}){3}$'
    return re.match(pattern, ip) is not None

def apply_ip(new_ip, root_password):
    if not is_valid_ip(new_ip):
        return "Неверный IP-адрес", False

    # Обновленные команды для изменения настроек сети
    commands = [
        f"echo {root_password} | sudo -S ip route del default",
        f"echo {root_password} | sudo -S ip route add default via {new_ip}"
    ]

    for cmd in commands:
        subprocess.run(cmd, shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)

    # Обновленная проверка изменений
    try:
        check_cmd = "ip route | grep '^default'"
        result = subprocess.check_output(check_cmd, shell=True).decode()
        if new_ip in result:
            return "IP-адрес добавлен в default gateway", True
        else:
            return "Ошибка добавления IP-адреса", False
    except subprocess.CalledProcessError:
        return "Ошибка выполнения команды проверки", False

def get_external_ip():
    try:
        with urllib.request.urlopen("https://api.ipify.org") as response:
            return response.read().decode('utf-8')
    except Exception as e:
        return f"Ошибка получения внешнего IP: {e}"

def main():
    while True:
        new_ip = input("Введите IP-адрес gateway: ")
        root_password = getpass.getpass("Введите ваш пароль: ")

        result, success = apply_ip(new_ip, root_password)
        print(result)
        if success:
            break
        else:
            print("Пожалуйста, попробуйте снова.")

    external_ip = get_external_ip()
    print(f"Внешний IP: {external_ip}")

    input("Нажмите любую клавишу для выхода...")

if __name__ == "__main__":
    main()
