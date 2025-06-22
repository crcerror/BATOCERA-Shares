#!/bin/bash
# change script on the fly by crcerror 22.06.2025

es_settingsFile="/userdata/system/configs/emulationstation/es_settings.cfg"
currentTheme=$(grep ThemeSet "${es_settingsFile}" | awk -F'"' '{print $4}')

# check if currentTheme value is valid
# stop ES right now

# Set your theme here
newTheme="es-theme-carbon"

# Write new theme
sed "s/${currentTheme}/${newTheme}/g" "${es_settingsFile}"

# start ES right now
