#!/bin/bash
# Перебираем каталоги
for dir in */ ; do
    echo "Обработка каталога: $dir"

    # Пропускаем каталог change_gate и crypt
    if [ "$dir" == "change_gate/" ] || [ "$dir" == "crypt/" ]; then
        continue
    fi

    # Проверяем наличие папки configs и файлов .ovpn или .conf в ней
    if [ -d "${dir}configs/" ]; then
        config_files=($(ls ${dir}configs/*.ovpn ${dir}configs/*.conf 2> /dev/null))

        if [ ${#config_files[@]} -gt 0 ]; then
            # Запускаем init.sh, если он существует
            if [ -f "${dir}init.sh" ]; then
                cd ${dir}
                bash ./init.sh
                cd ..
            fi
        else
            echo "В каталоге ${dir}configs/ нет файлов .ovpn или .conf"
            # Запрашиваем количество копий
            echo -n "Сколько копий ${dir%/} хотите? "
            read copies

            # Создаем копии, если введено число больше 0
            if [[ "$copies" =~ ^[0-9]+$ ]] && [ "$copies" -gt 0 ]; then
                for ((i=1; i<=copies; i++)); do
                    mkdir -p "${dir}${i}"
                done
            fi
        fi
    else
        # Папки configs нет, запрашиваем количество копий
        echo -n "Сколько копий ${dir%/} хотите? "
        read copies

        # Создаем копии, если введено число больше 0
        if [[ "$copies" =~ ^[0-9]+$ ]] && [ "$copies" -gt 0 ]; then
            for ((i=1; i<=copies; i++)); do
                mkdir -p "${dir}${i}"
            done
        fi
    fi
done
