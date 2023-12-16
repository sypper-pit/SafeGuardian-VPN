#!/bin/bash

# Функция для выполнения setup.sh в каталогах
execute_setup() {
    local base_dir=$1
    local base_ip=$2
    local counter=0

    # Переходим в основной каталог сервиса
    cd "${base_dir}" || exit

    # Перебор подкаталогов
    for dir in */ ; do
        if [ -d "${dir}" ]; then
            ((counter++))
            ip=$(echo "${base_ip}" | awk -F '.' '{printf "%s.%s.%s.%d", $1, $2, $3, $4+'${counter}'-1}')
            bash "./setup.sh" "${ip}" "${counter}"
        fi
    done

    # Возвращаемся обратно в исходный каталог
    cd - > /dev/null
}

# Выполнение для каталогов с setup.sh
execute_setup "wireguard" "10.0.4.50"
execute_setup "openvpn-pass" "10.0.4.100"
execute_setup "openvpn" "10.0.4.150"

# Функция для запуска скриптов в главном каталоге
execute_script() {
    local script=$1
    local base_ip=$2
    local copies

    echo -n "How many ${script} you want start? (if send 0 - not run): "
    read copies

    if [[ "$copies" =~ ^[0-9]+$ ]] && [ "$copies" -gt 0 ]; then
        for ((i=1; i<=copies; i++)); do
            ip=$(echo "${base_ip}" | awk -F '.' '{printf "%s.%s.%s.%d", $1, $2, $3, $4+'${i}'-1}')
            bash "${script}" "${ip}" "${i}"
        done
    fi
}

# Выполнение для скриптов в главном каталоге
execute_script "tor-gate.sh" "10.0.4.200"
execute_script "desktop.sh" "10.0.4.2"
