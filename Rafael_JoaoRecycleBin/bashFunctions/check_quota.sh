#!/bin/bash

#################################################
# Script Query Comment
# Author: Joao Miguel Padrao
# Date: 2025-10-30
# Description: Checks if the Recycle bin is full 
# Version: 1.0
#################################################

#################################################
# Function: check_quota()
# Description: Checks if the Recycle size exceeds the global variable MAX_SIZE_MB and if it does the program ask the user if he can do a optimization(auto clean)
# Parameters: This function can have the paramter test to make it easier to test, changing the MAX_SIZE_MB to a smaller number
# Returns: 0 on success, 1 on failure (in case of the recycle is still full even after we make a auto-cleanup or the user abort the process or an invalid caracter in the confirmation)
#################################################

# ============================================
# LOG FUNCTION
# ============================================

log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

function check_quota() {

    : "${RECYCLE_DIR:="$HOME/.recycle_bin"}"
	: "${FILES_DIR:="$RECYCLE_DIR/files"}"
	: "${METADATA_FILE:="$RECYCLE_DIR/metadata.csv"}"
    : "${CONFIG_FILE="$RECYCLE_DIR/config.txt"}"
	: "${LOG_FILE:="$RECYCLE_DIR/recyclebin.log"}"

    source "$CONFIG_FILE"
    if [ "$1" == "test" ]; then
        MAX_SIZE_MB=1
    fi
    fileDirSize=$(du -sm "$FILES_DIR" | cut -f1)
    if (( fileDirSize >= MAX_SIZE_MB )); then
        log "WARN" "Recycle bin is full!"
        echo "Do you wish to proceed with a optimization(Y/n)?"
        read -r anwser
        if [[ "${anwser,,}" = 'y' ]]; then
            auto_cleanup
            echo "Recycle Bin has been optimize successfully"
            fileDirSize=$(du -sm "$FILES_DIR" | cut -f1)
            if (( fileDirSize >= MAX_SIZE_MB )); then
                echo -e "Recycle bin is still full!"
                return 1
            fi
        elif [[ "${anwser,,}" = 'n' ]]; then
            echo "Operation aborted"
            return 1
        else
            echo "Invalid caracter"
            return 1
        fi
    fi
    log "CHECK" "Recycle has been clean successfully"
    return 0
}