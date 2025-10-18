#!/bin/bash

#################################################
# Script Header Comment
# Author: Rafael da Costa Matos
# Date: 2025-10-18
# Description: Creating the function that initializes the recycleBin
# Version: 1.0
#################################################


#################################################
# Function: initialize_recyclebin()
# Description: Creates, if it doesn't exist the recyclebin folder in the root of the operatingSystem ~/
# Parameters: This function doesn't have input parameters as it's run like ./recycle_bin.sh
# Returns: 0 on success, 1 on failure (in case the directory already exists)
#################################################



initialize_recyclebin(){

	local RECYCLE_DIR="$HOME/.recycle_bin"
	local FILES_DIR="$RECYCLE_DIR/files"
	local METADATA_FILE="$RECYCLE_DIR/metadata.db"
	local CONFIG_FILE="$RECYCLE_DIR/config"
	local LOG_FILE="$RECYCLE_DIR/recyclebin.log"

	if [[ -z "$HOME" || ! -d "$HOME" ]]; then
		echo "[ERROR] Home environment variable is not set or invalid" >&2
		return 1
	fi

	if [[ -d "$RECYCLE_DIR" ]]; THEN
		echo "[Warning] Recycle bin already exists at $RECYCLE_DIR"
		echo "		Skipping re-initialization to avoid overwriting data"
		return 0
	fi

	echo "[INFO] Initializing Recycle Bin at: $RECYCLE_DIR"

	mkdir -p "$FILES_DIR"

	if [[ $? -ne 0 ]]; then
		echo "[ERROR] Failed to create directory structure at: $FILES_DIR" >&2
		return 1
	fi

	if [[ ! -d "$FILES_DIR" ]]; then
		echo "[Error] Directory creation verification failed for $FILES_DIR" >&2
		return 1
	fi

	if [[ -f "$METADATA_FILE" && -s "$METADATA_FILE" ]];then
		echo "[INFO] metadata.db already exists, skipping"
	else
		echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER"
		if [[ $? -ne 0 ]]; then
			echo "[ERROR] Failed to create metadata.db at $METADATA_FILE" >&2
			return 1
		fi
		echo "[INFO] Created metadata.db with header"
	fi

	if [[ ! -f "$CONFIG_FILE" ]]; then
		cat > "$CONFIG_FILE" << EOF
MAX_SIZE_MB=1024
RETENTION_DAYS=30
EOF
		if [[ $? -ne 0 ]]; then
			echo "[ERROR] Failed to create config file at $CONFIG_FILE" >&2
			return 1
		fi
		echo "[INFO] Created dafault config file"
	else
		echo "[INFO] Config file already exists, skipping"
	fi


	local MAX_SIZE RETENTION

	MAX_SIZE=$(grep -E '^MAX_SIZE_MB=' "$CONFIG_FILE" | cut -d'=' -f2)	
   	RETENTION=$(grep -E '^RETENTION_DAYS=' "$CONFIG_FILE" | cut -d'=' -f2)	

	if [[ -z "$MAX_SIZE" || "$MAX_SIZE" =~ [^0-9] ]]; then
		echo "[ERROR] Invalid MAX_SIZE_MB value in config: '$MAX_SIZE'" >&2
		return 1
	fi

	if [[ -z "$RETENTION" || "$RETENTION" =~ [^0-9] ]]; then
		echo "[ERROR] Invalid RETENTION_DAYS value in config: '$RETENTION'" >&2
		return 1
	fi

	if [[ ! -f "$LOG_FILE" ]]; then
		touch "$LOG_FILE"
		if [[ $? -ne 0 ]]; then

			echo "[Error] recyclebin.log is not writable at $LOG_FILE" >&2
			return 1
		fi
		echo "[INFO] Created Recyclebin.log"
	fi

	if [[ ! -w "$LOG_FILE" ]]; then
		echo "[ERROR] recyclebin.log is not writable at $LOG_FILE" >&2
		return 1
	fi

	echo "$(date '+%Y-%m-%d %H:%M:%S') [INIT] Recycle Bin initialized successfully" >> "$LOG_FILE"

   	echo "[SUCCESS] Recycle Bin initialized successfully at $RECYCLE_DIR"
    	return 0
	
}
