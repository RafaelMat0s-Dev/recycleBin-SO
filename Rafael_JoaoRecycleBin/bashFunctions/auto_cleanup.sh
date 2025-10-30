#!/bin/bash

#################################################
# Script Query Comment
# Author: Joao Miguel Padrao
# Date: 2025-10-30
# Description: Cleans every file that is keep in recycle for too long 
# Version: 1.0
#################################################

#################################################
# Function: auto_cleanup()
# Description: Checks if the Recycle has any file, that is in recycle more time than the number of days saved in the global variable RETENTION_DAYS and if it does delete it   
# Parameters: This function can have the paramter test to make it easier to test, changing the MAX_SIZE_MB to a smaller number
# Returns: 0 on success
#################################################

# ============================================
# LOG FUNCTION
# ============================================

log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

function auto_cleanup() {

	: "${RECYCLE_DIR:="$HOME/.recycle_bin"}"
	: "${FILES_DIR:="$RECYCLE_DIR/files"}"
	: "${METADATA_FILE:="$RECYCLE_DIR/metadata.csv"}"
    : "${CONFIG_FILE="$RECYCLE_DIR/config.txt"}"
	: "${LOG_FILE:="$RECYCLE_DIR/recyclebin.log"}"

    source "$CONFIG_FILE"
    if [ "$1" == "test" ]; then
        RETENTION_DAYS=1
    fi
    files=("$FILE_DIR"/*) #List of files
    curdate=$( date +%s)
    curdateDays=$(( curdate / 86400 ))
    deleted=0
    for f in "${files[@]}"; do
        fileDate=$(grep -F -- "$f" "$METADATA_FILE" | awk -F',' '{print $4}')
        ts=$(date -d "$fileDate" +%s)
        fileDateDays=$(( ts / 86400 ))
        if (( curdateDays - fileDateDays >= RETENTION_DAYS )); then
            [[ -f "$f" ]] || continue
            rm -rf "$f" 
            echo "[INFO] File $f auto-deleted successfully"
            deleted=1
        fi
    done
    if [[ "$deleted" -eq 0 ]]; then
        log "CLEANUP" "Recycle Bin is already Optimized"
        return 0
    fi
    log "CLEANUP" "Recycle Bin optimize successfully"
    return 0
}