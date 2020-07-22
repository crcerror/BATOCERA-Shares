#!/bin/bash
for i in "videofile1.mp4" "video file 2.mp4"
do
    [ -e "$i" ] || continue
    vl=$(ffmpeg -i "$i" 2>&1 | grep -m1 Duration)
    ret=$?
    vl=$(echo "$vl" | awk '{print substr($2,7,length($2)-10)}')
    if [ $ret -eq 0 ]
    then
        echo $vl
    fi
done
