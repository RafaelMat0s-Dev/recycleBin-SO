#!/bin/bash

#################################################
# Script Query Comment
# Author: Joao Miguel Padrao
# Date: 2025-10-18
# Description: Delete one ou many files
# Version: 1.0
#################################################

#################################################
# Function: search_recycle()
# Description: Delete a file by a unique ID or delete everything and give a confirmation before proceed (we can use the flag --force to dont make any confirmation)
# Parameters: This function has as paramter a file unique ID or the parameter 'all' or nothing to delete everything or the flag '--force' to skip confirmation, it run like "./recycle_bin.sh empty --force all" (for instance)
# Returns: 0 on success, 1 on failure (in case the file config doesn't exists or the ID doesn't mach with any of files or the user abort the process)
#################################################

# ============================================
# GLOBAL VARIABLES
# ============================================

RECYCLE_DIR="$HOME/.recycle_bin"
FILES_DIR="$RECYCLE_DIR/files"
METADATA_FILE="$RECYCLE_DIR/metadata.db"
LOG_FILE="$RECYCLE_DIR/recyclebin.log"

# ============================================
# LOG FUNCTION
# ============================================

log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

# ============================================
# EMPTY FUNCTION
# ============================================
function empty_recyclebin() {
	
	argument=$2
	#Check(in case we didn't use the flag --force)
	if [[ $1 != '--force' ]]; then
		echo -e "Permanently deleted files cannot be restore\nDo you wish to continue[Y/n]?"
		read -r answer
		argument=$1
		if [[ "${answer,,}" == "n" ]]; then
			echo "Abort process"
			return 1
		fi
	fi
	cd "$FILES_DIR" || { echo "[ERROR] Cannot enter $FILES_DIR"; return 1; }
	#Checking the arguments
	if [[ $# = 0 || $1 = "all" ]]; then
		#remove files
		for f in *; do
			rm -rf "$f"
			echo -e "$f deleted successfully!\n"
		done
		#clear the metadata.bd file
		> "$METADATA_FILE"
		#write on log file and make the return
		log "DELETE" "Successfully deleted all files"	
		return 0
	fi
	
	#force recursive remove específic ID_FILE
	file=$( grep "$argument" "$METADATA_FILE" | awk '{print $2}')
	if [[ -e "$file" ]]; then
		rm -rf "$file"
		echo -e "$file deleted sucefully!\n"
		#remove file in metadata file
		tmpfile=$(mktemp)
        	grep -F -v "$file" "$METADATA_FILE" > "$tmpfile" && mv "$tmpfile" "$METADATA_FILE"
		#write on log file and make the return
		log "DELETE" "Successfully deleted $file"
	else 
		echo "[WARN] File with ID $argument not found"
		return 1
	fi
	
	return 0
}
