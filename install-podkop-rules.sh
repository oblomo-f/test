#!/bin/sh

CONFIG_FILE="/etc/config/podkop"

cat > "$CONFIG_FILE" <<'EOF'
config settings 'settings'
        option dns_type 'doh'
        option dns_server '8.8.8.8'
        option bootstrap_dns_server '8.8.4.4'
        option dns_rewrite_ttl '60'
        list source_network_interfaces 'br-lan'
        option enable_output_network_interface '0'
        option enable_badwan_interface_monitoring '0'
        option enable_yacd '0'
        option disable_quic '1'
        option update_interval '1d'
        option download_lists_via_proxy '1'
        option dont_touch_dhcp '1'
        option config_path '/etc/sing-box/config.json'
        option cache_path '/tmp/sing-box/cache.db'
        option log_level 'warn'
        option exclude_ntp '1'
        option shutdown_correctly '0'
        option download_lists_via_proxy_section 'main'

config section 'main'
        option connection_type 'proxy'
        option proxy_config_type 'outbound'
        option enable_udp_over_tcp '0'
        option outbound_json '
{
  "type": "http",
  "tag": "http-proxy",
  "server": "127.0.0.1",
  "server_port": 18080
}
'
        list community_lists 'geoblock'
        list community_lists 'block'
        list community_lists 'meta'
        list community_lists 'twitter'
        list community_lists 'hdrezka'
        list community_lists 'tiktok'
        list community_lists 'google_ai'
        option user_domain_list_type 'text'
        option user_domains_text 'myip.com amazonaws.com whatsapp.com whatsapp.net whatsapp.biz wa.me'
        option user_subnet_list_type 'disabled'
        option mixed_proxy_enabled '0'
EOF

# Проверка конфига
uci show podkop >/dev/null 2>&1 || {
    echo "❌ Ошибка: UCI не смог прочитать podkop"
    exit 1
}

# Перезапуск сервиса
if [ -x /etc/init.d/podkop ]; then
    /etc/init.d/podkop restart
    printf "\033[32;1mPodkop перезапущен\033[0m\n"
else
     printf "\033[32;1mСервис podkop не найден\033[0m\n"
fi

printf "\033[32;1mКонфиг записан в $CONFIG_FILE\033[0m\n"
printf "\n\n"

printf "\033[32;1mУстановка opera-proxy\033[0m\n"
opkg update && opkg install opera-proxy


printf "\033[31;1mAfter 10 second AUTOREBOOT ROUTER...\033[0m\n"
sleep 10
reboot
