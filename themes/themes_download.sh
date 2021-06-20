#!/bin/bash 
#
# Download and install EmulationStation themes for Batocera
#
# @lbrpdx on Batocera Forums and Discord
# @cyperghost aka lala on Discord
#
# Usage:
# batocera-es-theme 'list' or 'install <theme>' 
# 
# If you don't provide a <theme>, the list of themes available online will be returned back to you
#
THEMESDIR="/userdata/themes"
THEMESLIST="https://updates.batocera.org/themes.txt"
LOCALTHEMESLIST="/userdata/system/themes.txt"
# themes.txt must be a plain file with the format 'theme_name https://githubURL size checksum' (spaces or tabs)
# Example of a themes.txt file: 
#  fundamental	https://github.com/jdorigao/es-theme-fundamental
#  Zoid		https://github.com/RetroPie/es-theme-zoid

###############################
#
function usage() {
    cat <<-_EOF_
		$(basename $0) - downloads and installs EmulationStation themes for Batocera

		It accepts two modes: 'list' and 'install <theme>'
		  - 'list' for the list of themes available online, and if they are
		    [A]vailable to install, [I]nstalled or [?]unknown.
		  - 'install <theme>' to install the theme, from its theme name.
		  - 'remove <theme>' to delete an installed theme.

		Furthermore: 'checkup' in SSH only
		  - 'checkup <theme>' will calculate md5sum of first 100kB chunk
		    if there is a checksum available, it will be recalculated
		    and filesize of theme will be added to list.
		  - 'checkup all' will behave like the single command but for all listed themes.
		!! THIS WORKS ONLY WITH LOCAL $(basename $LOCALTHEMESLIST) file !!

		If you have a local $LOCALTHEMESLIST file,
		it will override the one hosted on Batocera website.
		_EOF_
    exit 1
}

###############################
#
function check_url() {
    [[ "$1" =~ ^(https?|ftp)://.*$ ]] && echo "[A]" || echo "[?]"
}

###############################
#
function git_name() {
    echo "$1" | sed "s,.*/\(.*\),\1,"
}

###############################
#
function repo_name() {
    echo "$1" | sed "s,.*github.com/\([A-Za-z0-9_-]*\)/.*,\1,"
}

###############################
#
function get_md5chunk() {
    local file="$1"

    ( ulimit -f 100
      wget "$file" -O /tmp/theme_md5chunk 2>/dev/null
      ulimit -f unlimited ) 2>/dev/null

    echo $(md5sum /tmp/theme_md5chunk | awk '{print $1}')
    rm /tmp/theme_md5chunk
}

###############################
#
function build_array() {
    fn=$(date +"%s")
    tmp="/tmp/themes_$fn"
    if [ -f $LOCALTHEMESLIST ]; then
        cp -f "$LOCALTHEMESLIST" "$tmp"
    else
        curl -sfL "$THEMESLIST" -o "$tmp" || exit 1
    fi
    while IFS=$' \t' read name url fsize md5chunk date_dy; do
        array+=("$name" "$url" "$size" "$md5chunk" "$date_dy")
    done < "$tmp"
    rm "$tmp"
    ARRAY_SIZE=$((${#array[@]}-1))
}

###############################
#
function list_themes() {
    build_array
    local url name fsize
    local ia gitname
    for i in $(seq 0 5 $ARRAY_SIZE)
    do
        name="${array[i]}"
        [ -z "$name" ] && continue 
        url="${array[i+1]}"
        fsize="${array[i+2]}"
        ia=$(check_url "$url")
        gitname=$(git_name "$url")
        [ -d "$THEMESDIR"/"$gitname" ] && ia="[I]"
        if [ -n "$fsize" ]; then
            fsize=$((fsize/1024/1024))
            echo "$ia $name - $url - $fsize MB"
        else
            echo "$ia $name - $url"
        fi
    done
}

###############################
#
function check_themes() {
    build_array
    local theme="$1"
    local url name fsize md5chunk 
    local ia gitname filezip md5chunk_t

    [ -z "$theme" ] && return 1

    for i in $(seq 0 5 $ARRAY_SIZE)
    do
        name="${array[i]}"
        if [ "$theme" != "all" ]; then
            [ "$name" != "$theme" ] && continue
        fi 

        url="${array[i+1]}"
        fsize="${array[i+2]}"
        md5chunk="${array[i+3]}"

        ia=$(check_url "$url")
        if [ "$ia" != "[A]" ]; then
            echo "Error - invalid theme URL $url"
            continue
        else
            reponame=$(repo_name "$url")
            gitname=$(git_name "$url")
            filezip="${url}/archive/master.zip"
        fi

        echo "Calculating first 100kB chunk from: $name"
        md5chunk_t=$(get_md5chunk "$filezip")

        if [ "$md5chunk_t" != "$md5chunk" ]; then
            echo "100kB md5 chunk are not equal!"
            echo "Downloading theme and counting size:"
            size=$(wget -q --show-progress "$filezip" -O - | wc -c)
            date_dy="$(date +%D)"
            sed -i "s~$name[ \t]*.*~$name $url $size $md5chunk_t $date_dy~" "$LOCALTHEMESLIST"

            echo "Name:      $name"
            echo "URL:       $url" 
            echo "Size:      $size" 
            echo "md5chunk:  $md5chunk_t"
            echo "Date:      $date_dy"
            echo "Written to $LOCALTHEMESLIST"
            echo
        else

            echo "100kB md5 chunk is the same as in local file!"
            echo "No Update done!"
            echo
        fi

    done
}
###############################
#
function getPer() {
    TARFILE="$1"
    TARVAL="$2"
    while true; do
        CURVAL=$(stat "$TARFILE" | grep -E '^[ ]*Size:' | sed -e s+'^[ ]*Size: \([0-9][0-9]*\) .*$'+'\1'+)
        CURVAL=$((CURVAL / 1024 / 1024))
        PER=$(expr ${CURVAL} '*' 100 / ${TARVAL})
        echo "[${TARVAL}MB] - ${theme^^} >>>${PER}"
        sleep 2
    done
}

###############################
#
function install_theme() {
    build_array
    local theme="$1"
    local url name fsize
    local ia gitname
    local success_installed=1

    [ -z "$theme" ] && return 1
    for i in $(seq 0 5 $ARRAY_SIZE)
    do
        name="${array[i]}"
        [ "$name" != "$theme" ] && continue || break
    done
        url="${array[i+1]}"
        fsize="${array[i+2]}"

        ia=$(check_url "$url")
        if [ "$ia" != "[A]" ]; then
            echo "Error - invalid theme URL $url"
            exit 1
        else
            reponame=$(repo_name "$url")
            gitname=$(git_name "$url")
            cd "$THEMESDIR"
            filezip="${url}/archive/master.zip"
            [ -f "gitname.zip" ] && rm -f "$gitname.zip"
            touch "$gitname.zip"

            case $TERMINAL in
                0)
                    getPer "$THEMESDIR"/"$gitname.zip" "$fsize" &
                    GETPERPID=$!
                    curl -sfL "$filezip" -o "$gitname.zip" || exit 1
                    kill -9 "${GETPERPID}" >/dev/null 2>/dev/null
                    GETPERPID=
                ;;
                1)
                    wget -q --show-progress "$filezip" -O "$gitname.zip" || exit 1
                ;;
            esac
        fi

        # Extraction Process
        if [ -f "$gitname.zip" ]; then
            [ -d "$THEMESDIR"/"$gitname" ] && rm -rf "$THEMESDIR"/"$gitname"
            zipdir=$(unzip -Z1 "$gitname.zip" | sed "s:\([a-zA-Z0-9\._-]*\)/.*:\1:g" | uniq | head -n1)

            case $TERMINAL in
                0)
                    files_inzip=$(unzip -l "$gitname.zip" | tail -1 | awk '{print $2}')
                    unzip "$gitname.zip" | awk '{perc=NR/'$files_inzip'*100} {printf "Unzipping '${theme^^}' >>>%0.f\n", perc}'
                ;;
                1)
                    echo -e "Unzipping $gitname to:\t$PWD"
                    unzip -q "$gitname.zip"
                ;;
            esac

            mv "$zipdir" "$gitname"
            rm "$gitname.zip"
            success_installed=0
        else
            echo "Error - $theme zip file could not be downloaded from $url"
            exit 1
        fi
return $success_installed 
}

###############################
#
function remove_theme() {
    success_removed=1
    build_array
    local theme="$1"
    local url name fsize md5chunk 
    local ia gitname filezip md5chunk_t

    [ -z "$theme" ] && return 1

    for i in $(seq 0 5 $ARRAY_SIZE)
    do
        name="${array[i]}"
        [ "$name" != "$theme" ] && continue
        gitname=$(git_name "$url")
        if [ -d "$THEMESDIR"/"$gitname" ]; then
            rm -rf "$THEMESDIR"/"$gitname" && success_removed=0
        else
            echo "Theme $theme doesn't appear to be in $THEMESDIR/$gitname"
        fi
    done
return $success_removed
}

#### Main loop
#
command="$1"
theme="$2"

#Started from Terminal/SSH (TERMINAL=1) or from ES (TERMINAL=0)
#ThemeDir available
[ -t 1 ] && TERMINAL=1 || TERMINAL=0
[ -d "$THEMESDIR" ] || { echo "Error - theme directory '$THEMESDIR' is not valid."; exit 1; }

case "$command" in
    list)
        list_themes
    ;;
    install)
        install_theme "$theme" || usage
        if [ $? -eq 0 ]; then
            [ $TERMINAL = 1 ] && echo -e "Theme $theme installed to:\t$PWD/$gitname"
            [ $TERMINAL = 0 ] && echo "Theme ${theme^^} is now installed >>>100"
            exit 0
        else
            echo "Error - theme $theme could not be found"
            exit 1
        fi
    ;;
    remove)
        remove_theme "$theme" || usage
        if [ $? -eq 0 ]; then
            echo "Theme $theme is now removed"
            exit 0
        else
            echo "Error - theme $theme could not be removed"
            exit 1
        fi

    ;;
    checkup)
        if [ -f "$LOCALTHEMESLIST" ]; then
            check_themes "$theme" || usage
        else
            echo "This will work only with local themelist"
            echo "Download local theme list with command:"
            echo "  wget $THEMESLIST -O $LOCALTHEMESLIST"
            echo "or create a local one"
            echo "Consider to remove the file later!"
        fi
    ;;

    *)
        usage
esac
 
