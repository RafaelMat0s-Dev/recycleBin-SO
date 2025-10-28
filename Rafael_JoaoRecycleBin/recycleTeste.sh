#!/bin/bash
#################################################
# recycle_bin.sh - Main Script with embedded initialize function
# Author: Rafael da Costa Matos
# Date: 2025-10-27
#################################################

if [[ -d "$HOME/.recycle_bin" ]]; then
    echo "[DEBUG] Recycle bin directory already exists at $HOME/.recycle_bin"
    # Uncomment the next line if you want to remove it automatically before init
    # rm -rf "$HOME/.recycle_bin"
else
    echo "[DEBUG] Recycle bin directory NOT FOUND. Proceeding..."
fi

# PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# FUNCTIONS_DIR="$PROJECT_ROOT/bashFunctions"

# === Include other function scripts ===
# source "$FUNCTIONS_DIR/deleteFiles.sh"
# source "$FUNCTIONS_DIR/listRecycled.sh"
# source "$FUNCTIONS_DIR/restoreFile.sh"
# source "$FUNCTIONS_DIR/previewFile.sh"
# source "$FUNCTIONS_DIR/search_recycle.sh"

# === Initialize Recycle Bin function embedded directly ===
initialize_recyclebin() {
    local RECYCLE_DIR="$HOME/.recycle_bin"
    local FILES_DIR="$RECYCLE_DIR/files"
    local METADATA_FILE="$RECYCLE_DIR/metadata.csv"
    local CONFIG_FILE="$RECYCLE_DIR/config"
    local LOG_FILE="$RECYCLE_DIR/recyclebin.log"

    RECYCLE_DIR="$HOME/.recycle_bin"
    if [[ -d "$RECYCLE_DIR" ]]; then
        echo "[DEBUG] Detected folder exists: $RECYCLE_DIR"
    else
        echo "[DEBUG] Folder does NOT exist: $RECYCLE_DIR"
    fi


    if [[ -z "$HOME" || ! -d "$HOME" ]]; then
        echo "[ERROR] Home environment variable is not set or invalid" >&2
        return 1
    fi

    if [[ -d "$RECYCLE_DIR" ]]; then
        echo "[WARNING] Recycle bin already exists at $RECYCLE_DIR"
        echo "          Skipping re-initialization to avoid overwriting data"
        return 0
    fi

    echo "[INFO] Initializing Recycle Bin at: $RECYCLE_DIR"
    mkdir -p "$FILES_DIR"
    if [[ $? -ne 0 || ! -d "$FILES_DIR" ]]; then
        echo "[ERROR] Failed to create directory structure at: $FILES_DIR" >&2
        return 1
    fi

    if [[ ! -f "$METADATA_FILE" || ! -s "$METADATA_FILE" ]]; then
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" > "$METADATA_FILE"
        if [[ $? -ne 0 ]]; then
            echo "[ERROR] Failed to create metadata.csv at $METADATA_FILE" >&2
            return 1
        fi
        echo "[INFO] Created metadata.csv with header"
    else
        echo "[INFO] metadata.csv already exists, skipping"
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
        echo "[INFO] Created default config file"
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
            echo "[ERROR] Failed to create recyclebin.log at $LOG_FILE" >&2
            return 1
        fi
        echo "[INFO] Created recyclebin.log"
    fi

    if [[ ! -w "$LOG_FILE" ]]; then
        echo "[ERROR] recyclebin.log is not writable at $LOG_FILE" >&2
        return 1
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') [INIT] Recycle Bin initialized successfully" >> "$LOG_FILE"
    echo "[SUCCESS] Recycle Bin initialized successfully at $RECYCLE_DIR"
    return 0
}

# === Main Command Routing ===
case "$1" in
    "" )
        echo "[INFO] Initializing Recycle Bin..."
        initialize_recyclebin
        ;;
    
    # delete )
    #     shift
    #     delete_file "$@"
    #     ;;
    
    # list )
    #     shift
    #     list_recycled "$@"
    #     ;;
    
    # restore )
    #     shift
    #     restore_file "$@"
    #     ;;
    
    # preview )
    #     shift
    #     preview_file "$@"
    #     ;;
    
    # search )
    #     shift
    #     search_recycle "$@"
    #     ;;
    
    # * )
    #     echo "[ERROR] Unknown command: $1"
    #     echo "Usage:"
    #     echo "  ./recycle_bin.sh                     # Initialize"
    #     echo "  ./recycle_bin.sh delete file1.txt    # Delete files"
    #     echo "  ./recycle_bin.sh list [--detailed]   # List files"
    #     echo "  ./recycle_bin.sh restore <fileID>    # Restore file"
    #     echo "  ./recycle_bin.sh preview <filename>  # Preview file"
    #     echo "  ./recycle_bin.sh search <pattern>    # Search files"
    #     ;;
esac
