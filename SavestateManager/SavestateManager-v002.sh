#!/bin/bash
# cyperghost + lbrpdx
# List SaveStates for Selected ROM
# Output of PNG path if picture found

##### DEBUG
romfile="/userdata/roms/megadrive/Streets of Rage.bin"

# ----- Set variables ----
readonly rom_name="$(basename "$romfile")"
readonly rom_path="$(dirname "$romfile")"
readonly rom_no_ext="${rom_name%.*}"
readonly system="$(basename "$rom_path")"
readonly sav_path="/userdata/saves/$system"

### Maybe set here more?
### I've limitated to only first 10 savestates + SRM
search=".*$rom_no_ext\.\(srm\|state.auto\|state\|state.[1-9]\)"

#### DEBUG
echo "ROM-Name: $rom_name"
echo "ROM-Path: $rom_path"
echo "ROM-woEx: $rom_no_ext"
echo "System:   $system"
echo "SAVE-Loc: $sav_path"
echo "Search-T: $search"
echo

# Build Array
readarray -t saves_array < <(find "$sav_path" -type f -regex "$search")

# Array validity check!
if [[ ${#saves_array[@]} -eq 0 ]]; then
    echo "Yuck... No Savestates found!"
    sleep 3
    exit 1
fi

# Building Options array for dialog input
# Remeber: Threr might be some data in already (SRM!!)
echo "We have ${#saves_array[@]}" entries in array
for i in "${saves_array[@]}"; do
    echo "$i"
    echo "Slot: ${i##*.} $(date -r "$i" +'%t%Y-%m-%d %H:%M:%S')"
    [[ -f "${i%.*}.png" ]] && echo "${i%.*}.png" || echo "No Picture!"
    echo
done
