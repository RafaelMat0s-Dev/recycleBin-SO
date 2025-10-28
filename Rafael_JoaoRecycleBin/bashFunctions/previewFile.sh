#!/bin/bash

#################################################
# Recycle Bin File Preview Script
# Author: Rafael da Costa Matos
# Date: 2025-10-23
# Version: 1.0
# Description:
#   Allows previewing of files stored in the recycle bin.
#   Supports text and binary file detection using the 'file' command.
#################################################

# ============================================
# GLOBAL VARIABLES
# ============================================



log(){
	local level="$1"
	local message="$2"
	echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}


preview_file(){

    local RECYCLE_DIR="$HOME/.recycle_bin"
    local FILES_DIR="$RECYCLE_DIR/files"
    local METADATA_FILE="$RECYCLE_DIR/metadata.csv"
    local LOG_FILE="$RECYCLE_DIR/recyclebin.log"

    local id="$1"

    if [[ -z "$id" ]]; then
        echo "[ERROR] Missing argument. Usage: preview_file <file_id>"
        return 1
    fi

    local line
    line=$(grep -m1 "^$id," "$METADATA_FILE")

    if [[ -z "$line" ]]; then
        echo "[ERROR] No entry found for ID: $id"
        log "PREVIEW_FAILED" "NO metadata entry found for $id"
        return 1
    fi

    IFS=',' read -r id original_name original_path deletion_date file_size file_type perms owner <<< "$line"
    local file_path="$FILES_DIR/$id"

    if [[ ! -e "$file_path" ]]; then
        echo "[ERROR] File not found in recycle bin for ID: $id"
        log "PREVIEW_FAILED" "Missing recycled file for $id ($original_name)"
        return 1
    fi

    local mime_type
    mime_type=$(file -b --mime-type "$file_path")

    echo "========================================"
    echo "🔍 Previewing File:"
    echo "  Original Name: $original_name"
    echo "  Type: $mime_type"
    echo "  Size: $file_size bytes"
    echo "  Deleted on: $deletion_date"
    echo "========================================"
    echo

    if [[ "$mime_type" == text/* ]]; then
        echo "--- First 10 lines of $original_name ---"
        echo
        head -n 10 "$file_path"
        echo
        echo "--- End of preview ---"
        log "PREVIEW_SUCCESS" "Displayed first 10 lines of text file $original_name ($id)"
    else
        echo "[INFO] This is a binary or non-text file. Showing file details instead:"
        file "$file_path"
        log "PREVIEW_INFO" "Displayed info for binary file $original_name ($id)"
    fi

    return 0

}