#!/bin/bash

# Whishlist to mimic batoceraSettings.py
# goal: abbolish this software, it's useless for the sake of the load feature only
#
# -command load/get save/set 
#           enable/activate disable/deactivate >> for boolean means 1 and 0
#                                              >> for others means comment uncomment
#           add/remove                         >> add and delete key
#
# -key what happens to load if key is deativated >> ask user, so he uses enable feature first
#      if key is not found output - "not found"
# -value should be easiest task
#

readonly BATOCERA_CONFIGFILE="/userdata/system/batocera.conf"
readonly COMMENT_CHAR="#"

function get_config() {
     local val
     val=$(grep -E -m1 ^$COMMENT_CHAR?\s*$1 $BATOCERA_CONFIGFILE) 
     [[ "${val:0:1}" == "$COMMENT_CHAR" ]] && return
     val="${val#*=}"
     echo "$val"
}

function set_config() {
     sed -i "s|^\(\s*$1\s*=\).*|\1$2|" "$BATOCERA_CONFIGFILE"
}

function rem_config() {
     sed -i "s|^$COMMENT_CHAR\(\s*$1\)|\1|" "$BATOCERA_CONFIGFILE"
}
