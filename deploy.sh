#!/bin/bash

# Функция для установки Docker
install_docker() {
    echo "Docker не найден! Устанавливаем Docker..."

    # Для Ubuntu/Debian
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update
        sudo apt install -y docker-ce
    fi

    # Для CentOS/RHEL
    if [ -f /etc/redhat-release ]; then
        sudo yum install -y yum-utils
        sudo yum install -y docker-ce
    fi

    # Для Fedora
    if [ -f /etc/fedora-release ]; then
        sudo dnf install -y docker-ce
    fi

    # Запуск и настройка Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Добавление пользователя в группу docker для работы без sudo
    sudo usermod -aG docker $USER
    echo "Docker установлен и запущен."

    echo "Для применения изменений вам нужно выйти из системы и войти снова."
    echo "Или используйте команду: newgrp docker для применения изменений без выхода."
}

# Проверка, установлен ли Docker
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "Docker уже установлен."
fi

# Переменные
IMAGE="itzg/minecraft-server"  # Docker-образ для Minecraft Paper сервера
CONTAINER_NAME="minecraft_server"  # Имя контейнера
PORT="25565"  # Порт для Minecraft сервера
MEMORY="2G"  # Количество памяти для сервера
EULA="TRUE"  # Принятие EULA
BRIDGE_MODE="true"  # Флаг для мостовой сети

# Установка Paper как ядра Minecraft
echo "Загружаем и настраиваем Minecraft сервер с ядром Paper..."

# Запуск Docker контейнера с сервером Minecraft (Paper)
if [ "$BRIDGE_MODE" == "true" ]; then
    # Мостовая сеть (bridged)
    docker run -d \
      --name $CONTAINER_NAME \
      -p $PORT:25565 \
      -e EULA=$EULA \
      -e MEMORY=$MEMORY \
      --restart unless-stopped \
      --network bridge \
      itzg/minecraft-server:latest
else
    # NAT сеть
    docker run -d \
      --name $CONTAINER_NAME \
      -p $PORT:25565 \
      -e EULA=$EULA \
      -e MEMORY=$MEMORY \
      --restart unless-stopped \
      itzg/minecraft-server:latest
fi

# Проверка состояния контейнера
if [ $? -eq 0 ]; then
    echo "Minecraft сервер с ядром Paper успешно установлен и запущен!"
    echo "Подключитесь к серверу через: <IP виртуальной машины или хоста>:$PORT"
else
    echo "Произошла ошибка при запуске сервера."
    exit 1
fi

# Проверка, что порт открыт в фаерволе
echo "Проверка фаервола..."
sudo ufw allow 25565/tcp
echo "Порт 25565 открыт для входящих подключений."

# Подключение к консоли сервера через Docker
echo "Чтобы подключиться к консоли сервера, используйте команду:"
echo "docker exec -it minecraft_server /bin/bash"
echo "Для получения логов сервера используйте команду:"
echo "docker logs -f minecraft_server"
