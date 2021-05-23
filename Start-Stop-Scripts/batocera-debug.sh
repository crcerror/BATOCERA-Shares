#!/bin/sh
# Debug Screen for Batocera aka RetroPie default splash
# Gives user information about used core and default errorlog
# cyperghost/crcerror aka lala 23.05.2021
#
# Thx for developing BATOCERA guys, only cores that matters

[ "$1" = "gameStop" ] && { clear > /dev/tty1; exit 0; }

# --- MAIN ---
text="\n
Launching:  $5\n\n
Using core: $4\n\n
System:     $2\n\n
Errors are logged to '$HOME/logs/es_launch_stderr.log'
"

/usr/bin/openvt -c1 -f -s -w -- dialog --title " BATOCERA-DEBUG " --infobox "$text" 10 75
sleep 3
