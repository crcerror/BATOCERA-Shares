#!/bin/bash
#This script tries to create SAVEDIR entry from WINE-game selection
#cyperghost and his second live 14.03.2025

WINEGAMESDIR=/userdata/roms/windows
WINEPOINTDIR=/userdata/system/wine-bottles/windows
FILEXTENSION=".*\.\(pc\|wine\|wsquashfs\)"

#Function selectWindowsGame lets you choose from list and searches for games winepoint
#it spwawn following variables
WINEPOINTGAMEDIR=
WINEGAME=

selectWindowsGame(){
    local i cmd ret
    pushd "$WINEGAMESDIR" > /dev/null || { echo "Could not go open dir: $WINEGAMESDIR" >&2; return 1; }
    readarray -t i < <(find -maxdepth 1 -iregex "$FILEXTENSION" -printf '%f\n' | sort -n)
    [[ "${#i[@]}" -eq 0 ]] && { echo "Dir $WINEGAMESDIR is empty" >&2; return 1; }

    cmd=(dialog --stdout --backtitle "Batocera - WINE Simple Config" \
                --title "Step 1 - Select your game" --no-items \
                --menu "Please choose your game" 0 0 20)
    WINEGAME=$("${cmd[@]}" "${i[@]}")
    #Winepoint depends on file extension - do not blame me for that
    #it is batocera-wine that used it so
    case "${WINEGAME##*.}" in
        pc) WINEPOINTGAMEDIR=$(find "$WINEPOINTDIR" -name "${WINEGAME}.wine" -printf '%p\n') || { echo "Found no winepointdir for $WINEGAME in $WINEPOINTDIR" >&2; } ;;
      wine) WINEPOINTGAMEIDR="${WINEGAMESDIR}/${WINEGAME}" ;;
 wsquashfs) WINEPOINTGAMEDIR=$(find "$WINEPOINTDIR" -name "$WINEGAME" -printf '%p\n') || { echo "Found no winepointdir for $WINEGAME in $WINEPOINTDIR" >&2; } ;;        
    esac

    popd > /dev/null
    return $ret
}

wineDirSelection(){
    local ret=1 winepointpath=$1
    until [ $ret -eq 0 ]; do 
        SAVEDIR=$(dialog --stdout --title "Step 2 - Choose your SaveDir" \
                  --backtitle "BATOCERA - Wine Simple Config" \
                  --dselect "$winepointpath/drive_c/" 20 60); ret=$?
        #Prepare SAVEDIR
        SAVEDIR="${SAVEDIR/$winepointpath/}" #Strip winepointpath
        [[ "${SAVEDIR: -1}" == "/" ]] && SAVEDIR="${SAVEDIR:1:-1}" || SAVEDIR="${SAVEDIR:1}" #remove first and/or trailing slash
        [ $ret -eq 1 ] && return 1 || { dialog --title "Accept your choice?"  --yesno "Accept selected path:\n${SAVEDIR}" 20 60; }; ret=$?
    done
    return $ret
}

selectWindowsGame
wineDirSelection "${WINEPOINTGAMEDIR}" || { clear; echo "Aborted...."; exit 1; }
#This can be improved, check before and so on
echo "SAVEDIR=$SAVEDIR" >> "${WINEGAMESDIR}/${WINEGAME}/autorun.cmd"
echo "Written: ${WINEGAMESDIR}/${WINEGAME}/autorun.cmd"
