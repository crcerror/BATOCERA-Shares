#!/bin/bash
# Script by cyperghost - Please resepect the work of others!
#

mkdir resize
for i in *.info; do
    # Call every info file with script parameter to reduce size
    # Usage: 
    #   info file to resize
    #   Resize factor (calculation is done [pixel in info file]*100/[factor]
    ./resize.sh $i 240

    # Set fix factor for picture height (needed for DSI RPi)
    sed -i 's|height\":450|height\":480|' "${i%.*}_resized.info"

    # Set 3 spaces (to look like original file, for cosmetics)
    sed -i 's|\"|   \"|' "${i%.*}_resized.info"
    
    # As default info files won't get overwritten and a new file _resize is formed
    mv "${i%.*}_resized.info" "./resize/$i"
    
    # Create PNG files, pointig to default systems
    # echo "../../default/systems/${i%.*}.png" > "./resize/${i%.*}.png"
    
    # Create symlinks because descriptive png files seems to be broken!
    ln -s "../../default/systems/${i%.*}.png" "./resize/${i%.*}.png"
done
