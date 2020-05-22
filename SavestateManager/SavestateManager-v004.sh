#!/bin/bash
# cyperghost + lbrpdx
# List SaveStates for Selected ROM
# Added XML output - v004

#### Todo:
## add help item
## shift item
## use more function calls

##### DEBUG
romfile="/userdata/roms/megadrive/Streets of Rage.bin"

# ----- Set variables ----
readonly rom_name="$(basename "$romfile")"
readonly rom_path="$(dirname "$romfile")"
readonly rom_no_ext="${rom_name%.*}"
readonly system="$(basename "$rom_path")"
readonly sav_path="/userdata/saves/$system"

### Maybe set here more?
### I've limitated to only first 10 savestates + SRM
### Added 99 savestates, maybe we reduce later
###
search=".*$rom_no_ext\.\(srm\|state.auto\|state\|state.[1-9]\|state.[1-9][0-9]\)"

#### DEBUG
echo "ROM-Name: $rom_name"
echo "ROM-Path: $rom_path"
echo "ROM-woEx: $rom_no_ext"
echo "System:   $system"
echo "SAVE-Loc: $sav_path"
echo "Search-T: $search"
echo

function xml_head()
{
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    echo "<savestates>"
    echo "  <all_entries>"$1"</all_entries>"
}

function xml_error()
{
    echo "  <error>Yuck! No SaveStates found!</error>"
}

function xml_foot()
{
    echo "</savestates>"
}

function xml_body()
{
    # Argument list:
    #   1 path for state file
    #   2 slotname/slotnumber
    #   3 creation_day
    #   4 creation_time
    #   5 picture to file

    # We can change slotname, if needed
    # aka ... if slotname=SRM >>> battery save
    # or if SRM then use <SRM>path</SRM>
    echo "  <state_entry = \"$z\">"
    echo "    <state_path>"$1"</state_path>"
    echo "    <state_name>"$2"</state_name>"
    echo "    <state_date>"$3"</state_date>"
    echo "    <state_time>"$4"</state_time>"
    echo "    <state_pics>"$5"</state_pics>"
    echo "  </state_entry>"
}

#### MAIN #####

# Build Array
readarray -t saves_array < <(find "$sav_path" -type f -regex "$search")

# Array validity check!
if [[ ${#saves_array[@]} -eq 0 ]]; then
    #Building XML file
    xml_head "${#saves_array[@]}" > savestate.xml
    xml_error >> savestate.xml
    xml_foot >> savestate.xml
    exit 1
fi

case ${1,,} in
    list) #create xml list
        #Building XML file
        xml_head "${#saves_array[@]}" > savestate.xml
        echo "We have ${#saves_array[@]}" entries in array
        for i in "${saves_array[@]}"; do
            save_filepath="$i"
            slot_number="${i##*.}" 
            creation_day="$(date -r "$i" +'%Y-%m-%d')"
            creation_time="$(date -r "$i" +'%H:%M:%S')"
            if [[ -f "$i.png" ]]
            then
                picture_filepath="${i%.*}.png"
            else
                picture_filepath=""
            fi
            #### BUILD XML file
            ((z++)) #counter
            xml_body "$save_filepath" "$slot_number" "$creation_day" "$creation_time" "$picture_filepath" >> savestate.xml
        done
        xml_foot >> savestate.xml
    ;;
    delete) #delete savestate and png...shift array, then delete array ... FC
        ### Give full array? then for in in "$[@]"... rm -f
        echo "Delete $2"
        # File PNG avail?
        echo "Delete $2.png"
    ;;
    reorder) #sort savegames, rename png too
        search=".*$rom_no_ext\.\(state\|state.[1-9]\|state.[1-9][0-9]\)"
        readarray -t saves_array < <(find "$sav_path" -type f -regex "$search" | sort -V)

        z=0
        file="$sav_path/$rom_no_ext.state"

        while [[ $z -lt ${#saves_array[@]} ]]
        do
            if [[ -f "$file" ]]; then
                echo "File found: ${saves_array[$z]} - skipping"
            else
                echo "rename ${saves_array[$z]} --> $file"
                [[ -f "${saves_array[$z]}.png" ]] && echo "rename ${saves_array[$z]}.png --> $file.png"
            fi
            ((z++))
            file="$sav_path/$rom_no_ext.state.$z"
        done
    ;;
esac

