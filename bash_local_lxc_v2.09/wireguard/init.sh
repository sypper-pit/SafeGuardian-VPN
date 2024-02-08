#!/bin/bash

# Переходим в папку configs
cd configs || exit

# Получаем список файлов wg
wg_files=( *.conf )

# Переходим обратно в основную папку
cd ..

# Создаем каталоги с номерами и перемещаем файлы
for ((i=0; i<"${#wg_files[@]}"; i++)); do
    mkdir -p "$((i+1))"
    mv "configs/${wg_files[i]}" "$((i+1))"
done
