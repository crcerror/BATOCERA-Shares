#!/bin/bash
# WIFI CONFIG by cyperghost for BATOCERA
# 2019/05/11
# Credits to hiulit @RetroPie forum for the nice config setups
# and helpfull RegEx setups
#
# There are seveal options to get your inputs
# Input manual:
# Select 1 and enter your PSK key with a keyboard connected or terminal
# Select 2 and enter your WIFI SSID with keyboard connected or terminal
#
# Automatic inputs:
# Option 3 tries to obtain presetted file with wifi credentials located in /boot/wifikeyfile.txt
# you need to place your password and your ssid in a form like this
# psk="my password to wifi"
# ssid="my wlan SSID"
#
# The other options are for  transfer or change your inputs to BATOCERA configfile
# Option 4 - selects current wifislot. Batocera gots 3 of them, only the first is visible in ES
# Option 5 - Read the credentials out from current slot (if active!)
# Option 6 - Writes the obtained credentials to current slot (if active)
#
# Option A - Activates current slot (it just removes the # remark)
# Option C - Clean PSK and SSID for current slot (you need to select save)
# Option D - Deactivates current slot (it sets the # remark)


##### pathes and main setup
readonly BATOCERA_CONFIGFILE="$HOME/batocera.conf"
readonly WIFI_KEYFILE="/boot/wifikeyfile.txt"
#####
##### OPTIONS
##### Read wifikeyfile, setup wifikey manual write to batocera.config
#####

array=("1" "PSK" "2" "SSID" "3" "Import from keyfile" "4" "SLOT" \
       "5" "Read credentials from current slot" "6" "Write credentials to current slot" \
       "A" "Activate current slot" "C" "Clean settings for current slot" "D" "Deactivate current slot")


#####
##### FUNCTIONS
##### Read wifikeyfile, setup wifikey manual write to batocera.config
#####


# These are main whiptail functions, first parameter is always message text
# USAGE:
# function input_box "[TEXT]" "[DEFAULTVALUE]" - shows you a input box
# function msg_box "[TEXT"] - shows a small box with OK button to close

function input_box() {
    local val=$(whiptail --inputbox "$1" --cancel-button "Clear" 10 50 "$2" 3>&1 1>&2 2>&3)
    echo "$val"
}

function msg_box() {
    whiptail --msgbox "$1" 10 50 3>&1 1>&2 2>&3
}

# If you are using the config file, uncomment set_config() and get_config().
# USAGE:
# set_config "[KEY]" "[VALUE]" "[CONFFILE]" - Sets the VALUE to the KEY in $BATOCERA_CONFIGFILE.
# get_config "[KEY]" "[CONFFILE]"- Returns the KEY's VALUE in $BATOCERA_CONFIGFILE.
# rem_config "[KEY]" "[CONFFILE]"- Enable/Disable KEY in $BATOCERA_CONFIGFILE.
#

function set_config() {
    sed -i "s|^\(\s*$1\s*=\).*|\1$2|" "$3"
}

function get_config() {
    local config
    config="$(grep -Po "(?<=^$1=).*" "$2")"
    config="${config%\"}"
    config="${config#\"}"
    echo "$config"
}

function rem_config() {
    sed -i "s|^\s*$1|$2|" "$3"
}


# This function checks current state of SLOT (active/not active)
# USAGE
# slot_state "[SLOTNUMBER]" - Returns boolean if values are readable

function slot_state() {
    local config="$(grep -Po -c "^$1" "$2")"
    echo $config
}

#####
##### MAIN PROGRAMM
#####

# We first check presence of config file
! [[ -e "$BATOCERA_CONFIGFILE" ]] && msg_box "Error!\nBATOCERA CONFIG not found in\n$BATOCERA_CONFIGFILE" && exit
 
# We start the loop as long as cancel is not selected
while [[ $home -eq 0 ]]; do

    # Some prechecks
    # if PSK and SSID not set, then show a nice text
    # is the slot currently activated?
    [[ -n "$PSK" ]] && array[3]="PSK  set: ${PSK:0:9} ..." || array[3]="Input PSK"
    [[ -n "$SSID" ]] && array[1]="SSID set: $SSID" || array[1]="Input SSID"

    # Setup Slots, it's a bit nasty with this
    [[ $SLOT -eq 1 ]] && SLOT=
    [[ $(slot_state wifi${SLOT}.ssid "$BATOCERA_CONFIGFILE") -eq 0 ]] && slotstate="deactivated" || slotstate="activated"
    [[ -z "$SLOT" ]] && array[7]="Slot set: 1 - Status: $slotstate" || array[7]="Slot set: $SLOT - Status: $slotstate"    

    # Whiptail dialog begin
    cmd=(whiptail --title " Wifi Key Config " --ok-button "Select" --menu "Select your options" 18 70 0)
    choices=$("${cmd[@]}" "${array[@]}" 3>&1 1>&2 2>&3)
    home=$?

    # Case selection of choice
    case $choices in
        1) #Enter SSID
            SSID=$(input_box "Input SSID" "$SSID")
        ;;

        2) #Enter WPA Key
           PSK=$(input_box "Input WPA-Key" "$PSK")
        ;;

        3) #Import from /boot/wifikeyfile.txt
           if [[ -e "$WIFI_KEYFILE" ]]; then
               while read -r var; do
                   if [[ "ssid=" == "${var:0:5}" ]]; then
                       SSID=$(echo "$var" | cut -d "\"" -f 2)
                   elif [[ "psk=" == "${var:0:4}" ]]; then
                       PSK=$(echo "$var" | cut -d "\"" -f 2)
                   else
                       msg_box "Error! PSK or SSID not found!"
                   fi
               done < <(tr -d '\r' < "$WIFI_KEYFILE")
           else
              msg_box "File missing! Aborting"
           fi
        ;;

        4) # Select WIFI Slot to BATOCERA CONFIG
             SLOT=$(input_box "Enter Slot to put your credentials in" "1")
             SLOT=${SLOT//[^[:digit:].]/}
             [[ $SLOT -gt 3 ]] && SLOT=1
        ;;

        5) # Read Value from SLOT
           if [[ $slotstate == "activated" ]]; then
               PSK=$(get_config "wifi${SLOT}.key" "$BATOCERA_CONFIGFILE")
               SSID=$(get_config "wifi${SLOT}.ssid" "$BATOCERA_CONFIGFILE")
           else
               msg_box "Activate Slot first!"
           fi
        ;;

        6) # Write Value to current SLOT
           if [[ $slotstate == "activated" ]]; then
               set_config "wifi${SLOT}.key" "$PSK" "$BATOCERA_CONFIGFILE"
               set_config "wifi${SLOT}.ssid" "$SSID" "$BATOCERA_CONFIGFILE"
           else
               msg_box "Activate Slot first!"
           fi
        ;;

        A) # Activate current slot
           rem_config "#wifi${SLOT}.key" "wifi${SLOT}.key" "$BATOCERA_CONFIGFILE"
           rem_config "#wifi${SLOT}.ssid" "wifi${SLOT}.ssid" "$BATOCERA_CONFIGFILE"
        ;;

        C) # Clean current slot
            PSK= ; SSID=
            msg_box "PSK and SSID are cleaned!\nSelect \"6 Write credentials to current slot\""
        ;;

        D) # Deactivate current slot
            rem_config "wifi${SLOT}.key" "#wifi${SLOT}.key" "$BATOCERA_CONFIGFILE"
            rem_config "wifi${SLOT}.ssid" "#wifi${SLOT}.ssid" "$BATOCERA_CONFIGFILE"
            PSK= ;SSID=
        ;;

    esac
done
