#!/bin/bash

# Обновляем список пакетов
sudo apt update

# Обновляем установленные пакеты
sudo apt upgrade -y

# Устанавливаем пакет cryptsetup
sudo apt-get install -y cryptsetup

