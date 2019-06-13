#!/bin/bash
# Setup Credentials for WIFI
# Place this script to /userdata/system/scripts
# Add call to script to /userdata/system/custom.sh to autostart
#
# To import keyfile place wifikeyfile.txt to /boot (this is visible FAT32 ext. in Windows)
# To import keyfile activate WiFi in EmulationStation and reboot
#
# by cyperghost 2019/06/13

readonly BATOCERA_CONFIGFILE="$HOME/batocera.conf"
readonly WIFI_KEYFILE="/boot/wifikeyfile.txt"
readonly COMMENT_CHAR="#"

function get_config() {
     local val
     val=$(grep -E -m1 ^$COMMENT_CHAR?$1 $BATOCERA_CONFIGFILE) 
     [[ "${val:0:1}" == "$COMMENT_CHAR" ]] && val=
     val=${val//$1=/}
     echo $val
}

function set_config() {
     sed -i "s|^\(\s*$1\s*=\).*|\1$2|" "$BATOCERA_CONFIGFILE"
}

[[ -e "$WIFI_KEYFILE" ]] || exit                              #If no file present then exit
[[ "$(get_config wifi.enabled)" -eq 0 ]] && exit              #If WiFi is disabled then exit 

while read line; do
    if [[ "$line" =~ "psk=\"" ]]; then
        psk="${line#*\"}"
        psk="${psk%\"*}"
        val=$(get_config wifi.key)
        [[ "$psk" == "$val" || -z "$val" ]] && psk=          #If Passkey already setted then clear psk var
    elif [[ "$line" =~ "ssid=\"" ]]; then
        ssid="${line#*\"}"
        ssid="${ssid%\"*}" 
        val=$(get_config wifi.ssid)
        [[ "$ssid" == "$val" || -z $val  ]] && ssid=         #If SSID is setted then clear ssid var
    fi
done < <(tr -d '\r' < "$WIFI_KEYFILE")

[[ -z $psk ]] && echo "KEY is equal or $BATOCERA_CONFIGFILE value is commented" || set_config wifi.key "$psk"
[[ -z $ssid ]] && echo "SSID is euqal or $BATOCERA_CONFIGFILE value is commented" || set_config wifi.ssid "$ssid"
