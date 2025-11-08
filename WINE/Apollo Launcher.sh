#!/bin/bash
#Apollo Launcher - cyperghost aka crcerror 03/2025
#Done in Favour to have a simple UI to navigate through python and shell scripts
#For shell files use artemis as file extension, for python use asklepios
#This isn't needed but will help to get a clean Gamelist
#laucnher file is created in /tmp to just keep maintainence for the script more easy

#v1.0 - 27.03.2025 - happy birthday dear brother

LAUNCHER=/tmp/launcher.artemis
SEARCHMASK=".*\.\(bash\|artemis\|py\|asklepios\)"
SEARCHPATH="/userdata/roms/ports"

createArtemis(){
  cat -v <<-___EOF > "$LAUNCHER"
	#Artemis-Launcher by cyperghost aka crcerror 03/2025
	readarray -t i < <(find "$SEARCHPATH" -iregex "$SEARCHMASK" -printf '%p\n')
        [[ "\${#i[@]}" -eq 0 ]] && { echo "No files found in $SEARCHPATH!" >&2; exit 0; }
        for file in "\${i[@]}"; do
          let ii++
	  #Enumerate and strip SEARCHPATH to show subdirs
	  array+=("\$ii" "\${file/"$SEARCHPATH/"}")
	done

	#Create Dialog
	cmd=(dialog --backtitle "Batocera: Apollo Launcher" --stdout \
             --title " Artemis & Asklepios " 
             --menu "Select module to launch:" 0 0 0)
	ii=\$("\${cmd[@]}" "\${array[@]}")
        ret=\$?
        [[ \$ret -eq 0 ]] || exit \$ret
        file="\${i[\$ii-1]}"

	#Selection between shell and python scripts
        i="\${file##*.}"   #Fileextenstion for case selection, how file launch is handled
	case "\${i,,}" in
	  py|asklepios)  /usr/bin/python3 "\$file" ;;
          bash|artemis)  /bin/bash "\$file" ;;
          *)             echo "\$i: is not an supported extension" >&2; exit 1
	esac   
___EOF
  return $?
}

[[ -e "${LAUNCHER}" ]] || { createArtemis || exit 1; }

#Start virtual terminal session, -s switch to it and -w wait till it is finished
#If you are in Terminal/SSH then directly launch 
if [ -t 1 ]; then
  bash "${LAUNCHER}"
else
  ld=$(getLocalXDisplay)
  [[ -z "$ld" ]] && { /usr/bin/openvt -s -w -- bash "$LAUNCHER"; }
  [[ -n "$ld" ]] && { DISPLAY=$ld xterm -fs 18 -bg blue -maximized  -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=$ld bash "$LAUNCHER""; }
fi
exit $?
