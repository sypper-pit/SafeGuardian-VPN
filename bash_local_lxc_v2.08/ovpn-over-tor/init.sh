#!/bin/bash

# Переходим в папку configs
cd configs || exit

# Получаем список файлов .ovpn
ovpn_files=( *.ovpn )

# Переходим обратно в основную папку
cd ..

# Создаем каталоги с номерами и перемещаем файлы
for ((i=0; i<"${#ovpn_files[@]}"; i++)); do
    mkdir -p "$((i+1))"
    mv "configs/${ovpn_files[i]}" "$((i+1))"
done
