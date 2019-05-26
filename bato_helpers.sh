#!/bin/bash
#
# This script provides some BATOCERA funtions that can be included into your
# script by using the "source $HOME/scripts/bato_helpers.sh` command
#
# 

# v 0.01 - 2019/05/26 crcerror
#
# Not for usage in BATOCERA prior to 5.21 

# Path to configfile to edit
BATO_CONFIGFILE="$HOME/batocera.conf"

# script to read and set keys
# Usage: $BATO_SYSTEMSETTINGS -command [COMMAND] -key [KEY] -value [VALUE]
#  -h, --help        show this help message and exit
#  -command COMMAND  load, save or disable
#  -key KEY          key to load
#  -value VALUE      if command = save value to save
BATO_SYSTEMSETTING="python /usr/lib/python2.7/site-packages/configgen/settings/batoceraSettings.py"

# Inline editor to commen some values, Comment sign is #
# Usage:
# BATO_SYSTEMSETTING_COMMENT [KEY] - Disable KEY in $BATOCERA_CONFIGFILE.
# BATO_SYSTEMSETTING_UNCOMMENT [KEY] - Enable KEY in $BATOCERA_CONFIGFILE 
#
####
####
#### TODO: AUTOFUNCTION to toggle COMMENT/UNCOMMENT
#### MAYBE whole funtion block unneeded if python script will offers those commands
#### NEED IMPROVMENTS: Set precheck with grep command, output result to stdout

function BATO_SYSTEMSETTING_COMMENT() {
    local COMMENT="#${1}"
    sed -i "s|^\s*$1|$COMMENT|" "$BATO_CONFIGFILE"
}

function BATO_SYSTEMSETTING_UNCOMMENT() {
    local COMMENT="#${1}"
    sed -i "s|^\s*$COMMENT|$1|" "$BATO_CONFIGFILE"
}
