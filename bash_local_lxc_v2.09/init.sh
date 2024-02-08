#!/bin/bash

# Перебираем каталоги
for dir in */ ; do
    # Пропускаем каталог change_gate и crypt
    if [ "$dir" == "change_gate/" ] || [ "$dir" == "crypt/" ]; then
        continue
    fi

    # Проверяем наличие папки configs
    if [ -d "${dir}configs/" ]; then
        # Получаем список файлов в папке configs
        config_files=(${dir}configs/*)

        # Проверяем, что в папке configs есть файлы
        if [ ${#config_files[@]} -gt 0 ]; then
            # Запускаем init.sh
            cd ${dir}
            bash ./init.sh
            cd ..
            continue
        fi
    fi

    # Спрашиваем, сколько копий нужно
    echo -n "Сколько копий ${dir%/} хотите? "
    read copies

    # Проверяем, что введено число и оно больше 0
    if [[ "$copies" =~ ^[0-9]+$ ]] && [ "$copies" -gt 0 ]; then
        # Создаем указанное количество копий
        for ((i=1; i<=copies; i++)); do
            mkdir -p "${dir}${i}"
        done
    fi
done
