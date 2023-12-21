#!/bin/bash

# Перебираем каталоги
for dir in */ ; do
    # Пропускаем каталог change_gate
    if [ "$dir" == "change_gate/" ]; then
        continue
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
