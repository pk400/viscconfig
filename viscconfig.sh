#! /bin/bash

# Author: Joel Aro
# Description: This script installs a fresh copy of Viscosity.


# Declare some variables that need to be accessed from functions as well
ALL_FILES=(
	~/Library/Preferences/com.viscosityvpn.Viscosity.plist
	~/Library/Application\ Support/Viscosity/*
)

# Kill all processes related to Viscosity ie. ViscosityHelper. This is so that
# the files can easily be removed for a clean install
kill_p() {
	LISTP=$(ps -axco command | sort | uniq)
	for p in $@
	do
		ISRUNNING=$(echo "$LISTP" | grep -w $p | wc -l)
		[ $ISRUNNING -gt 0 ] && killall $p && echo "Killing $p ..."
	done
}

# Removes all related process files and their directories
remove_path() for p in "$@"; do rm -rf "$p"; done

# Closes all open instances of Viscosity and removes related files/directories
# to ensure a fresh install
wipe_viscosity() {
	echo "Clearing previous Viscosity data ..."
	kill_p Viscosity com.sparklabs.ViscosityHelper

	defaults delete com.viscosityvpn.Viscosity 2> /dev/null \
	&& echo "Viscosity reset defaults successful"
	
	launchctl unload ${ALL_FILES[1]} 2> /dev/null
	
	# These files/directories need to be checked first if they exist!
	remove_path "${ALL_FILES[@]}"
}

# Ensures that all commands throughout the program have the proper admin privileges
[ $(id -u) -ne 0 ] && echo "Try again with sudo." && exit 1

# User will run the script with the intention to have a fresh install
wipe_viscosity

# Remove old Viscosity
rm -rf /Applications/Viscosity.app/ 2> /dev/null

# Install new one
cp -r Viscosity.app /Applications/ 2> /dev/null

echo "Clean install completed!"