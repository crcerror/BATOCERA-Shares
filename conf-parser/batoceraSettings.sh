#!/bin/bash

# batoceraSettings.sh to mimic batoceraSettings.py
# goal: abbolish this python script, it's useless for the sake of the load feature only
#
# Usage of BASE COMMAND:
#           <filename> -command <cmd> -key <key> -value <value>
#
#           -command    load write enable disable status
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

BATOCERA_CONFIGFILE="/userdata/system/batocera.conf"
COMMENT_CHAR="#"

function get_config() {
     #Will look for key.value and #key.value for only one occourance
     #If the character is the COMMENT CHAR then set value to it
     #Otherwise strip to equal-char
    local val
    val="$(grep -E -m1 ^$COMMENT_CHAR?\s*$1\s*= $BATOCERA_CONFIGFILE)"
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

           <file> -command <cmd> -key <key> -value <value>

           -command    load write enable disable status
           -key        any key in batocera.conf (kodi.enabled...)
           -value      any alphanumerical string
                       use quotation marks to avoid globbing

           For write command -value <value> must be provided

           exit codes: exit 0  = value is available, proper exit
                       exit 1  = general error
                       exit 2  = file error
                       exit 11 = value found, but not activated
                       exit 12 = value not found 

           If you don't set a filename then default is '~/batocera.conf'"

echo "$val"

}

# MAIN
function main() {

    #Filename parsed?
    if [[ -f "$1" ]]; then
        BATOCERA_CONFIGFILE="$1"
        shift 
    else
       [[ -f "$BATOCERA_CONFIGFILE" ]] || { echo "not found: $BATOCERA_CONFIGFILE" >&2; exit 2; }
    fi

    #First command line parameter set, shift 2
    [[ "${1,,}" != "-command" ]] && usage && exit 1
    check_argument $1 $2
    [[ $? -eq 0 ]] || exit 1
    command="$2"
    shift 2

    #Second command line parameter set, shift
    [[ "${1,,}" != "-key" ]] && usage && exit 1
    check_argument $1 $2
    [[ $? -eq 0 ]] || exit 1
    keyvalue="$2"
    shift 2

    # value processing, switch case
    case "$command" in

        "read"|"get"|"load")
            val="$(get_config $keyvalue)"
            [[ "$val" == "$COMMENT_CHAR" ]] && echo "$val" >&2 && exit 11
            [[ -z "$val" ]] && exit 12
            [[ -n "$val" ]] && echo "$val" && exit 0
        ;;

        "stat"|"status")
            val="$(get_config $keyvalue)"
            [[ -f "$BATOCERA_CONFIGFILE" ]] && echo "ok: found '$BATOCERA_CONFIGFILE'" >&2|| echo "error: not found '$BATOCERA_CONFIGFILE'" >&2
            [[ -w "$BATOCERA_CONFIGFILE" ]] && echo "ok: r/w file '$BATOCERA_CONFIGFILE'" >&2 || echo "error: r/o file '$BATOCERA_CONFIGFILE'" >&2
            [[ -z "$val" ]] && echo "error: '$keyvalue' not found!" >&2
            [[ "$val" == "$COMMENT_CHAR" ]] && echo "error: '$keyvalue' is commented $COMMENT_CHAR!" >&2 && val=
            [[ -n "$val" ]] && echo "ok: '$keyvalue' $val" || echo "error: '$keyvalue' not available" >&2
            exit 0
        ;;

        "set"|"write"|"save")
            [[ ${1,,} != "-value" ]] && usage && exit 1
            check_argument $1 $2
            [[ $? -eq 0 ]] || exit 1

            ! [[ -w "$BATOCERA_CONFIGFILE" ]] && echo "r/o only: $BATOCERA_CONFIGFILE" >&2 && exit 2

            val="$(get_config $keyvalue)"
            if [[ "$val" == "$COMMENT_CHAR" ]]; then
                echo "$keyvalue: hashed out!" >&2
                uncomment_config "$keyvalue"
                set_config "$keyvalue" "$2"
                echo "$keyvalue: set to $2" >&2
                exit 0
            elif [[ -z "$val" ]]; then
                echo "$keyvalue: not found!" >&2
                exit 12
            elif [[ "$val" != "$2" ]]; then
                set_config "$keyvalue" "$2"
                exit 0 
            fi
        ;;

        "uncomment"|"enable"|"activate")
            val="$(get_config $keyvalue)"
            # Boolean
            if [[ "$val" == "$COMMENT_CHAR" ]]; then
                 uncomment_config "$keyvalue"
                 echo "$keyvalue: removed '$COMMENT_CHAR', key is active" >&2
            elif [[ "$val" == "0" ]]; then
                 set_config "$keyvalue" "1"
                 echo "$keyvalue: boolean set '1'" >&2
            elif [[ -z "$val" ]]; then
                 echo "$keyvalue: not found!" && exit 2
            fi
        ;;

        "comment"|"disable"|"remark")
            val="$(get_config $keyvalue)"
            # Boolean
            [[ "$val" == "$COMMENT_CHAR" || "$val" == "0" ]] && exit 0
            if [[ -z "$val" ]]; then
                echo "$keyvalue: not found!" >&2 && exit 12
            elif [[ "$val" == "1" ]]; then
                 set_config "$keyvalue" "0"
                 echo "$keyvalue: boolean set to '0'" >&2
            else
                 comment_config "$keyvalue"
                 echo "$keyvalue: added '$COMMENT_CHAR', key is not active" >&2
            fi
        ;;

        *)
            echo "ERROR: invalid command '$command'" >&2
            exit 1
        ;;
    esac
}

# Prepare arrays from fob python script
# Delimiter is |
# Keyword for python call is mimic_python
# Attention the unset is needed to eliminate first argument (python basefile)

if [[ "${#@}" -eq 1 && "$1" =~ "mimic_python" ]]; then
   #batoceraSettings.py fob
   readarray -t arr <<< "$1"
   unset arr[0]
else
   #regular call by shell
   arr=("$@")
fi

main "${arr[@]}"
