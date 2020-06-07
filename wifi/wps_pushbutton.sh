#!/bin/bash
# First attempt for adding WPS push button connection to BATOCERA
# This works now - 07.06.2020

#### Show list
batocera-wifi scanlist

read -p "Enter SSID to connect and push [WPS]-button: " wifi_conn
connect_tp=$(connmanctl services | grep -m1 "$wifi_conn" | awk -F "$wifi_conn[ ]*" '{print $2}')
connmanctl connect $connect_tp &> /dev/shm/wps.log

if grep -q "^Connected" /dev/shm/wps.log; then
    echo "WPS connected!"
    echo "Connection established" >> /dev/shm/wps.log
    conn_cred="/var/lib/connman/$connect_tp/settings"
    ssid="$(batocera-settings "$conn_cred" get Name)"
    psk="$(batocera-settings "$conn_cred" get Passphrase)"
    batocera-settings set wifi.ssid "$ssid"
    batocera-settings set wifi.key "$psk"
elif grep -q "Already connected" /dev/shm/wps.log; then
    echo "Connections already established to '$wifi_conn'"
else
    echo "Failed: WPS connection"
fi
