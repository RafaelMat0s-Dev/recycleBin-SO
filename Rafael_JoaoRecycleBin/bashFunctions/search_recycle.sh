#!/bin/bash

#################################################
# Script Query Comment
# Author: Joao Miguel Padrao
# Date: 2025-10-18
# Description: Function that searches deleted files in recycle bin
# Version: 1.1 (corrected)
#################################################

#################################################
# Function: search_recycle()
# Description:
#   Search for a file or pattern in the recycle bin and display:
#   ID, name, type, size, and owner (from metadata.db)
# Parameters:
#   A filename or pattern (e.g. "*.txt")
# Returns:
#   0 on success, 1 on failure
#################################################

CONFIG_FILE_DIR="../ConfigRecycle.txt"

search_recycle() {
	
	# Import global variables from config
	if [[ -f "$CONFIG_FILE_DIR" ]]; then
    	source "$CONFIG_FILE_DIR"
	else
    	echo "[ERROR] Config file not found: $CONFIG_FILE_DIR" >&2
    	return 1
	fi
	
	# Ensure required variables are set
	if [[ -z "$FILES_DIR" || -z "$METADATA_FILE" ]]; then
		echo "[ERROR] FILES_DIR or METADATA_FILE not defined in config" >&2
		return 1
	fi

	if [[ -z "$1" ]]; then
		echo "[ERROR] Missing search pattern. Usage: ./recycle_bin.sh search <pattern>" >&2
		return 1
	fi

	local pattern="$1"

	cd "$FILES_DIR" || {
		echo "[ERROR] Cannot access recycle bin files directory: $FILES_DIR" >&2
		return 1
	}

	# Find matching files (case insensitive)
	mapfile -t fileSearch < <(find . -iname "$pattern")

	# If no matches found
	if [[ ${#fileSearch[@]} -eq 0 ]]; then
		echo "[ERROR] No files found matching pattern '$pattern'"
		return 1
	fi

	# Print table header
	printf "%-36s %-30s %-10s %-10s %-20s\n" "UNIQUE_ID" "FILENAME" "TYPE" "SIZE" "OWNER"
	echo "------------------------------------------------------------------------------------------"

	for f in "${fileSearch[@]}"; do
		local file_id
		file_id=$(basename "$f")

		# Find the line in metadata
		local metadata_line
		metadata_line=$(grep -m 1 "$file_id" "$METADATA_FILE")

		if [[ -z "$metadata_line" ]]; then
			continue
		fi

		IFS=',' read -r id original_name original_path deletion_date file_size file_type permissions owner <<< "$metadata_line"

		local hr_size
		if command -v numfmt &>/dev/null; then
			hr_size=$(numfmt --to=iec --suffix=B "$file_size")
		else
			hr_size="${file_size}B"
		fi

		printf "%-36s %-30s %-10s %-10s %-20s\n" "$id" "$original_name" "$file_type" "$hr_size" "$owner"
	done

	# Log search operation
	echo "$(date '+%Y-%m-%d %H:%M:%S') [SEARCH] Search executed for pattern '$pattern'" >> "$LOG_FILE"

	return 0
}
