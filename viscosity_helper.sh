#! /bin/bash

# Author: Joel Aro
# Description: This script installs/configures Viscosity to be used for 
# a Mozilla employee.


# Declare some variables that need to be accessed from functions as well
BASE_URL='https://www.sparklabs.com'
DL_PATH='/downloads/Viscosity.dmg'
DMG='Viscosity.dmg'
MOUNT_POINT='/Volumes/Viscosity'
CON_CONFIG='config.conf'

# Kill all processes related to Viscosity ie. ViscosityHelper. This is so that
# the files can easily be removed for a clean install
kill_p() {
	LISTP=$(ps -axco command | sort | uniq)
	for p in $@
	do
		ISRUNNING=$(echo "$LISTP" | grep -w $p | wc -l)
		if [[ $ISRUNNING -gt 0 ]]; then killall $p; echo "Killing $p ..."; fi
	done
}

# Removes all related process files and their directories
remove_path() {
	for p in $@
	do
		rm -rf $p
	echo "Deleted $p"
	done
}

# Closes all open instances of Viscosity and removes related files/directories
# to ensure a fresh install
wipe_viscosity() {
	echo "Uninstalling Viscosity ..."
	kill_p Viscosity com.sparklabs.ViscosityHelper

	defaults delete com.viscosityvpn.Viscosity 2> /dev/null
	[[ $? = 0 ]] && echo "Viscosity reset defaults successful" \
	|| echo "Viscosity reset defaults unsuccessful"
	
	VHELP_PLIST="/Library/LaunchDaemons/com.sparklabs.ViscosityHelper.plist"
	if [ -f $VHELP_PLIST ]
	then
		launchctl unload $VHELP_PLIST 2> /dev/null
	fi
	
	# These files/directories need to be checked first if they exist!
	remove_path "~/Library/PrivilegedHelperTools/com.sparklabs.ViscosityHelper" \
	"~Library/LaunchDaemons/com.sparklabs.ViscosityHelper.plist" \
	"~/Library/Application Support/Viscosity"
}

# Ensures that all commands throughout the program have the proper admin privileges
if [[ $(id -u) -ne 0 ]]
then
	echo "Script needs admin privileges to run. Please try again with sudo."
	exit 1
fi

if [[ ! -f $CON_CONFIG ]]
then
	echo "Config file not found. Please download the ovpn-config .zip file from "\
	"login.mozilla.com and copy the config.conf file to the script's directory."
	exit 1
fi

# User will run the script with the intention to have a fresh install
wipe_viscosity

# Grab viscosity from Sparklabs website
if [[ ! -f $DMG ]]
then
	wget --no-check-certificate -q $BASE_URL$DL_PATH
	if [[ $? -ne 0 ]]; then echo "Could not fetch .dmg file"; exit 1; fi
fi

# Mounts .dmg file
hdiutil attach $DMG > /dev/null
if [[ $? -ne 0 ]]; then echo "Encountered a problem while mounting .dmg"; exit 1; fi

cp -rf $MOUNT_POINT/Viscosity.app /Applications

# Unmount
hdiutil detach $MOUNT_POINT > /dev/null
if [[ $? -ne 0 ]]; then echo "Encountered a problem while unmounting .dmg"; exit 1; fi

rm $DMG

echo "Clean install completed!"
echo "Starting up Viscosity..."

/Applications/Viscosity.app/Contents/MacOS/Viscosity &