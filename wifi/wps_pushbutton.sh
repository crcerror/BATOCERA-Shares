#!/bin/bash
# First attempt for adding WPS push button connection to BATOCERA
#

wifi_setupdir=/var/lib/connman
wifi_conn="VALUE FROM LIST"

#echo "$wifi_conn" | grep "VALUE" | awk -F "VALUE[ ]*" '{print $2}'
#exit
#### Show list
batocera-wifi scanlist

read -p "SSID? " wifi_conn
connect_tp=$(connmanctl services | grep -m1 "$wifi_conn" | awk -F "$wifi_conn[ >
connmanctl connect $connect_tp
echo $?
