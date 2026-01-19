#!/bin/sh

echo "=== Проверка OpenWrt ==="
if [ ! -f /etc/openwrt_release ]; then
    echo "Ошибка: это не OpenWrt"
    exit 1
fi

echo "=== Проверка устройства ==="
MODEL="$(cat /tmp/sysinfo/model 2>/dev/null)"

case "$MODEL" in
    *AX3000T*)
        echo "Устройство: $MODEL"
        ;;
    *)
        echo "Ошибка: это не Xiaomi AX3000T"
        echo "Определено: $MODEL"
        exit 1
        ;;
esac

echo "=== Обновление opkg ==="
opkg update || exit 1

echo "=== Установка русского языка LuCI ==="
opkg install luci-i18n-base-ru || exit 1

echo "=== Установка темы routerich ==="
THEME_URL="https://raw.githubusercontent.com/routerich/packages.routerich/24.10.4/routerich/luci-theme-routerich_1.0.9.10-r20251204_all.ipk"
THEME_IPK="/tmp/luci-theme-routerich.ipk"

wget -O "$THEME_IPK" "$THEME_URL" || exit 1
opkg install "$THEME_IPK" || exit 1
rm -f "$THEME_IPK"

echo "=== Переключение LuCI на русский ==="
uci set luci.main.lang='ru'
uci commit luci

echo "=== Активация темы routerich ==="
uci set luci.main.mediaurlbase='/luci-static/routerich'
uci commit luci

echo "=== Перезапуск uhttpd ==="
/etc/init.d/uhttpd restart

echo "=== ГОТОВО ==="
