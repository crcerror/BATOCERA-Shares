#!/bin/bash

# add 'global.retroarch.savestate_auto_load=true'
# to your batocera.conf
# by cyperghost aka lala for BATOCERA
# 
# download this script to '/userdata/system/scripts' and set executable bit
# 

rom_no_ext="$(basename "${5%.*}")"
sav_path="/userdata/saves/$2"

[[ "$(batocera-settings get global.autosave)" -eq 1 ]] && exit
[[ "$(batocera-settings get global.retroarch.savestate_auto_load)" == "true" ]] || exit

if [[ $1 == "gameStart" ]]; then
    file="$(/bin/ls "$sav_path/$rom_no_ext."* -turR1A | tail -1)"
    [[ -n "$file" ]] || exit
    [[ "${file##*.}" == "png" ]] && file="${file%.*}"
    [[ -f "$file" ]] || exit
    cp -f "$file" "$sav_path/$rom_no_ext.state.auto"
fi

if [[ $1 == "gameStop" ]]; then
    rm -f  "$sav_path/$rom_no_ext.state.auto"
fi
