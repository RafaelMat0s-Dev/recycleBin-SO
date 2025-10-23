#!/bin/bash

#################################################
# Recycle Bin DeleteFile Script
# Author: Rafael da Costa Matos
# Date: 2025-10-20
# Version: 1.1
# Description:
#    Script Created to Fulfill the restore_file() directory of the project.
#################################################

# ============================================
# GLOBAL VARIABLES
# ============================================

RECYCLE_DIR="$HOME/.recycle_bin"
FILES_DIR="$RECYCLE_DIR/files"
METADATA_FILE="$RECYCLE_DIR/metadata.csv"
CONFIG_FILE="$RECYCLE_DIR/config"
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
# DELETE FUNCTION
# ============================================
delete_file() {

    if [[ $# -eq 0 ]]; then
        echo "[ERROR] No files or directories specified for deletion." >&2
        return 1
    fi

    # Prevent deleting the recycle bin itself
    for item in "$@"; do
        if [[ "$item" == "$RECYCLE_DIR"* ]]; then
            echo "[ERROR] Cannot delete the recycle bin itself: $item" >&2
            return 1
        fi
    done

    # Ensure recycle bin exists
    if [[ ! -d "$FILES_DIR" ]]; then
        echo "[ERROR] Recycle Bin not initialized. Run './recycle_bin.sh'" >&2
        return 1
    fi

    for target in "$@"; do

        if [[ ! -e "$target" ]]; then
            echo "[ERROR] FILE or DIRECTORY not found: $target" >&2
            log "ERROR" "File/Directory not found: $target"
            continue
        fi

        if [[ ! -r "$target" || ! -w "$(dirname "$target")" ]]; then
            echo "[ERROR] No permission to delete: $target" >&2
            log "ERROR" "Permission denied for $target"
            continue
        fi

        # Generate unique ID
        local id
        id=$(uuidgen 2>/dev/null || date +%s%N)
        local base_name
        base_name=$(basename "$target")
        local abs_path
        abs_path=$(realpath "$target")
        local dest_path="$FILES_DIR/$id"

        # Determine size and type
        local file_size file_type perms owner
        if [[ -d "$target" ]]; then
            file_type="directory"
            file_size=$(du -sb "$target" | cut -f1)
        else
            file_type="file"
            file_size=$(stat -c %s "$target")
        fi

        perms=$(stat -c %a "$target")
        owner=$(stat -c %U:%G "$target")
        local deletion_date
        deletion_date=$(date '+%Y-%m-%d %H:%M:%S')

        # Check disk space
        local avail_kb file_kb
        avail_kb=$(df --output=avail -k "$RECYCLE_DIR" | tail -1)
        file_kb=$(( (file_size + 1023) / 1024 ))

        if (( avail_kb <= file_kb )); then
            echo "[ERROR] Insufficient disk space in recycle bin. Cannot delete: $target" >&2
            log "ERROR" "Insufficient disk space for $target (requires ${file_kb}KB)"
            continue
        fi

        # Move files or directories (preserving contents for directories)
        if [[ -d "$target" ]]; then
            mv "$target" "$dest_path" 2>/dev/null
        else
            mv "$target" "$dest_path" 2>/dev/null
        fi

        if [[ $? -ne 0 ]]; then
            echo "[ERROR] Failed to move $target to recycle bin." >&2
            log "ERROR" "Failed to move $target"
            continue
        fi

        # Append metadata to CSV
        if [[ ! -f "$METADATA_FILE" ]]; then
            echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" > "$METADATA_FILE"
        fi
        echo "$id,$base_name,$abs_path,$deletion_date,$file_size,$file_type,$perms,$owner" >> "$METADATA_FILE"

        echo "[SUCCESS] Deleted: $base_name -> Recycle bin ($id)"
        log "DELETE" "Moved $target -> $dest_path"
    done

    return 0
}
