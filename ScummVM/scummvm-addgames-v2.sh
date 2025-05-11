#!/bin/bash
# script is taken from knulli - https://github.com/knulli-cfw
# some minor improvements // 10.04.2025 - crcerror
# puplish as v2 with some nice tweaks // 09.05.2025 - crcerror

# ScummVM ini file locations
LIBRETRO_SCUMMVM_INI="/userdata/bios/scummvm.ini"
STANDALONE_SCUMMVM_INI="/userdata/system/configs/scummvm/scummvm.ini"
RANDOM_SCUMMVM_INI="/tmp/scummvm_$(shuf -er -n6 {A..Z} {a..z} {0..9} | tr -d '\n').ini"

if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage to single add a game:"
    echo "       $0 /userdata/roms/scummvm/<game> {auto|standalone|libretro|random}";echo
    exit 1
fi

# Set local display
LOCALDISPLAY=$(getLocalXDisplay) || { echo "setting export DISPLAY failed!"; exit 1; }
export DISPLAY=${LOCALDISPLAY}

# Create files and folders if not found
if ! [[ -f "$LIBRETRO_SCUMMVM_INI" && -f "$STANDALONE_SCUMMVM_INI" ]]; then
  mkdir -p "$(dirname "$LIBRETRO_SCUMMVM_INI")" "$(dirname "$STANDALONE_SCUMMVM_INI")"
fi

# Get real/full path otherwise scummvm-libretro will not work
GAME_FOLDER=$(realpath -s "$1")

if [[ ! -d "$GAME_FOLDER" ]]; then
    echo "$GAME_FOLDER does not exist. Aborting."
    exit 1
elif [[ -z "$(ls -A "$GAME_FOLDER")" ]]; then
    echo "Directory $GAME_FOLDER is empty. Nothing to do here."
    exit 1
elif ls "$GAME_FOLDER"/*.scummvm 1> /dev/null 2>&1; then
    echo "Directory $GAME_FOLDER already has a scummvm file. Nothing to do here."
    exit 1
fi

echo "$GAME_FOLDER has no ScummVM file, yet - attempting game detection."

case ${2,,} in
    auto|standalone)
        SCUMMVM_INI="${STANDALONE_SCUMMVM_INI}"
    ;;
    libretro)
        SCUMMVM_INI="${STANDALONE_SCUMMVM_INI}"
    ;;
    random)
        SCUMMVM_INI="${RANDOM_SCUMMVM_INI}"
    ;;
    *)
        echo "unknowen parameter used"
        exit 1
esac

touch "${SCUMMVM_INI}"
ADDING_GAME_LOG="$(scummvm -c "$SCUMMVM_INI" -p "$GAME_FOLDER" -a)"
GAME_HANDLES_RAW="$(sed -En "s/[ ]*Target:[ ]*(.*)/\1/p" <<< $ADDING_GAME_LOG)"
GAME_NAMES_RAW="$(sed -En "s/[ ]*Name:[ ]*(.*)/\1/p" <<< $ADDING_GAME_LOG)"

if [[ -z "$GAME_HANDLES_RAW" ]]; then
    echo "No new ScummVM game found in $GAME_FOLDER - aborting."
    exit 1
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
