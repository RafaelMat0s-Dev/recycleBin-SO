#!/bin/bash

#################################################
# Function: list_recycled()
# Description:
#   Lists all items currently in the recycle bin.
#   Supports compact (default) and detailed (--detailed) modes.
# Parameters:
#   --detailed (optional) for full item info
# Returns:
#   0 on success, 1 on error
#################################################

# ============================================
# GLOBAL VARIABLES
# ============================================


RECYCLE_DIR="$HOME/.recycle_bin"
FILES_DIR="$RECYCLE_DIR/files"
METADATA_FILE="$RECYCLE_DIR/metadata.db"
LOG_FILE="$RECYCLE_DIR/recyclebin.log"

mkdir -p "$FILES_DIR"
touch "$METADATA_FILE" "$LOG_FILE"

log(){

	local level="$1"
	local message="$2"
	echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

list_recycled(){

	local detailedOption=false
	[[ "$1" == "--detailed" ]] && detailedOption=true

	if [[ ! -s "$METADATA_FILE" ]]; then
		echo " Recycle Bin is empty "
		log "INFO" "USER listed recycle bin: empty"
		return 0
	fi

	if [[ "$detailedOption" == true ]]; then
		echo " Detailed Recycle Bin Contents "
		echo "------------------------------------------"
	else
		printf "%-12s %-25s %-20s %-10s\n" "UNIQUE_ID" "ORIGINAL_NAME" "DELETION_DATE" "SIZE"
		echo "------------------------------------------"
	fi

	local total_size=0
	local total_count=0

	while IFS=',' read -r id original_name original_path deletion_date file_size file_type permissions owner; do
		[[ -< "$id" || "$id" == "ID" ]] continue

		total_count=$((total_count + 1))
		total_size=$((total_size + file_size))

		local readable_sizeNumber
		if command -v numfmt &>/dev/null; then
			readable_sizeNumber=$(numfmt --to=iec --suffix=B "$file_size")
		else
			readable_sizeNumber="${file_size}B"
		fi


		if [[ "$detailedOption" == true ]]; then
			echo "🆔 ID:           $id"
           		echo "📄 Name:         $original_name"
          		echo "📂 Original Path:$original_path"
            		echo "🕒 Deleted On:   $deletion_date"
            		echo "📦 Size:         $hr_size"
            		echo "📁 Type:         $file_type"
            		echo "🔐 Permissions:  $permissions"
            		echo "👤 Owner:        $owner"
            		echo "----------------------------------------"
        	else
            		printf "%-12s %-25s %-20s %-10s\n" "${id:0:10}" "$original_name" "$deletion_date" "$hr_size"
        	fi
    	done < "$METADATA_FILE"


	#Send all Info to Terminal and List it in LOGFILE
	
	echo ""
	echo "Total items: $total_count"

	if command -v numfmt &>/dev/null; then
		echo "Total size: $(numfmt --to=iec --suffix=B "$total_size")"
	else
		echo "Total size: ${total_size}B"
	fi

	log "INFO" "Listed $total_count items (total size: ${total_size}B)"
}


