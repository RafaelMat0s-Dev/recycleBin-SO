#!/bin/bash

#################################################
# Script Query Comment
# Author: Joao Miguel Padrao
# Date: 2025-10-18
# Description: Delete one ou many files
# Version: 1.0
#################################################

#################################################
# Function: empty_recyclebin()
# Description: Delete a file by a unique ID or delete everything and give a confirmation before proceed (we can use the flag --force to dont make any confirmation)
# Parameters: This function has as paramter a file unique ID or the parameter 'all' or nothing to delete everything or the flag '--force' to skip confirmation, it run like "./recycle_bin.sh empty --force all" (for instance)
# Returns: 0 on success, 1 on failure (in case the file config doesn't exists or the ID doesn't mach with any of files or the user abort the process or an invalid caracter in the confirmation)
#################################################

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
	
	: "${RECYCLE_DIR:="$HOME/.recycle_bin"}"
	: "${FILES_DIR:="$RECYCLE_DIR/files"}"
	: "${METADATA_FILE:="$RECYCLE_DIR/metadata.csv"}"
	: "${LOG_FILE:="$RECYCLE_DIR/recyclebin.log"}"
	shopt -s nullglob
	files=("$FILES_DIR"/*)
	shopt -u nullglob
	if [[ ${#files[@]} -eq 0 ]]; then
    	log "ERROR" "Recycle bin is already empty"
    	return 1
	fi
	argument=("$@")
	skip=0
	for i in "${!argument[@]}"; do
		if [[ "${argument[i]}" == "--force" ]]; then
			skip=1
			unset 'argument[i]'
			break
		fi
	done
	argument=("${argument[@]}")
	#=====================
	if [[ $skip -eq 0 ]]; then
		echo -e "Permanently deleted files cannot be restore\nDo you wish to continue[Y/n]?"
		read -r answer
		if [[ "${answer,,}" == "n" ]]; then
			echo "Abort process"
			return 1
		elif [[ "${answer,,}" != "y" ]]; then
			echo "Invalid caracter"
			return 1
		fi
	fi
	#====================
	#Cheking the arguments(if there's nothing or "all")
	
	if [[ "${#argument[@]}" -eq 0 || "${argument[0]}" == "all" ]]; then
		#remove files
		shopt -s nullglob
		for f in "$FILES_DIR"/*; do
    		rm -rf "$f"
    		echo -e "$(basename "$f") deleted successfully!\n"
		done
		shopt -u nullglob
		#clear the metadata.bd file
		head -n 1 "$METADATA_FILE" > "$METADATA_FILE.tmp"
		mv "$METADATA_FILE.tmp" "$METADATA_FILE"
		#write on log file and make the return
		log "EMPTY" "Successfully deleted all files"	
		return 0
	fi
	#====================
	#Checking the arguments individually
	error=0
	deletedFiles=0
	for fileID in "${argument[@]}"; do
		file=$( grep "$fileID" "$METADATA_FILE" | awk -F',' '{print $2}')
		if [[ -z "$file" ]]; then
			echo "[ERROR] File ID unknown: $fileID"
			((error++))
    		continue
		fi
		filePath="$FILES_DIR/$file"
		if [[ ! -e "$filePath" ]]; then
    		echo "[ERROR] File not found: $file"
			((error++))
    		continue
		fi
		rm -rf "$filePath"
		echo -e "$file deleted successfully!\n"
		((deletedFiles++))
		#remove file in metadata file
		sed -i "/^$fileID,/d" "$METADATA_FILE"
		#write on log file and make the return
		
	done
	if (( error > 0 && error != "${#argument[@]}" )); then
		log "ERROR" "Function empty_recycle couldn't delete $error files"
		log "EMPTY" "Successfully deleted $deletedFiles files"
		return 1
	elif (( error == "${#argument[@]}" )); then
		log "ERROR" "Function empty_recycle couldn't delete any of the files"
		return 1
	fi
	log "EMPTY" "Successfully deleted all files"
	return 0
	#====================
}