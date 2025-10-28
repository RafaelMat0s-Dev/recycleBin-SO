#!/bin/bash

#################################################
# RestoreFile Management Script
# Author: Rafael da Costa Matos
# Date: 2025-10-20
# Version: 1.1
# Description:
#   Script Created to Fulfill the restore_file() directory of the project.
#################################################

# ============================================
# GLOBAL VARIABLES
# ============================================


log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

restore_file(){

    local RECYCLE_DIR="$HOME/.recycle_bin"
    local FILES_DIR="$RECYCLE_DIR/files"
    local METADATA_FILE="$RECYCLE_DIR/metadata.csv"
    local CONFIG_FILE="$RECYCLE_DIR/config"
    local LOG_FILE="$RECYCLE_DIR/recyclebin.log"

    # Primeiro preciso de diferenciar o script  para ver se é ID de ficheiro ou nome de ficheiro

    local query="$1"

    if [[ -z "$query" ]]; then
        echo "[ERROR] Missing argument. Usage: restore_file <file_id|filename>"
        return 1
    fi

    local search_field
    if [[ "$query" =~ ^[0-9a-fA-F-]{36}$ ]] || [[ "$query" =~ ^[0-9]{15,20}$ ]]; then
        search_field="ID"
    else
        search_field="ORIGINAL_NAME"
    fi
    
    local line
    if [[ "$search_field" == "ID" ]]; then
        line=$(grep -m1 "^$query," "$METADATA_FILE")
    else
        line=$(grep -m1 ",$query," "$METADATA_FILE")
    fi


    if [[ -z "$line" ]]; then
        echo "[ERROR] No entry found for '$query' in metadata."
        log "RESTORE_FAILED" "No metadata entry found for $query"
        return 1
    fi

    IFS=',' read -r id original_name original_path deletion_date file_size file_type perms owner <<< "$line"

    local source_path="$FILES_DIR/$id"
    local dest_path="$original_path"


    if [[! -e "$source_path" ]]; then
        echo "[ERROR] Recycled file not found in $FILES_DIR/$id"
        log "RESTORE_FAILED" "Missing recycled file for $id ($original_name)"
        return 1
    fi

    if [[ ! -d "$(dirname "$dest_path")" ]]; then
        echo "[INFO] Original directory no longer exists. Creating Parent Directories"
        log "[CREATION]" "Creating parent directories"
        mkdir -p "$(dirname "$dest_path")"

    fi

    if [[ -e "$dest_path" ]]; then
        echo "[WARNING] A file already exists at: $dest_path"
        echo "Choose action:"
        echo "  [O] Overwrite existing file"
        echo "  [R] Restore with modified name (append timestamp)"
        echo "  [C] Cancel restoration"
        read -rp "Your choice (O/R/C): " choice

        case "$choice" in

            [Oo])
                echo "[INFO] Overwriting existing file..."
                rm -rf "$dest_path"
                ;;
            [Rr])
                local timestamp
                timestamp=$(date +"%Y%m%d_%H%M%S")
                local ext="${original_name##*.}"
                local base="${original_name%.*}"
                if [[ "$original_name" == "$ext" ]]; then
                    dest_path="$(dirname "$original_path")/${base}_restored_$timestamp"
                else
                    dest_path="$(dirname "$original_path")/${base}_restored_$timestamp.$ext"
                fi
                echo "[INFO] Restoring with new name: $(basename "$dest_path")"
                ;;
            [Cc])
                echo "[INFO] Restoration canceled."
                log "RESTORE_CANCEL" "User canceled restoration of $original_name ($id)"
                return 0
                ;;
            *)
                echo "[ERROR] Invalid choice. Aborting restoration."
                return 1
                ;;
        esac
    fi

    mv "$source_path" "$dest_path" 2>/dev/null
    if [[ $? -ne 0 ]]; then 
        echo "[ERROR] Failed to restore file to $dest_path"
        log "RESTORE_FAILED" "Could not move $id to $dest_path"
        return 1
    fi

    chmod "$perms" "dest_path" 2>/dev/null
    chmod "$owner" "$dest_path" 2>/dev/null


    grep -v "^$id," "$METADATA_FILE" > "${METADATA_FILE}.tmp" && mv "${METADATA_FILE}.tmp" "$METADATA_FILE"

    echo "[SUCCESS] File '$original_name' restore to '$dest_path'"
    log "RESTORE_SUCCESS" "Restored $original_name ($id) -> $dest_path"
    
}