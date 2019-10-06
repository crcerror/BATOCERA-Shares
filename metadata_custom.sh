#!/bin/bash

#custom.sh place in /userdata/system
#arguments are from /etc/init.d/S99custom
#this code is property of cyperghost aka crcerror
#don't distribute and respect the work of others!

case $1 in

    start) 
    ;;
    stop)
        #Save Shutdown to save metadata
        #After 20 seconds loop will force break
        
        es_pid=$(pidof emulationstation)
        
        #Assume that es_pid is already empty by menu shutdown
        #if you forced shutdown by a button press then this help you
        #to proper exit emulationstation and save your metadata
        if [[ -n $es_pid ]]; then                  #Assume button press or menu shutdown
            kill $es_pid
            sleep 0.5                              #Sleep timer to maybe avoid the while loop
            
            while [[ -e /proc/$es_pid ]]; do       #Loop as long as PID from ES is detected
                sleep 0.5
                
                #Now comes the cool part ;)
                #A Watchdog not counting up, I've setted a sleep timer in background and 
                #watch it's PID - this is very flexible and acts as timeout
                if [[ -n $watchdog ]]; then
                    [[ -e /proc/$watchdog ]] || break
                else
                    sleep 20 &
                    watchdog=$!
                fi
            done
        fi 
    ;;
    *)
        echo "Usage: /etc/init/S99custom {start|stop}"
    ;;

esac

