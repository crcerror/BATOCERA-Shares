#!/bin/bash

# batocera-settings can mimic batoceraSettings.py
# goal: abolish this python script, it's useless for the sake of the load feature only
#       get a more user friendly environment for setting, getting and saving keys
#
# Usage of BASE COMMAND:
#           longform:   <filename> --command <cmd> --key <key> --value <value>
#
#           shortform:  <file> <cmd> <key> <value>
#
#           --command    load write enable disable status
#           --key        any key in batocera.conf (kodi.enabled...)
#           --value      any alphanumerical string
#                        use quotation marks to avoid globbing use slashes escape special characters 

# This script reads only 1st occurrence if string and writes only to this first hit
#
# This script uses #-Character to comment values
#
# If there is a boolean value (0,1) then then enable and disable command will set the corresponding
# boolean value.

# Examples:
# 'batocera-settings --command load --key wifi.enabled' will print out 0 or 1
# 'batocera-settings --command write --key wifi.ssid -value "This is my NET"' will set 'wlan.ssid=This is my NET'
# 'batocera-settings enable wifi.ssid' will remove # from  configfile (activate)
# 'batocera-settings disable wifi.enabled' will set key wifi.enabled=0
# 'botocera-settings /myown/config.file --command status --key my.key' will output status of own config.file and my.key 

# by cyperghost - 2019/12/30

##### INITS #####
BATOCERA_CONFIGFILE="/userdata/system/batocera.conf"
COMMENT_CHAR_SEARCH="[#|;]"
COMMENT_CHAR="#"
##### INITS #####

##### Function Calls #####

function get_config() {
    #Will search for key.value and #key.value for only one occurrence
    #If the character is the COMMENT CHAR then set value to it
    #Otherwise strip till the equal-char to obtain value
    local val
    local ret
    val="$(grep -E -m1 "^\s*$1\s*=" $BATOCERA_CONFIGFILE)"
    ret=$?
    if [[ $ret -eq 1 ]]; then 
        val="$(grep -E -m1 "^$COMMENT_CHAR_SEARCH\s*$1\s*=" $BATOCERA_CONFIGFILE)"
        ret=$?
        [[ $ret -eq 0 ]] && val=$COMMENT_CHAR
    else
         #Maybe here some finetuning to catch key.value = ENTRY without blanks
         val="${val#*=}"
    fi
    echo "$val"
    return $ret
}

function set_config() {
     #Will search for first key.name at beginning of line and write value to it
     sed -i "1,/^\(\s*$1\s*=\).*/s//\1$2/" "$BATOCERA_CONFIGFILE"
}

function uncomment_config() {
     #Will search for first Comment Char at beginning of line and remove it
     sed -i "1,/^$COMMENT_CHAR_SEARCH\(\s*$1\)/s//\1/" "$BATOCERA_CONFIGFILE"
}

function comment_config() {
     #Will search for first key.name at beginning of line and add a comment char to it
     sed -i "1,/^\(\s*$1\)/s//$COMMENT_CHAR\1/" "$BATOCERA_CONFIGFILE"
}

function check_argument() {
    # This method does not accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo >&2
        echo "ERROR: '$1' is missing an argument." >&2
        echo >&2
        echo "Just type '$0' to see usage page." >&2
        echo >&2
        return 1
    fi
}

function classic_style() {
    #This function is needed to "simulate" the python script with single dash
    #commands. It will also accept the more common posix double dashes   
    #Accept dashes and double dashes and build new array ii with parameter set
    #The else-branch can be used for the shortform

    for i in --command --key --value; do
        if [[ -z "$1" ]]; then
            continue 
        elif [[ "$i" =~ ^-{0,1}"${1,,}" ]]; then
            check_argument $1 $2
            [[ $? -eq 0 ]] || exit 1
            ii+=("$2")
            shift 2
        else
            ii+=("$1")
            shift 1
        fi
    done
}


function usage() {
val=" Usage of BASE COMMAND:

           <file> --command <cmd> --key <key> --value <value>

           shortform: <file> <cmd> <key> <value>

           --command    load write enable disable status
           --key        any key in batocera.conf (kodi.enabled...)
           --value      any alphanumerical string
                        use quotation marks to avoid globbing

           For write command --value <value> must be provided

           exit codes: exit 0  = value is available, proper exit
                       exit 1  = general error
                       exit 2  = file error
                       exit 10 = value found, but empty
                       exit 11 = value found, but not activated
                       exit 12 = value not found

           If you don't set a filename then default is '~/batocera.conf'"

echo "$val"

}
##### Function Calls #####

##### MAIN FUNCTION #####
function main() {

    #Filename parsed?
    if [[ -f "$1" ]]; then
        BATOCERA_CONFIGFILE="$1"
        shift 
    else
       [[ -f "$BATOCERA_CONFIGFILE" ]] || { echo "not found: $BATOCERA_CONFIGFILE" >&2; exit 2; }
    fi

    #How much arguments are parsed, up to 6 then it is the long format
    #up to 3 then it is the short format
    if [[ ${#@} -eq 0 ]]; then
        usage
        exit 1
    elif [[ "$1" =~ (--command|load|get|read) ]]; then
        classic_style "$@"
        command="${ii[0]}"
        keyvalue="${ii[1]}"
        newvalue="${ii[2]}"
        unset ii
    else
        echo "use other method"
    fi

echo "${keyvalue}"
exit
    [[ -z $keyvalue ]] && { echo "error: Please provide a proper keyvalue" >&2; exit 1; }

    # value processing, switch case
    case "${command}" in

        "read"|"get"|"load")
            val="$(get_config $keyvalue)"
            ret=$?
            [[ "$val" == "$COMMENT_CHAR" ]] && exit 11
            [[ -z "$val" && $ret -eq 0 ]] && exit 10
            [[ -z "$val" && $ret -eq 1 ]] && exit 12
            [[ -n "$val" ]] && echo "$val" && exit 0
        ;;

        "stat"|"status")
            val="$(get_config $keyvalue)"
            ret=$?
            [[ -f "$BATOCERA_CONFIGFILE" ]] && echo "ok: found '$BATOCERA_CONFIGFILE'" >&2 || echo "error: not found '$BATOCERA_CONFIGFILE'" >&2
            [[ -w "$BATOCERA_CONFIGFILE" ]] && echo "ok: r/w file '$BATOCERA_CONFIGFILE'" >&2 || echo "error: r/o file '$BATOCERA_CONFIGFILE'" >&2
            [[ -z "$val" && $ret -eq 1 ]] && echo "error: '$keyvalue' not found!" >&2
            [[ -z "$val" && $ret -eq 0 ]] && echo "error: '$keyvalue' is empty - use 'comment' command to retrieve" >&2
            [[ "$val" == "$COMMENT_CHAR" ]] && echo "error: '$keyvalue' is commented $COMMENT_CHAR!" >&2 && val=
            [[ -n "$val" ]] && echo "ok: '$keyvalue' $val"
            exit 0
        ;;

        "set"|"write"|"save")
            #Is file write protected?
            [[ -w "$BATOCERA_CONFIGFILE" ]] || { echo "r/o file: $BATOCERA_CONFIGFILE" >&2; exit 2; }
            #We can comment line above to erase keys, it's much saver to check if a value is setted
            [[ -z "$newvalue" ]] && echo "error: '$keyvalue' needs value to be setted" >&2 && exit 1

            val="$(get_config $keyvalue)"
            ret=$?
            if [[ "$val" == "$COMMENT_CHAR" ]]; then
                echo "$keyvalue: hashed out!" >&2
                uncomment_config "$keyvalue"
                set_config "$keyvalue" "$newvalue"
                echo "$keyvalue: set from '$val' to '$newvalue'" >&2
                exit 0
            elif [[ -z "$val" && $ret -eq 1 ]]; then
                echo "$keyvalue: not found!" >&2
                exit 12
            elif [[ "$val" != "$newvalue" ]]; then
                set_config "$keyvalue" "$newvalue"
                exit 0 
            fi
        ;;

        "uncomment"|"enable"|"activate")
            val="$(get_config $keyvalue)"
            ret=$?
            # Boolean
            if [[ "$val" == "$COMMENT_CHAR" ]]; then
                 uncomment_config "$keyvalue"
                 echo "$keyvalue: removed '$COMMENT_CHAR', key is active" >&2
            elif [[ "$val" == "0" ]]; then
                 set_config "$keyvalue" "1"
                 echo "$keyvalue: boolean set '1'" >&2
            elif [[ -z "$val" && $ret -eq 1 ]]; then
                 echo "$keyvalue: not found!" && exit 2
            fi
        ;;

        "comment"|"disable"|"remark")
            val="$(get_config $keyvalue)"
            ret=$?
            # Boolean
            [[ "$val" == "$COMMENT_CHAR" || "$val" == "0" ]] && exit 0
            if [[ -z "$val" && $ret -eq 1 ]]; then
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
##### MAIN FUNCTION #####

##### MAIN CALL #####

# Prepare arrays from fob python script
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

##### MAIN CALL #####
