#!/bin/bash
# Read Pads
file=pads2.txt
readarray -t arr <<< "$(grep \<inputConfig.* $file | awk -F '"' '{print $6,$4}')"
unset arr[0] #delete keyboard, because value of -1

for i in "${arr[@]}"; do
    gid="${i%% *}"
    pad="${i#* }"
    if [[ $(grep -c $gid "$file") -gt 1 ]]; then
        echo "$gid; $pad;" >> pads.csv
    fi
done

echo "${#arr[@]}"