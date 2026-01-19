#!/bin/sh

# ===== Защита =====
set -e

# ===== Проверка OpenWrt =====
if [ ! -f /etc/openwrt_release ]; then
    echo "Ошибка: это не OpenWrt"
    exit 1
fi

echo "=== Установка начата ==="

# ===== Обновление opkg =====
echo "Обновление списка пакетов..."
if ! opkg update; then
    echo "Ошибка: opkg update"
    exit 1
fi

# ===== Установка русского языка LuCI =====
echo "Установка luci-i18n-base-ru..."
if ! opkg install luci-i18n-base-ru; then
    echo "Ошибка установки luci-i18n-base-ru"
    exit 1
fi

# ===== Установка темы routerich =====
THEME_URL="https://raw.githubusercontent.com/routerich/packages.routerich/24.10.4/routerich/luci-theme-routerich_1.0.9.10-r20251204_all.ipk"
THEME_IPK="/tmp/luci-theme-routerich.ipk"

echo "Скачивание темы routerich..."
if ! wget -O "$THEME_IPK" "$THEME_URL"; then
    echo "Ошибка скачивания темы"
    exit 1
fi

echo "Установка темы routerich..."
if ! opkg install "$THEME_IPK"; then
    echo "Ошибка установки темы"
    exit 1
fi

# ===== Очистка =====
rm -f "$THEME_IPK"

echo "=== Установка завершена успешно ==="

