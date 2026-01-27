#!/bin/sh

set -e

printf "\033[32;1m Обновление списка пакетов и установка зависимостей.\033[0m\n"
opkg update
opkg install ca-certificates wget-ssl
opkg remove wget-nossl || true

printf "\033[32;1m Загрузка и установка публичного ключа репозитория\033[0m\n"
wget -O /tmp/nfqws-keenetic.pub \
  https://anonym-tsk.github.io/nfqws-keenetic/openwrt/nfqws-keenetic.pub
opkg-key add /tmp/nfqws-keenetic.pub

printf "\033[32;1m Добавление репозитория nfqws-keenetic\033[0m\n"
echo "src/gz nfqws-keenetic https://anonym-tsk.github.io/nfqws-keenetic/openwrt" \
  > /etc/opkg/nfqws-keenetic.conf

printf "\033[32;1mУстановка пакета nfqws\033[0m\n"
opkg update
opkg install nfqws-keenetic

printf "\033[32;1m Установка веб-интерфейса\033[0m\n"
opkg install nfqws-keenetic-web

printf "\033[32;1m Готово! nfqws успешно установлен.\033[0m\n"


printf "\033[31;1mAfter 10 second AUTOREBOOT ROUTER...\033[0m\n"
sleep 10
reboot

