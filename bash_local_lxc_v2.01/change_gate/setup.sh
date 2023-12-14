#!/bin/bash

# Копирование change_gate.py в /opt и установка прав на выполнение
sudo cp change_gate.py /opt/
sudo chmod +x /opt/change_gate.py

# Копирование gateway_tool.desktop на рабочий стол пользователя
cp gateway_tool.desktop ~/Desktop/

# Даем права на запуск файла .desktop, если это необходимо
chmod +x ~/Desktop/gateway_tool.desktop

