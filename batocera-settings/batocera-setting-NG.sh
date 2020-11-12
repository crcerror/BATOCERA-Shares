#!/bin/bash

# by cyperghost - 2019/12/30 - rev 2
# updated for batocera 29 to NG

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

function build_key() {

    ii=("${systemvalue}.\[\"$gamevalue\"\].${keyvalue}"
        "${systemvalue}.${keyvalue}"
        "global.${keyvalue}")

    [[ $game_flag -eq 0 ]] && ii=("${ii[@]:1}")
    [[ $system_flag -eq 0 ]] && ii=("${ii[@]:2}")
    [[ ${#ii[@]} -eq 0 ]] && ii="global.${keyvalue}"

    for i in "${ii[@]}"; do
        if grep -qEo -m1 "^$i" "$BATOCERA_CONFIGFILE"; then
            keyvalue="$i"
            return 0
        fi
    done
    unset ii
    return 1
}

##### Function Calls #####

##### MAIN FUNCTION #####
function main() {
    #Determine here between the classic mode born from 4.x versions
    #and try to make a future proof but simple parser
    # No args -> helppage
    if [[ ${#@} -eq 0 ]]; then
        usage
        exit 1
    elif [[ ${#1} -gt 2 || -f "$1" ]]; then
        #Filename parsed?
        if [[ -f "$1" ]]; then
            BATOCERA_CONFIGFILE="$1"
            shift
            [[ -f "$BATOCERA_CONFIGFILE" ]] || { echo "not found: $BATOCERA_CONFIGFILE" >&2; exit 2; }
        fi

        classic_style "$@"
        command="${ii[0]}"
        keyvalue="${ii[1]}"
        newvalue="${ii[2]}"
        unset ii
        [[ -z $keyvalue ]] && { echo "error: Please provide a proper keyvalue" >&2; exit 1; }
        processing
        exit $?
    else
        #GETOPT function
        #r=read single key; w=write single key
        #f=file; v=value

        #"Advanced options"
        #e=enable extended options (no argument)
        #s=system; g=game; v=key
        #This is used to build a key
        #
        # Set defaults
        extend_flag=0
        game_flag=0
        system_flag=0
        newvalue_flag=0
        write_flag=0

        while getopts ':r:w:v:g:s:f:eh' option
        do
            case "$option" in
                :) echo "Missing option argument for -$OPTARG" >&2; exit 2;;
                f) BATOCERA_CONFIGFILE="$OPTARG";;
                e) extend_flag=1;;
                v) newvalue="$OPTARG"; newvalue_flag=1;;
                w) command=$option; keyvalue="$OPTARG"; write_flag=1;;
                r) command=$option; keyvalue="$OPTARG";;
                h) usage; exit 0;;
                g) gamevalue="$OPTARG"; game_flag=1;;
                s) systemvalue="$OPTARG"; system_flag=1;;
                *) echo "Unimplemented option: -$OPTARG" >&2; exit 1 ;;
            esac
        done
            [[ -z $command ]] && { echo "error: Please provide a proper command" >&2; exit 1; }
            [[ -z $keyvalue ]] && { echo "error: Please provide a proper keyvalue" >&2; exit 1; }
            [[ $command == "w" && $write_flag -ne $newvalue ]] && { echo "error: Please set value and write command together" >&2; exit 1; }
            [[ -f "$BATOCERA_CONFIGFILE" ]] || { echo "not found: $BATOCERA_CONFIGFILE" >&2; exit 2; }
            [[ $extend_flag -eq 1 ]] && build_key
            processing
            exit $?
    fi
}

function processing() {
    # value processing, switch case
    case "${command}" in

        "read"|"get"|"load"|"r")
            val="$(get_config "$keyvalue")"
            ret=$?
            [[ "$val" == "$COMMENT_CHAR" ]] && return 11
            [[ -z "$val" && $ret -eq 0 ]] && return 10
            [[ -z "$val" && $ret -eq 1 ]] && return 12
            [[ -n "$val" ]] && echo "$val" && return 0
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
            return 0
        ;;

        "set"|"write"|"save"|"w")
            #Is file write protected?
            [[ -w "$BATOCERA_CONFIGFILE" ]] || { echo "r/o file: $BATOCERA_CONFIGFILE" >&2; return 2; }
            #We can comment line above to erase keys, it's much saver to check if a value is setted
            [[ -z "$newvalue" ]] && echo "error: '$keyvalue' needs value to be setted" >&2 && return 1

            val="$(get_config $keyvalue)"
            ret=$?
            if [[ "$val" == "$COMMENT_CHAR" ]]; then
                echo "$keyvalue: hashed out!" >&2
                uncomment_config "$keyvalue"
                set_config "$keyvalue" "$newvalue"
                echo "$keyvalue: set from '$val' to '$newvalue'" >&2
                return 0
            elif [[ -z "$val" && $ret -eq 1 ]]; then
                echo "$keyvalue: not found!" >&2
                return 12
            elif [[ "$val" != "$newvalue" ]]; then
                set_config "$keyvalue" "$newvalue"
                return 0
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
                 echo "$keyvalue: not found!" && return 2
            fi
        ;;

        "comment"|"disable"|"remark")
            val="$(get_config $keyvalue)"
            ret=$?
            # Boolean
            [[ "$val" == "$COMMENT_CHAR" || "$val" == "0" ]] && exit 0
            if [[ -z "$val" && $ret -eq 1 ]]; then
                echo "$keyvalue: not found!" >&2 && return 12
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
            return 1
        ;;
    esac
}
##### MAIN FUNCTION #####

##### MAIN CALL #####

main "$@"

##### MAIN CALL #####
