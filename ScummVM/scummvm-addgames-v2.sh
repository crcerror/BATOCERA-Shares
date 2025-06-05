#!/bin/bash
# script is taken from knulli - https://github.com/knulli-cfw
# some minor improvements // 10.04.2025 - crcerror
# puplished as v2 with some nice tweaks // 09.05.2025 - crcerror
# Error Codes:
# 0  - everything went okay
# 1  - general error (missing parameters, wrong parameter
# 11 - game folder does not exist
# 12 - game folder is empty
# 13 - scummvm file found in gamedir
# 15 - scummvm.ini already contains gameID
# So it's up to YOU to handle this, please delete /tmp/scummvm.identifier after you used ma-random parameter for mass adding

if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage to single add a game:"
    echo "       $0 /userdata/roms/scummvm/<game> {auto|standalone|libretro|random|ma-random}";echo
    exit 1
fi

# Get real/full path otherwise scummvm-libretro will not work
GAME_FOLDER=$(realpath -s "$1")

# ScummVM ini file locations
case ${2,,} in
    auto|standalone)
        SCUMMVM_INI="/userdata/system/configs/scummvm/scummvm.ini"
    ;;
    libretro)
        SCUMMVM_INI="/userdata/bios/scummvm.ini"
    ;;
    random)
        SCUMMVM_INI="/tmp/scummvm_$(shuf -er -n6 {A..Z} {a..z} {0..9} | tr -d '\n').ini"
    ;;
    ma-random)
        if [[ -f /tmp/scummvm.identifier ]]; then
            SCUMMVM_INI=$(cat /tmp/scummvm.identifier)
        else
            SCUMMVM_INI=$(shuf -er -n6 {A..Z} {a..z} {0..9} | tr -d '\n')
            echo ${SCUMMVM_INI} > /tmp/scummvm.identifier
        fi
        SCUMMVM_INI="/tmp/scummvm_${SCUMMVM_INI}.ini"
    ;;

    *)
        echo "unknown parameter used, use auto, standalone, libretro, random, ma-random" 
        exit 1
esac

# Create files and folders if not found
[[ -f "$SCUMMVM_INI" ]] || { mkdir -p "$(dirname "$SCUMMVM_INI")"; touch "$SCUMMVM_INI"; } 

# Set local display
LOCALDISPLAY=$(getLocalXDisplay) || { echo "setting export DISPLAY failed!"; exit 1; }
export DISPLAY=${LOCALDISPLAY}

# spit out exit codes 11 - game folder does not exist, 12 - game folder is empty, 13 - scummvm file found, 15 - scummvm.ini already contains gameID
if [[ ! -d "$GAME_FOLDER" ]]; then
    echo "$GAME_FOLDER does not exist. Aborting."
    exit 11
elif [[ -z "$(ls -A "$GAME_FOLDER")" ]]; then
    echo "Directory $GAME_FOLDER is empty. Nothing to do here."
    exit 12
elif ls "$GAME_FOLDER"/*.scummvm 1> /dev/null 2>&1; then
    echo "Directory $GAME_FOLDER already has a scummvm file. Nothing to do here."
    exit 13
fi

echo "$GAME_FOLDER has no ScummVM file, yet - attempting game detection."

ADDING_GAME_LOG="$(scummvm -c "$SCUMMVM_INI" -p "$GAME_FOLDER" -a)"
GAME_HANDLES_RAW="$(sed -En "s/[ ]*Target:[ ]*(.*)/\1/p" <<< $ADDING_GAME_LOG)"
GAME_NAMES_RAW="$(sed -En "s/[ ]*Name:[ ]*(.*)/\1/p" <<< $ADDING_GAME_LOG)"

if [[ -z "$GAME_HANDLES_RAW" ]]; then
    echo "No new ScummVM game found in $GAME_FOLDER - aborting."
    exit 15
fi

# Transform raw data into arrays (there could've been more than one game in this folder!)
IFS=$'\n' GAME_HANDLES=($GAME_HANDLES_RAW)
IFS=$'\n' GAME_NAMES=($GAME_NAMES_RAW)

for INDEX in "${!GAME_HANDLES[@]}"
do
    CURRENT_GAME_HANDLE=${GAME_HANDLES[$INDEX]}
    CURRENT_GAME_NAME=${GAME_NAMES[$INDEX]}

    # Sanitize name to be used as scummvm file name
    SANITIZED_GAME_NAME="$(sed -e "s/[^()A-Za-z0-9 ._-]/ /g" <<< $CURRENT_GAME_NAME)"

    echo "Detected $CURRENT_GAME_NAME in $GAME_FOLDER and added the game as $CURRENT_GAME_HANDLE"

    # Create *.scummvm file for EmulationStation
    echo "$CURRENT_GAME_HANDLE" > "$GAME_FOLDER/$SANITIZED_GAME_NAME.scummvm"
    echo "Created $GAME_FOLDER/$SANITIZED_GAME_NAME.scummvm"

done

echo "Used: ${SCUMMVM_INI}"
exit 0
