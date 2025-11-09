#!/bin/bash
# Create WR_ARRAY, it creates a list exactly mimics the filelist from system WinePrefixes
# wine-runner is taken according batocera.conf, if no entry is found then fallbacl to wine-tkg
while read i; do
  WR=$(batocera-settings-get "$(printf 'windows[\"%s\"].wine-runner' "$i")" || echo wine-tkg)
  WR_ARRAY+=("./$WR/$i.wine")
done < <(find /userdata/roms/windows -maxdepth 1 -type d -printf '%P\n')

# List of WinePrefixes with ./<runner>/<wineprefix>.wine
# max- and mindepth 2 and print path, we avoid to list our dir default-prefix
pushd /userdata/system/wine-bottles/windows/ >/dev/null
readarray -t WR_SYS < <(find . -mindepth 2 -maxdepth 2 ! -name default-settings -printf '%p\n')
popd >/dev/null

echo "Found ${#WR_SYS[@]} entries in wine-bottles"
echo "Found ${#a[@]} games in roms"
echo "${#WR_ARRAY[@]}"

# get sorted compare output from file2 so you see unused WinePrefixes
readarray -t WR_ARRAY < <(comm -23 <(printf '%s\n' "${WR_SYS[@]}" | sort ) <(printf '%s\n' "${WR_ARRAY[@]}" | sort ))
echo ${#WR_ARRAY[@]}

# compare both arrays again and the result if file is found it is found in annother column
# awk look if entries starts with a . -> print col 1, if not print col 3 from there push to dialog
readarray -t WR_ARRAY < <(comm <(printf '%s\n' "${WR_SYS[@]}" | sort ) <(printf '%s\n' "${WR_ARRAY[@]}" | sort ) | awk -F'\t' '{ if ($1 ~ /^./) { print $1; print "OFF" } else { print $3; print "ON" }; }')
cmd=$(dialog --stdout --no-items --checklist "check that" 0 0 0 "${WR_ARRAY[@]#*\/}")
echo "${#cmd[@]}"
