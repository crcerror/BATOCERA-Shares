#!/bin/bash
# Tested and designed for Bato 40/41
# Just Install one Wine-Application and let it create the default directory
# Go to: /userdata/system/wine-bottles/windows/wine-tkg
# Reanme a directory: /userdata/system/wine-bottles/windows/xyz.pc.wine to default-settings 
# by cyperghost 01/2025
wine_bottle_dir=/userdata/system/wine-bottles/windows/wine-tkg
wine_stores_dir=/userdata/roms/windows

# Check if default-settings directory is available
if [ -d "${wine_bottle_dir}/default-settings" ];
then
    echo "Dir: 'default-settings' found in ${wine_bottle_dir}!"
    echo "Proceed!"
else
    echo "Error: 'default-settings' not found!"
    echo "Go to: ${wine_bottle_dir} and reaname for ex.: Game.pc.wine to default-settings"
    exit 1
fi

#Go to WINE-Directory where games are stored and create array there
pushd "$wine_stores_dir"
readarray -t WINE_GAMES < <(find -maxdepth 1 -iregex ".*\.\(iso\|pc\|sqashfs\)" -printf '%f\n')
popd &>/dev/null
games_in_dir=${#WINE_GAMES[@]}

#Now go to WINE-Prefix-dir and look for .pc.wine extensions
pushd "$wine_bottle_dir"
readarray -t WINE_PREFIXES < <(find -maxdepth 1 -name "*.wine" -printf '%f\n')
prefixes_in_dir=${#WINE_PREFIXES[@]}

#We are looping throuh our WINE_GAMES cataloque, checking for already setted
#symlinks or directories and set symlinks to default-settings dir
no_do=0
for DIR in "${WINE_GAMES[@]}"; do
  DIR="${DIR}.wine"
  if [ -L "$DIR" ]; then
    echo "Symlink2Game already present: $DIR"
  elif [ -d "$DIR" ]; then
    #remove WINE Prefix for specfic game
    rm -f -r "$DIR" && echo "Removing: $DIR" || { echo "Error! rm $DIR"; break; }
    #Add Symlink for removed directory
    ln -s default-settings "$DIR" && echo "Symlink: default-settings -> $DIR" && let no_do++ || echo "Symlink failed: $DIR"
  else
    #Add Symlink for new added games
    ln -s default-settings "$DIR" && echo "Symlink: default-settings -> $DIR" && let no_do++ || echo "Symlink failed: $DIR"
  fi

  #Clean Up array for WINE_PREFIXES, if current WINE_GAMES.wine
  #Matches any entry in WINE_PREFIXES
  for PREFIX in "${!WINE_PREFIXES[@]}"; do
    [[ "${WINE_PREFIXES[$PREFIX]}" == "$DIR" ]] && unset WINE_PREFIXES[$PREFIX]
  done
done

#Clean Up stage
echo "Finished Symlinking!"
[ $no_do -eq 0 ] && echo "Nothing done....!" || echo "${no_do} new links created....!"
echo
no_do=${#WINE_PREFIXES[@]}
echo "Now cleaning.... "
echo "Compare arrays: Prefix holds ${no_do} elements missing in WINE-GAMES"
for PREFIX in "${WINE_PREFIXES[@]}"; do
    echo "Removing: ${PREFIX}"
    rm -f -r "${PREFIX}"
done
popd &>/dev/null
echo "Finished Cleaning!"
echo
echo "Detected Games in WINE: ${games_in_dir} -> ${wine_stores_dir}"
echo "Detected WINE Prefixes: ${prefixes_in_dir} -> ${wine_bottle_dir}"
echo "Removed Prefixes: ${no_do}"
echo "Finished all!"
