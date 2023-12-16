import subprocess
import re
import urllib.request
import getpass

def is_valid_ip(ip):
    pattern = r'^\d{1,3}(\.\d{1,3}){3}$'
    return re.match(pattern, ip) is not None

def apply_ip(new_ip, root_password):
    if not is_valid_ip(new_ip):
        return "Wrong IP-address", False

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
            return "IP-address add as default gateway", True
        else:
            return "Error! create IP-address", False
    except subprocess.CalledProcessError:
        return "Error: execute the check command", False

def get_external_ip():
    try:
        with urllib.request.urlopen("https://api.ipify.org") as response:
            return response.read().decode('utf-8')
    except Exception as e:
        return f"Error getting external IP: {e}"

def main():
    while True:
        new_ip = input("Enter IP-address you gateway: ")
        root_password = getpass.getpass("Enter you password(need for sudo, not root): ")

        result, success = apply_ip(new_ip, root_password)
        print(result)
        if success:
            break
        else:
            print("Please try again!")

    external_ip = get_external_ip()
    print(f"You external IP: {external_ip}")

    input("Press |Enter| for END...")

if __name__ == "__main__":
    main()
