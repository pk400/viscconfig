#! /bin/bash

# Author: Joel Aro
# Description: This script installs/configures Viscosity to be used for 
# a Mozilla employee.


# Declare some variables that need to be accessed from functions as well
BASE_URL='https://www.sparklabs.com'
DL_PATH='/downloads/Viscosity.dmg'
DMG='Viscosity.dmg'
MOUNT_POINT='/Volumes/Viscosity'
PKG='moz_config.pkg'
ALL_FILES=(
	/Library/PrivilegedHelperTools/com.sparklabs.ViscosityHelper
	/Library/LaunchDaemons/com.sparklabs.ViscosityHelper.plist
	/Library/Application\ Support/Viscosity
	~/Library/Preferences/com.viscosityvpn.Viscosity.plist
)

# Kill all processes related to Viscosity ie. ViscosityHelper. This is so that
# the files can easily be removed for a clean install
kill_p() {
	LISTP=$(ps -axco command | sort | uniq)
	for p in $@
	do
		ISRUNNING=$(echo "$LISTP" | grep -w $p | wc -l)
		if [[ $ISRUNNING -gt 0 ]]; then killall $p && echo "Killing $p ..."; fi
	done
}

# Removes all related process files and their directories
remove_path()
	for p in "$@"; do [[ -f $p ]] && (rm -rf $p && echo "Deleting $p"); done

# Closes all open instances of Viscosity and removes related files/directories
# to ensure a fresh install
wipe_viscosity() {
	echo "Clearing previous Viscosity data ..."
	kill_p Viscosity com.sparklabs.ViscosityHelper

	defaults delete com.viscosityvpn.Viscosity 2> /dev/null \
	&& echo "Viscosity reset defaults successful"
	
	launchctl unload ${ALL_FILES[1]}
	
	# These files/directories need to be checked first if they exist!
	remove_path "${ALL_FILES[@]}"
}

# Ensures that all commands throughout the program have the proper admin privileges
if [[ $(id -u) -ne 0 ]]
then
	echo "Script needs admin privileges to run. Please try again with sudo."
	exit 1
fi

[[ ! -f $PKG ]] && (echo "Viscosity Installer.pkg not found."; exit 1)

# User will run the script with the intention to have a fresh install
wipe_viscosity

# Grab viscosity from Sparklabs website
if [ ! -f $DMG ]
then
	echo "Downloading Viscosity ..."
	wget --no-check-certificate -q $BASE_URL$DL_PATH
	[[ $? -ne 0 ]] && (echo "Could not fetch .dmg file"; exit 1)
fi

# Mounts .dmg file
echo "Installing Viscosity ..."
hdiutil attach $DMG > /dev/null
[[ $? -ne 0 ]] && (echo "Encountered a problem while mounting .dmg"; exit 1)

cp -rf $MOUNT_POINT/Viscosity.app /Applications

# Unmount
hdiutil detach $MOUNT_POINT > /dev/null
[[ $? -ne 0 ]] && (echo "Encountered a problem while unmounting .dmg"; exit 1)

rm $DMG

echo "Clean install completed!"

echo "Configuring Mozilla settings ..."
installer -pkg "$PKG" -target /

open -a /Applications/Viscosity.app/Contents/MacOS/Viscosity