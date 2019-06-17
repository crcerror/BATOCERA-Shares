#!/bin/bash

# Mimic batoceraSettings.py
# goal: abbolish this python script, it's useless for the sake of the load feature only
#
# Usage of BASE COMMAND:
#           -command <value> -key <value> -value <value>
#
#           -command    load write enable disable
#           -key        any key in batocera.conf (kodi.enabled...)
#           -value      any alphanumerical string
#                       use quotation marks to avoid globbing use slashe escape special characters 

# This script reads only 1st occourance if string and writes only to 1st occurance
# So 10 entries overwritten with system.power.switch will never occour again.
#
# This script uses #-Character to comment vales
#
# If there is a bolean value (0,1) then then enable and disable command will set the correspondending
# boolean value.

# Examples:
# ./batoceraSettings.sh -command load -key wifi.enabled will print out 0 or 1
# ./batoceraSettings.sh -command write -key wifi.ssid -value "This is my NET" will set wlan.ssid=This is my NET
# ./batoceraSettings.sh -command enable -key wifi.ssid will remove # from  configfile (activate)
# ./batoceraSettings.sh -command disable -key wifi.enabled will set key wifi.enabled=0

readonly BATOCERA_CONFIGFILE="/userdata/system/batocera.conf"
readonly COMMENT_CHAR="#"

function get_config() {
     #Will look for key.value and #key.value for only one occourance
     #If the character is the COMMENT CHAR then set value to it
     #Otherwise strip to equal-char
    local val
    val="$(grep -E -m1 ^$COMMENT_CHAR?\s*$1 $BATOCERA_CONFIGFILE)"
    if [[ "${val:0:1}" == "$COMMENT_CHAR" ]]; then
         val="$COMMENT_CHAR"
    else
         #Maybe here some finetuning to catch key.value = ENTRY without blanks
         val="${val#*=}"
    fi
    echo "$val"
}

function set_config() {
     #Will look for first key.name at line beginnng and write value to it
     sed -i "1,/^\(\s*$1\s*=\).*/s//\1$2/" "$BATOCERA_CONFIGFILE"
}

function uncomment_config() {
     #Will look for first Comment Char at line beginnng and remove it
     sed -i "1,/^$COMMENT_CHAR\(\s*$1\)/s//\1/" "$BATOCERA_CONFIGFILE"
}

function comment_config() {
     #Will look for first key.name at line beginnng and add a comment char to it
     sed -i "1,/^\(\s*$1\)/s//$COMMENT_CHAR\1/" "$BATOCERA_CONFIGFILE"
}

function check_argument() {
    # This method does not accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo >&2
        echo "ERROR: '$1' is missing an argument." >&2
        echo >&2
        echo "Try '$0 --help' for more info." >&2
        echo >&2
        return 1
    fi
}

function usage() {
val=" Usage of BASE COMMAND:

           -command <value> -key <value> -value <value>

           -command    load write enable disable
           -key        any key in batocera.conf (kodi.enabled...)
           -value      any alphanumerical string
                       use quotation marks to avoid globbing

           For write command -value <value> must be provided"

echo "$val"

}

# MAIN
[[ -e "$BATOCERA_CONFIGFILE" ]] || exit 2
[[ "${1,,}" != "-command" ]] && usage && exit 1
check_argument $1 $2
[[ $? -eq 0 ]] || exit 1
command="$2"
shift 2

[[ "${1,,}" != "-key" ]] && usage && exit 1
check_argument $1 $2
[[ $? -eq 0 ]] || exit 1
keyvalue="$2"
shift 2

# value processing
case "$command" in

    "read"|"get"|"load")
        val="$(get_config $keyvalue)"
        [[ -n "$val" ]] && echo "$val" || echo "$keyvalue: not found!"
    ;;

    "set"|"write")
        [[ ${1,,} != "-value" ]] && usage
        check_argument $1 $2
        [[ $? -eq 0 ]] || exit 1

        val="$(get_config $keyvalue)"
        if [[ "$val" == "$COMMENT_CHAR" ]]; then
            uncomment_config "$keyvalue"
            val="$(get_config $keyvalue)"
            set_config "$keyvalue" "$2"
        elif [[ -z "$val" ]]; then
            echo "$keyvalue: not found!"
        elif [[ "$val" != "$2" ]]; then
            set_config "$keyvalue" "$2"
        fi
   ;;

    "uncomment"|"enable"|"activate")
        val="$(get_config $keyvalue)"
        # Boolean
        if [[ "$val" == "$COMMENT_CHAR" ]]; then
            uncomment_config "$keyvalue"
        elif [[ "$val" == "0" ]]; then
             set_config "$keyvalue" "1"
        elif [[ -z "$val" ]]; then
             echo "$keyvalue: not found!"
        fi
    ;;

    "comment"|"disable"|"remark")
        val="$(get_config $keyvalue)"
        # Boolean
        [[ "$val" == "$COMMENT_CHAR" || "$val" == "0" ]] && exit 0
        if [[ -z "$val" ]]; then
            echo "$keyvalue: not found!"
        elif [[ "$val" == "1" ]]; then
             set_config "$keyvalue" "0"
        else
             comment_config "$keyvalue"
        fi
    ;;

    "-h"|"--help")
        usage
    ;;

    *)
        echo "ERROR: invalid option '$1'" >&2
        exit 2
    ;;
esac
