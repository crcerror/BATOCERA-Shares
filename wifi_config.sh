#!/bin/bash
# Wifi config

##### pathes
readonly BATOCERA_CONFIGFILE=batocera.config
#####
##### Options
##### Read wifikeyfile, setup wifikey manual write to batocera.config
#####


while [[ $home -eq 0 ]]; do
array=("1" "Input SSID" "2" "Input Key" "3" "Import" "4" "Write")
cmd=(whiptail --ok-button "Select" --menu "Select" 18 70 0)
choices=$("${cmd[@]}" "${array[@]}" 3>&1 1>&2 2>&3)
home=$?
echo $home

case $choices in
    1) echo "Input SSID" ;;
    2) echo "Input WPA-Key" ;;
    3) echo "Import from /boot/wifikeyfile.txt" ;;
    4) echo "Writing to $BATOCERA_CONFIG"
esac

[[ $home -eq 1 ]] || sleep 5
done
