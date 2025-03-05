#!/bin/bash

# Переменные
CONTAINER_NAME="minecraft_server"  # Имя контейнера
PORT="25565"  # Порт для Minecraft сервера

# Проверка, запущен ли контейнер Minecraft
if ! docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q "$CONTAINER_NAME"; then
    echo "Ошибка: Контейнер $CONTAINER_NAME не запущен. Пожалуйста, убедитесь, что сервер Minecraft работает."
    exit 1
fi

# Проверка, что Docker установлен
if ! command -v docker &> /dev/null; then
    echo "Ошибка: Docker не установлен. Установите Docker и попробуйте снова."
    exit 1
fi

# Подключение к консоли Minecraft сервера
echo "Подключаемся к консоли Minecraft сервера..."

# Проверка, использует ли сервер screen (если нет, можно использовать команду для директного взаимодействия)
docker exec -it $CONTAINER_NAME /bin/bash -c "screen -ls" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    # Если screen найден, подключаемся через screen
    echo "Запускаем консоль Minecraft через screen..."
    docker exec -it $CONTAINER_NAME screen -r minecraft
else
    # Если screen не используется, просто выводим логи
    echo "Консоль сервера не запущена через screen, выводим логи..."
    docker exec -it $CONTAINER_NAME bash
fi

