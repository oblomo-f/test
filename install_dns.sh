#!/bin/sh

install_awg_packages() {
    # Получение pkgarch с наибольшим приоритетом
    PKGARCH=$(opkg print-architecture | awk 'BEGIN {max=0} {if ($3 > max) {max = $3; arch = $2}} END {print arch}')

    TARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f 1)
    SUBTARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f 2)
    VERSION=$(ubus call system board | jsonfilter -e '@.release.version')
    PKGPOSTFIX="_v${VERSION}_${PKGARCH}_${TARGET}_${SUBTARGET}.ipk"
    BASE_URL="https://github.com/Slava-Shchipunov/awg-openwrt/releases/download/"

}

manage_package() {
    local name="$1"
    local autostart="$2"
    local process="$3"

    # Проверка, установлен ли пакет
    if opkg list-installed | grep -q "^$name"; then
        
        # Проверка, включен ли автозапуск
        if /etc/init.d/$name enabled; then
            if [ "$autostart" = "disable" ]; then
                /etc/init.d/$name disable
            fi
        else
            if [ "$autostart" = "enable" ]; then
                /etc/init.d/$name enable
            fi
        fi

        # Проверка, запущен ли процесс
        if pidof $name > /dev/null; then
            if [ "$process" = "stop" ]; then
                /etc/init.d/$name stop
            fi
        else
            if [ "$process" = "start" ]; then
                /etc/init.d/$name start
            fi
        fi
    fi
}

checkPackageAndInstall() {
    local name="$1"
    local isRequired="$2"
    local alt=""

    if [ "$name" = "https-dns-proxy" ]; then
        alt="luci-app-doh-proxy"
    fi

    if [ -n "$alt" ]; then
        if opkg list-installed | grep -qE "^($name|$alt) "; then
            echo "$name or $alt already installed..."
            return 0
        fi
    else
        if opkg list-installed | grep -q "^$name "; then
            echo "$name already installed..."
            return 0
        fi
    fi

    echo "$name not installed. Installing $name..."
    opkg install "$name"
    res=$?

    if [ "$isRequired" = "1" ]; then
        if [ $res -eq 0 ]; then
            echo "$name installed successfully"
        else
            echo "Error installing $name. Please, install $name manually$( [ -n "$alt" ] && echo " or $alt") and run the script again."
            exit 1
        fi
    fi
}


checkAndAddDomainPermanentName()
{
  nameRule="option name '$1'"
  str=$(grep -i "$nameRule" /etc/config/dhcp)
  if [ -z "$str" ] 
  then 

    uci add dhcp domain
    uci set dhcp.@domain[-1].name="$1"
    uci set dhcp.@domain[-1].ip="$2"
    uci commit dhcp
  fi
}

byPassGeoBlockComssDNS()
{
	echo "Configure dhcp..."

	uci set dhcp.cfg01411c.strictorder='1'
	uci set dhcp.cfg01411c.filter_aaaa='1'
	uci add_list dhcp.cfg01411c.server='127.0.0.1#5053'
	uci add_list dhcp.cfg01411c.server='127.0.0.1#5054'
	uci add_list dhcp.cfg01411c.server='127.0.0.1#5055'
	uci add_list dhcp.cfg01411c.server='127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.chatgpt.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.oaistatic.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.oaiusercontent.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.openai.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.microsoft.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.windowsupdate.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.bing.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.supercell.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.seeurlpcl.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.supercellid.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.supercellgames.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.clashroyale.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.brawlstars.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.clash.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.clashofclans.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.x.ai/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.grok.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.github.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.forzamotorsport.net/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.forzaracingchampionship.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.forzarc.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.gamepass.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.orithegame.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.renovacionxboxlive.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.tellmewhygame.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xbox.co/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xbox.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xbox.eu/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xbox.org/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xbox360.co/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xbox360.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xbox360.eu/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xbox360.org/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxab.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxgamepass.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxgamestudios.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxlive.cn/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxlive.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxone.co/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxone.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxone.eu/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxplayanywhere.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxservices.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xboxstudios.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.xbx.lv/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.sentry.io/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.usercentrics.eu/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.recaptcha.net/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.gstatic.com/127.0.0.1#5056'
	uci add_list dhcp.cfg01411c.server='/*.brawlstarsgame.com/127.0.0.1#5056'
	uci commit dhcp

	echo "Add unblock ChatGPT..."

	checkAndAddDomainPermanentName "chatgpt.com" "83.220.169.155"
	checkAndAddDomainPermanentName "openai.com" "83.220.169.155"
	checkAndAddDomainPermanentName "webrtc.chatgpt.com" "83.220.169.155"
	checkAndAddDomainPermanentName "ios.chat.openai.com" "83.220.169.155"
	checkAndAddDomainPermanentName "searchgpt.com" "83.220.169.155"

	service dnsmasq restart
	service odhcpd restart
}

deleteByPassGeoBlockComssDNS()
{
	uci del dhcp.cfg01411c.server
	uci add_list dhcp.cfg01411c.server='127.0.0.1#5359'
	while uci del dhcp.@domain[-1] ; do : ;  done;
	uci commit dhcp
	service dnsmasq restart
	service odhcpd restart
	service doh-proxy restart
}



#####after test delete 
DESCRIPTION=$(ubus call system board | jsonfilter -e '@.release.description')
VERSION=$(ubus call system board | jsonfilter -e '@.release.version')
findKey="OpenWrt"
findVersion="24.10.2"

if echo "$DESCRIPTION" | grep -qi -- "$findKey" && printf '%s\n%s\n' "$findVersion" "$VERSION" | sort -V | tail -n1 | grep -qx -- "$VERSION"; then
	printf "\033[32;1mThis new firmware. Running scprit...\033[0m\n"
else
	printf "\033[32;1mThis old firmware.\nTo use this script, update your firmware to the latest version....\033[0m\n"
	exit 1
fi
####after test delete 


echo "Update list packages..."
opkg update

checkPackageAndInstall "coreutils-base64" "1"

encoded_code="IyEvYmluL3NoCgojINCn0YLQtdC90LjQtSDQvNC+0LTQtdC70Lgg0LjQtyDRhNCw0LnQu9CwCm1vZGVsPSQoY2F0IC90bXAvc3lzaW5mby9tb2RlbCkKCiMg0J/RgNC+0LLQtdGA0LrQsCwg0YHQvtC00LXRgNC20LjRgiDQu9C4INC80L7QtNC10LvRjCDRgdC70L7QstC+ICJSb3V0ZXJpY2giCmlmICEgZWNobyAiJG1vZGVsIiB8IGdyZXAgLXEgIlhpYW9taSI7IHRoZW4KICAgIGVjaG8gIlRoaXMgc2NyaXB0IGZvciByb3V0ZXJzIFhpYW9taS4uLiIKICAgIGV4aXQgMQpmaQ=="
eval "$(echo "$encoded_code" | base64 --decode)"

#проверка и установка пакетов AmneziaWG
#install_awg_packages

checkPackageAndInstall "jq" "1"
checkPackageAndInstall "curl" "1"
checkPackageAndInstall "unzip" "1"


#проверяем установлени ли пакет dnsmasq-full
if opkg list-installed | grep -q dnsmasq-full; then
	echo "dnsmasq-full already installed..."
else
	echo "Installed dnsmasq-full..."
	cd /tmp/ && opkg download dnsmasq-full
	opkg remove dnsmasq && opkg install dnsmasq-full --cache /tmp/

	[ -f /etc/config/dhcp-opkg ] && cp /etc/config/dhcp /etc/config/dhcp-old && mv /etc/config/dhcp-opkg /etc/config/dhcp
fi

#проверяем установлени ли пакет https-dns-proxy
if opkg list-installed | grep -q https-dns-proxy; then
	echo "Delete packet https-dns-proxy..."
	opkg remove --force-removal-of-dependent-packages "https-dns-proxy"
fi

printf "Setting confdir dnsmasq\n"
uci set dhcp.@dnsmasq[0].confdir='/tmp/dnsmasq.d'
uci commit dhcp

DIR="/etc/config"
DIR_BACKUP="/root/backup5"
config_files="network
firewall
doh-proxy
dhcp
dns-failsafe-proxy
stubby"
URL="https://raw.githubusercontent.com/routerich/RouterichAX3000_configs/refs/heads/podkop07"

checkPackageAndInstall "luci-app-dns-failsafe-proxy" "1"
checkPackageAndInstall "luci-i18n-stubby-ru" "1"
checkPackageAndInstall "luci-i18n-doh-proxy-ru" "1"

if [ ! -d "$DIR_BACKUP" ]
then
    echo "Backup files..."
    mkdir -p $DIR_BACKUP
    for file in $config_files
    do
        cp -f "$DIR/$file" "$DIR_BACKUP/$file"  
    done
	echo "Replace configs..."

	for file in $config_files
	do
		if [ "$file" == "doh-proxy" ] || [ "$file" == "dns-failsafe-proxy" ] || [ "$file" == "stubby" ]
		then 
		  wget -O "$DIR/$file" "$URL/config_files/$file" 
		fi
	done
fi

echo "Configure dhcp..."

uci set dhcp.cfg01411c.strictorder='1'
uci set dhcp.cfg01411c.filter_aaaa='1'
uci commit dhcp

nameRule="option name 'Block_UDP_443'"
str=$(grep -i "$nameRule" /etc/config/firewall)
if [ -z "$str" ] 
then
  echo "Add block QUIC..."

  uci add firewall rule # =cfg2492bd
  uci set firewall.@rule[-1].name='Block_UDP_80'
  uci add_list firewall.@rule[-1].proto='udp'
  uci set firewall.@rule[-1].src='lan'
  uci set firewall.@rule[-1].dest='wan'
  uci set firewall.@rule[-1].dest_port='80'
  uci set firewall.@rule[-1].target='REJECT'
  uci add firewall rule # =cfg2592bd
  uci set firewall.@rule[-1].name='Block_UDP_443'
  uci add_list firewall.@rule[-1].proto='udp'
  uci set firewall.@rule[-1].src='lan'
  uci set firewall.@rule[-1].dest='wan'
  uci set firewall.@rule[-1].dest_port='443'
  uci set firewall.@rule[-1].target='REJECT'
  uci commit firewall
fi

printf "\033[32;1m$messageComplete\033[0m\n"
printf "\033[31;1mAfter 10 second AUTOREBOOT ROUTER...\033[0m\n"
sleep 10
reboot

