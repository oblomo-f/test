#!/bin/sh

# Папка для временных файлов
TMPDIR="/tmp/zapret"
mkdir -p "$TMPDIR"
cd "$TMPDIR" || exit 1
opkg update
opkg install wget

REPO="remittor/zapret-openwrt"
API_URL="https://api.github.com/repos/$REPO/releases/latest"

echo "Проверяем последнюю версию на GitHub..."
LATEST_TAG=$(wget -qO- "$API_URL" | grep '"tag_name":' | head -1 | cut -d '"' -f 4)
if [ -z "$LATEST_TAG" ]; then
    echo "Ошибка: не удалось определить последнюю версию."
    exit 1
fi
echo "Последняя версия: $LATEST_TAG"

# Проверяем установленную версию
INSTALLED_VERSION=$(opkg list-installed | grep luci-app-zapret | awk '{print $2}')
if [ "$INSTALLED_VERSION" = "$LATEST_TAG" ]; then
    echo "Уже установлена последняя версия ($INSTALLED_VERSION). Обновление не требуется."
    exit 0
fi

# Скачиваем архив для aarch64_cortex-a53
LATEST_URL=$(wget -qO- "$API_URL" | grep "browser_download_url" | grep "_aarch64_cortex-a53.zip" | cut -d '"' -f 4)
if [ -z "$LATEST_URL" ]; then
    echo "Ошибка: не удалось найти ссылку на архив."
    exit 1
fi

echo "Скачиваем $LATEST_URL ..."
wget -q --show-progress "$LATEST_URL" -O zapret_latest.zip
if [ $? -ne 0 ]; then
    echo "Ошибка скачивания."
    exit 1
fi

# Распаковываем архив
echo "Распаковываем архив..."
unzip -o zapret_latest.zip

# Устанавливаем ipk пакеты
echo "Устанавливаем ipk пакеты..."
for pkg in luci-app-zapret_*.ipk *_aarch64_cortex-a53.ipk; do
    if [ -f "$pkg" ]; then
        echo "Устанавливаем $pkg ..."
        opkg install --force-overwrite "$pkg"
    fi
done

# Очистка
echo "Чистим временные файлы..."
rm -rf "$TMPDIR"

echo "Обновление до версии $LATEST_TAG завершено."
