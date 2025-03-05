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

# Проверка прав на сокет Docker
check_docker_socket() {
    # Проверка, есть ли доступ к сокету Docker
    if ! docker ps &> /dev/null; then
        echo "Ошибка: Нет доступа к Docker сокету /var/run/docker.sock."

        # Предложим добавить пользователя в группу docker
        echo "Попробуем добавить пользователя в группу docker..."
        sudo usermod -aG docker $USER

        # Перезапуск Docker и применение изменений
        sudo systemctl restart docker

        # Выполнение newgrp для применения изменений без выхода из системы
        echo "Автоматически применяем новые группы..."
        newgrp docker

        # Уведомление, что нужно перезайти или обновить группу
        echo "Пожалуйста, выйдите из системы и войдите снова, если newgrp не помогло."
        exit 1
    else
        echo "Доступ к Docker сокету успешно настроен."
    fi
}

# Проверка прав на сокет
check_docker_socket

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

# Установка screen внутри контейнера
echo "Проверяем, установлен ли screen в контейнере..."

docker exec $CONTAINER_NAME apt-get update -y
docker exec $CONTAINER_NAME apt-get install -y screen

# Проверка, запущен ли сервер через screen
echo "Проверяем, запущен ли Minecraft сервер через screen..."

# Проверка наличия screen в контейнере
docker exec $CONTAINER_NAME screen -ls > /dev/null 2>&1

if [ $? -eq 0 ]; then
    # Если screen запущен, выводим сообщение
    echo "Minecraft сервер работает через screen."
else
    # Если screen не найден, запускаем сервер через screen
    echo "Запускаем Minecraft сервер через screen..."

    docker exec -it $CONTAINER_NAME bash -c "screen -S minecraft_server -dm java -Xmx$MEMORY -Xms$MEMORY -jar /minecraft_server.jar nogui"

    if [ $? -eq 0 ]; then
        echo "Minecraft сервер успешно запущен через screen!"
    else
        echo "Произошла ошибка при запуске Minecraft сервера через screen."
        exit 1
    fi
fi

# Подключение к консоли сервера через Docker и Screen
echo "Чтобы подключиться к консоли сервера через screen, используйте команду:"
echo "docker exec -it minecraft_server screen -r minecraft_server"

# Для получения логов сервера используйте команду:
echo "Для получения логов сервера используйте команду:"
echo "docker logs -f minecraft_server"
