#!/bin/bash

# Путь к каталогу с зашифрованными файлами
CRYPT_DIR="/crypt"

# Путь к каталогу для монтирования расшифрованных файлов
MOUNT_DIR="/crypt/tmp"

# Получаем список доступных фаилов в каталоге
FILES=($(find $CRYPT_DIR -maxdepth 1 -type f -exec basename {} \;))

# Функция для проверки, активировано ли LUKS-устройство
is_luks_open() {
    local device=$1
    cryptsetup status $device 2>/dev/null | grep -q "active"
}

# Функция для проверки, смонтирована ли файловая система
is_mounted() {
    local mount_point=$1
    mountpoint -q $mount_point
}

# Исключаем уже подключенные файлы
for device in $(cryptsetup luksDump $CRYPT_DIR/* 2>/dev/null | grep "Cipher name" | awk '{print $3}'); do
    for ((i=0; i<${#FILES[@]}; i++)); do
        if [[ ${FILES[$i]} == $device && ( $(is_luks_open $device) || $(is_mounted $MOUNT_DIR/${FILES[$i]}) ) ]]; then
            unset FILES[$i]
        fi
    done
done

# Исключаем уже подключенные файлы по mount
for mount_point in $(mount | grep "$MOUNT_DIR" | awk '{print $3}'); do
    for ((i=0; i<${#FILES[@]}; i++)); do
        if [[ ${FILES[$i]} == $(basename $mount_point) ]]; then
            unset FILES[$i]
        fi
    done
done

# Отфильтровываем пустые имена файлов
FILES=("${FILES[@]// /}")
FILES=("${FILES[@]/''/}")

# Выводим список доступных фаилов для выбора
echo "Доступные файлы для подключения:"
for ((i=0; i<${#FILES[@]}; i++)); do
    echo "$i: ${FILES[$i]}"
done

# Запрашиваем у пользователя номер файла для подключения
read -p "Выберите номер файла для подключения: " FILE_INDEX

# Проверяем, что введенный номер корректен
if [[ $FILE_INDEX -ge 0 && $FILE_INDEX -lt ${#FILES[@]} ]]; then
    SELECTED_FILE=${FILES[$FILE_INDEX]}

    # Собираем полные пути к исходному файлу и каталогу для монтирования
    SOURCE_PATH="$CRYPT_DIR/$SELECTED_FILE"
    TARGET_PATH="$MOUNT_DIR/$SELECTED_FILE"

    # Запрашиваем пароль для расшифровки LUKS
    read -s -p "Введите пароль для расшифровки LUKS: " LUKS_PASSWORD
    echo

    # Расшифровываем LUKS и монтируем файловую систему
    echo "Расшифровка LUKS и монтирование..."
    echo $LUKS_PASSWORD | cryptsetup luksOpen $SOURCE_PATH $SELECTED_FILE
    mount /dev/mapper/$SELECTED_FILE $TARGET_PATH

    echo "Файл успешно подключен и монтирован в $TARGET_PATH."
else
    echo "Ошибка: Некорректный номер файла."
fi
