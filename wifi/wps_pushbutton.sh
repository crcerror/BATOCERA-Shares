#!/bin/bash
# First attempt for adding WPS push button connection to BATOCERA
#

wifi_setupdir=/var/lib/connman
wifi_conn="VALUE FROM LIST"

#echo "$wifi_conn" | grep "VALUE" | awk -F "VALUE[ ]*" '{print $2}'
#exit
#### Show list
batocera-wifi scanlist

read -p "Enter SSID to connect and push [WPS]-button: " wifi_conn
connect_tp=$(connmanctl services | grep -m1 "$wifi_conn" | awk -F "$wifi_conn[ ]*" '{print $2}')
connmanctl connect $connect_tp &> /dev/shm/wps.log

if grep "^Connected" /dev/shm/wps.log; then
    echo "WPS connected!"
    echo "Connection established" >> /dev/shm/wps.log
    conn_cred="/var/lib/connman/$connect_tp/settings"
    ssid="$(batocera-settings "$conn_cred" get Name)"
    psk="$(batocera-settings "$conn_cred" get Passphrase)"
    echo "SSID: $ssid" >> /dev/shm/wps.log
    echo "PSK: $psk"   >> /dev/shm/wps.log
else
    echo "Failed: WPS connection"
fi
