#!/bin/bash

#################################################
# Recycle Bin Management Script
# Author: Rafael da Costa Matos
# Date: 2025-10-20
# Version: 1.0
# Description:
#   Implements a manual recycle bin system in Bash
#   with initialization, deletion, metadata logging,
#   and robust error handling.
#################################################

# ============================================
# GLOBAL VARIABLES
# ============================================

RECYCLE_DIR="$HOME/.recycle_bin"
FILES_DIR="$RECYCLE_DIR/files"
METADATA_FILE="$RECYCLE_DIR/metadata.db"
CONFIG_FILE="$RECYCLE_DIR/config"
LOG_FILE="$RECYCLE_DIR/recyclebin.log"


log(){
	local level="$1"
	local message="$2"
	echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

delete_file(){

	if [[ $# -eq 0 ]]; then
		echo "[ERROR]: No files specified for deletion." >&2
		return 1
	fi

	#Make sure you don't delete the recycle bin itself
	for item in "$@"; do
		if [[ "$item" == "$RECYCLE_DIR"* ]]; then
			echo "[ERROR] Cannot delete the recycle bin itself: $item" > &2
			return 1
		fi
	done

	#Ensure the main folder exists so it doesn't try to delete files on a folder that doesn't exist
	
	if [[ ! -d "$FILES_DIR" ]]; then
		echo "[ERROR] Recycle Bin not initialized. Run './recycle_bin.sh"
		return 1
	fi
	
	for file in "$@"; do

		if [[ ! -e "$file" ]]; then
			echo "[ERROR] FILE not FOUND: $file" >&2
			log "ERROR" "File not found: $file"
			continue
		fi

		if [[ ! -r "$file" || ! -w  "$(dirname "$file")" ]]; then
			echo "[ERROR] No permission to delete : $file" >&2
			log "ERROR" "Permission denied for $file"
			continue
		fi

		local id
		id=$(uuidgen 2>/dev/null || date +%s%N)
		local base_name
		base_name=$(basename "$file")
		local abs_path
		abs_path=$(realpath "$file")
		local dest_path="$FILES_DIR/$id"
		local file_size
		file_size=$(du -b "$file" | cut -f1)
		[[ -d "$file" ]] && file_type="directory" || file_type="file"
		local perms owner
		perms=$(stat -c %a "$file")
		owner=$(stat -c %U:%G "$file")
		local deletion_date
		deletion_date=$(date '+%Y-%m-%d %H:%M:%S')


		local avail_kb
		avail_kb=$(df --output=avail -k "$RECYCLE_DIR" | tail -1)
		local file_kb=$(( (file_size + 1023) / 1024 ))

		if (( avail_kb <= file_kb )); then
			echo "[ERROR] Insufficient disk space in recycle bin. Cannot delete: $file" >&2
			log "ERROR" "Insufficient disk space for $file (requires ${file_kb}KB)"
			continue
		fi

		mv "$file" "$dest_path" 2>/dev/null
		if [[$? -ne 0]]; then
			echo "[ERROR] Failed to move file to recycle bin: $file" >&2
			log "ERROR" "Failed to move $file"
			continue
		fi

		#Append metadata to the METADATA File
		
		echo "$id,$base_name,$abs_path,$deletion_date,$file_size,$file_type,$perms,$owner" >> "$METADATA_FILE"
		echo "[SUCCESS] Deleted: $base_name -> Recycle bin ($id)"
		log "DELETE" "Moved $file -> $dest_path"
	done

	return 0

}
