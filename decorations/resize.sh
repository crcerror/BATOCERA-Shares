#!/bin/bash
# This script resizes entries in info files
# all data written in ARRAY var will be processed
# other data is left untouched!
#
# pure bash for calculating
# so to set resolution down to factor 2.5 use factor 250
# First param=inputfile
# Second param=resize factor
# You will get a FILENAME_resized.info file
#
# by cyperghost - 2019/06/12

inputfile=$1
factor=$2
outputfile="${inputfile%.*}_resized.info"
[[ -z $factor ]] && echo "Input factor like 250 for 2.5" && exit
[[ -e "$inputfile" ]] && echo "Open file: $inputfile" || exit
[[ -e "$outputfile" ]] && echo "Resized file found --- removing!" && rm "$outputfile"

array=("width" "height" "top" "left" "bottom" "right")
while read line; do
    for i in ${array[@]}; do
        if [[ "$line" =~ "$i" ]]; then
            pixel=${line//[^[:digit:].]/}
            resize=$(($pixel*100/$factor))
            echo "${line//$pixel/$resize}" >> "$outputfile"
            z=1
        fi
    done
    [[ $z -eq 1 ]] && z=0 || echo "$line" >> "$outputfile"
done < <(tr -d '\r' < "$inputfile")
