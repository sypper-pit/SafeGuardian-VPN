#!/bin/bash

# Получаем информацию о хранилище "default"
storage_info=$(lxc storage show default)

# Извлекаем путь к хранилищу с использованием awk
storage_path=$(echo "$storage_info" | awk '/source/ {print $2}')

# Выводим путь
echo "Путь к хранилищу LXC: $storage_path"

# Переходим в каталог с контейнерами
cd "$storage_path/containers" || exit

# Выводим список контейнеров с их номерами
echo "Содержание хранилища LXC:"
counter=1
for container in *; do
  echo "$counter) $container"
  ((counter++))
done

# Запрашиваем у пользователя ввод номера контейнера
read -p "Введите номер контейнера: " container_number

# Извлекаем имя контейнера по номеру
selected_container=$(ls | sed -n "${container_number}p")

# Выводим путь к выбранному контейнеру
echo "Путь к выбранному контейнеру: $storage_path/containers/$selected_container"

# Запрашиваем у пользователя размер файла в мегабайтах
read -p "Введите размер файла в MB: " file_size_mb

# Создаем каталог /crypt, если его нет
mkdir -p /crypt

# Создаем зашифрованный файл для выбранного контейнера
file_path="/crypt/$selected_container"
dd if=/dev/zero of="$file_path" bs=1M count="$file_size_mb"

# Шифруем файл
cryptsetup luksFormat "$file_path"

# Открываем зашифрованный файл
cryptsetup luksOpen "$file_path" "$selected_container"

# Создаем файловую систему
mkfs.ext4 "/dev/mapper/$selected_container"

echo "Зашифрованный файл для контейнера $selected_container создан и готов к использованию."

# Останавливаем выбранный контейнер
lxc stop $selected_container

# Создаем каталоги
mkdir -p /crypt/tmp/
mkdir -p "/crypt/tmp/$selected_container/"

# Монтируем зашифрованный файл
mount "/dev/mapper/$selected_container" "/crypt/tmp/$selected_container/"

# Создаем каталоги внутри шифрованного блока
mkdir -p "/crypt/tmp/$selected_container/data"

# Создаем новое хранилище для контейнера
new_storage="/crypt/tmp/$selected_container/data"
new_storage_name="${selected_container}-pool"
lxc storage create "$new_storage_name" dir source="$new_storage"

# Дожидаемся полной остановки контейнера
while [ "$(lxc info $selected_container | grep Status | awk '{print $2}')" != "STOPPED" ]; do
  sleep 1
done

# Перемещаем контейнер в новое хранилище
lxc move $selected_container -s "$new_storage_name" && wait
echo "Контейнер $selected_container успешно перемещен в хранилище."

# Запуск контейнера
lxc start $selected_container
echo "Контейнер $selected_container запускается."
