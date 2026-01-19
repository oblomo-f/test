#!/bin/sh
set -e

echo "Обновление списка пакетов..."
if ! opkg update; then
    echo "Ошибка opkg update"
    exit 1
fi

echo "Установка luci-i18n-base-ru..."
if ! opkg install luci-i18n-base-ru; then
    echo "Ошибка установки luci-i18n-base-ru"
    exit 1
fi

echo "Установка темы routerich..."
URL="https://raw.githubusercontent.com/routerich/packages.routerich/24.10.4/routerich/luci-theme-routerich_1.0.9.10-r20251204_all.ipk"

wget -O /tmp/routerich.ipk "$URL"
opkg install /tmp/routerich.ipk

echo "Готово"
