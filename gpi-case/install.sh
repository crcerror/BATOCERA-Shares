#!/bin/bash

git_path="https://raw.githubusercontent.com/crcerror/BATOCERA-Shares/master/gpi-case"

echo "GPiCase Installer - beta"
echo

echo "Install files"
file_dest="/usr/bin"
wget -q --show-progress "$git_path/rpi_gpioswitch" -O "$file_dest/rpi_gpioswitch"
wget -q --show-progress "$git_path/rpi-retroflag-GPiCase.py" -O "$file_dest/rpi-retroflag-GPiCase"
echo "$file_dest/rpi-retroflag-GPiCase: Make file executable"
chmod +x "$file_dest/rpi-retroflag-GPiCase"
echo

file_dest="/etc/init.d"
wget -q --show-progress "$git_path/S92switch" -O "$file_dest/S92switch"

# Not needed for Batocera 5.25
echo
echo "Making changes permanent..."
batocera-save-overlay

# Setup conf file
echo
echo "Activate RETROFLAG_GPI in batocera.conf"
batocera-settings set system.power.switch RETROFLAG_GPI

# That's it ....
echo
echo "Please reboot now manually"