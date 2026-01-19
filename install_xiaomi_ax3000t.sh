#!/bin/sh

echo "=== Проверка модели ==="
MODEL="$(cat /tmp/sysinfo/model 2>/dev/null)"
echo "$MODEL" | grep -qi "AX3000T" || { echo "Не Xiaomi AX3000T"; exit 1; }
echo "Устройство: $MODEL"

echo "=== Обновление opkg ==="
opkg update || exit 1

echo "=== Установка русского языка LuCI ==="
opkg install luci-i18n-base-ru || exit 1

echo "=== Установка темы routerich ==="
THEME_URL="https://raw.githubusercontent.com/routerich/packages.routerich/24.10.4/routerich/luci-theme-routerich_1.0.9.10-r20251204_all.ipk"
IPK="/tmp/routerich.ipk"
wget -O "$IPK" "$THEME_URL" || exit 1
opkg install "$IPK" || exit 1
rm -f "$IPK"

echo "=== Переключение LuCI на русский ==="
uci set luci.main.lang='ru'
uci commit luci

echo "=== Активация темы routerich ==="
uci set luci.main.mediaurlbase='/luci-static/routerich'
uci commit luci

echo "=== Перезапуск uhttpd ==="
/etc/init.d/uhttpd restart

echo "=== ГОТОВО ==="

