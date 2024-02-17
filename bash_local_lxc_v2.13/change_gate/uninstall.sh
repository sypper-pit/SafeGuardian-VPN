#!/bin/bash

# Функция для запроса подтверждения и удаления файла
delete_file() {
    local file=$1
    read -p "Вы хотите удалить файл $file? (Y/n) " choice
    case "$choice" in
        [Yy]|[Yy][Ee][Ss])
            if [ -f "$file" ]; then
                rm "$file"
                echo "Файл $file удалён."
            else
                echo "Файл $file не найден."
            fi
            ;;
        [Nn]|[Nn][Oo])
            echo "Удаление файла $file отменено."
            ;;
        *)
            echo "Неверный выбор. Удаление файла $file отменено."
            ;;
    esac
}

# Пути к файлам
file1="/opt/change_gate.py"
file2="$HOME/Desktop/gateway_tool.desktop"

# Запрос подтверждения и удаление для каждого файла
delete_file "$file1"
delete_file "$file2"

