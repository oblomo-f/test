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


checkPackageAndInstall "jq" "1"
checkPackageAndInstall "curl" "1"
checkPackageAndInstall "unzip" "1"
checkPackageAndInstall "opera-proxy" "1"
opkg remove --force-removal-of-dependent-packages "sing-box"

findVersion="1.12.0"
if opkg list-installed | grep "^sing-box-tiny" && printf '%s\n%s\n' "$findVersion" "$VERSION" | sort -V | tail -n1 | grep -qx -- "$VERSION"; then
	printf "\033[32;1mInstalled new sing-box-tiny. Running scprit...\033[0m\n"
else
	printf "\033[32;1mInstalled old sing-box-tiny or not install sing-box-tiny. Reinstall sing-box-tiny...\033[0m\n"
	manage_package "podkop" "enable" "stop"
	opkg remove --force-removal-of-dependent-packages "sing-box-tiny"
	checkPackageAndInstall "sing-box-tiny" "1"
fi


#проверяем установлени ли пакет dnsmasq-full
if opkg list-installed | grep -q dnsmasq-full; then
	echo "dnsmasq-full already installed..."
else
	echo "Installed dnsmasq-full..."
	cd /tmp/ && opkg download dnsmasq-full
	opkg remove dnsmasq && opkg install dnsmasq-full --cache /tmp/

	[ -f /etc/config/dhcp-opkg ] && cp /etc/config/dhcp /etc/config/dhcp-old && mv /etc/config/dhcp-opkg /etc/config/dhcp
fi


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


echo "Configure dhcp..."

uci set dhcp.cfg01411c.strictorder='1'
uci set dhcp.cfg01411c.filter_aaaa='1'
uci commit dhcp

cat <<EOF > /etc/sing-box/config.json
{
	"log": {
	"disabled": true,
	"level": "error"
},
"inbounds": [
	{
	"type": "tproxy",
	"listen": "::",
	"listen_port": 1100,
	"sniff": false
	}
],
"outbounds": [
	{
	"type": "http",
	"server": "127.0.0.1",
	"server_port": 18080
	}
],
"route": {
	"auto_detect_interface": true
}
}
EOF

echo "Setting sing-box..."
uci set sing-box.main.enabled='1'
uci set sing-box.main.user='root'
uci add_list sing-box.main.ifaces='wan'
uci add_list sing-box.main.ifaces='wan2'
uci add_list sing-box.main.ifaces='wan6'
uci add_list sing-box.main.ifaces='wwan'
uci add_list sing-box.main.ifaces='wwan0'
uci add_list sing-box.main.ifaces='modem'
uci add_list sing-box.main.ifaces='l2tp'
uci add_list sing-box.main.ifaces='pptp'
uci commit sing-box

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

manage_package "podkop" "enable" "stop"

curl -f -o /dev/null -k --connect-to ::google.com -L -H "Host: mirror.gcr.io" --max-time 120 https://test.googlevideo.com/v2/cimg/android/blobs/sha256:2ab09b027e7f3a0c2e8bb1944ac46de38cebab7145f0bd6effebfe5492c818b6


isWorkOperaProxy=0
printf "\033[32;1mCheck opera proxy...\033[0m\n"
service sing-box restart
curl --proxy http://127.0.0.1:18080 ipinfo.io/ip
if [ $? -eq 0 ]; then
	printf "\n\033[32;1mOpera proxy well work...\033[0m\n"
	isWorkOperaProxy=1
else
	printf "\033[32;1mOpera proxy not work...\033[0m\n"
	isWorkOperaProxy=0
fi


printf  "\033[32;1mRestart service dnsmasq, odhcpd...\033[0m\n"
service dnsmasq restart
service odhcpd restart

path_podkop_config="/etc/config/podkop"
path_podkop_config_backup="/root/podkop"
URL="https://raw.githubusercontent.com/routerich/RouterichAX3000_configs/refs/heads/podkop07"


PACKAGE="podkop"
REQUIRED_VERSION="v0.7.7-r1"

INSTALLED_VERSION=$(opkg list-installed | grep "^$PACKAGE" | cut -d ' ' -f 3)
if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$REQUIRED_VERSION" ]; then
    echo "Version package $PACKAGE not equal $REQUIRED_VERSION. Removed packages..."
    opkg remove --force-removal-of-dependent-packages $PACKAGE
fi

if [ -f "/etc/init.d/podkop" ]; then
	#printf "Podkop installed. Reconfigured on AWG WARP and Opera Proxy? (y/n): \n"
	#is_reconfig_podkop="y"
	#read is_reconfig_podkop
	if [ "$is_reconfig_podkop" = "y" ] || [ "$is_reconfig_podkop" = "Y" ]; then
		cp -f "$path_podkop_config" "$path_podkop_config_backup"
		wget -O "$path_podkop_config" "$URL/config_files/$nameFileReplacePodkop" 
		echo "Backup of your config in path '$path_podkop_config_backup'"
		echo "Podkop reconfigured..."
	fi
else
	#printf "\033[32;1mInstall and configure PODKOP (a tool for point routing of traffic)?? (y/n): \033[0m\n"
	is_install_podkop="y"
	#read is_install_podkop

	if [ "$is_install_podkop" = "y" ] || [ "$is_install_podkop" = "Y" ]; then
		DOWNLOAD_DIR="/tmp/podkop"
		mkdir -p "$DOWNLOAD_DIR"
		podkop_files="podkop-v0.7.7-r1-all.ipk
			luci-app-podkop-v0.7.7-r1-all.ipk
			luci-i18n-podkop-ru-0.7.7.ipk"
		for file in $podkop_files
		do
			echo "Download $file..."
			wget -q -O "$DOWNLOAD_DIR/$file" "$URL/podkop_packets/$file"
		done
		opkg install $DOWNLOAD_DIR/podkop*.ipk
		opkg install $DOWNLOAD_DIR/luci-app-podkop*.ipk
		opkg install $DOWNLOAD_DIR/luci-i18n-podkop-ru*.ipk
		rm -f $DOWNLOAD_DIR/podkop*.ipk $DOWNLOAD_DIR/luci-app-podkop*.ipk $DOWNLOAD_DIR/luci-i18n-podkop-ru*.ipk
		wget -O "$path_podkop_config" "$URL/config_files/$nameFileReplacePodkop" 
		echo "Podkop installed.."
	fi
fi

printf  "\033[32;1mStart and enable service 'doh-proxy'...\033[0m\n"
manage_package "doh-proxy" "enable" "start"

str=$(grep -i "0 4 \* \* \* wget -O - $URL/configure_zaprets.sh | sh" /etc/crontabs/root)
if [ ! -z "$str" ]
then
	grep -v "0 4 \* \* \* wget -O - $URL/configure_zaprets.sh | sh" /etc/crontabs/root > /etc/crontabs/temp
	cp -f "/etc/crontabs/temp" "/etc/crontabs/root"
	rm -f "/etc/crontabs/temp"
fi


printf  "\033[32;1mService Podkop and Sing-Box restart...\033[0m\n"
service sing-box enable
service sing-box restart
service podkop enable
service podkop restart

printf "\033[32;1m$messageComplete\033[0m\n"
printf "\033[31;1mAfter 10 second AUTOREBOOT ROUTER...\033[0m\n"
sleep 10
reboot
