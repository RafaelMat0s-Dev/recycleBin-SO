#!/bin/bash

#################################################
# Script Header Comment
# Author: João Miguel Padrão Neves
# Date: 2025-10-28
# Description: Function to show statistics
# Version: 1.0
#################################################

#################################################
# Function: show_statistic()
# Description: Show informations about the recycle like the number of files the oldest the newest the heavier and show which files are diretories or files
# Parameters: None
# Returns: 0
#################################################

# ============================================
# GLOBAL VARIABLES
# ============================================

RECYCLE_DIR="$HOME/.recycle_bin"
FILES_DIR="$RECYCLE_DIR/files"
CONFIG_FILE="$RECYCLE_DIR/config.txt"
METADATA_FILE="$RECYCLE_DIR/metadata.db"
LOG_FILE="$RECYCLE_DIR/recyclebin.log"

# ============================================
# AUXILIARY FUNCTIONS
# ============================================

log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

# Função para obter a data em segundos do arquivo no METADATA_FILE
get_file_date_sec() {
    local file="$1"
    local date_str
    date_str=$(grep -F -- "$file" "$METADATA_FILE" | awk -F',' '{print $4}')
    date -d "$date_str" +%s
}

function show_statistic() {
    echo -e "============================================================="
    source "$CONFIG_FILE"
    files=("$FILES_DIR"/*) #List of files
    echo -e "Recycle Bin status:\n"
    if [ ${#files[@]} -eq 0 ]; then
        echo "Recycle bin is empty."
        echo -e "============================================================="
        return 0
    fi
    echo -e "   ->Number of files: ${#files[@]} files\n"
    
    fileSize=$(du -sm "$FILES_DIR" | cut -f1)
    convertPercent=$(echo "scale=2; $fileSize * 100 / $MAX_SIZE_MB" | bc)
    echo -e "   ->Total Storage used: $convertPercent%\n"
    
    #======================================
    heavierFile="${files[0]}"
    fileHeavierSize=$(stat -c%s "$heavierFile")
    for f in "${files[@]}"; do 
        fileSize=$(stat -c%s "$f")
        if [[ fileSize -gt fileHeavierSize ]]; then
            heavierFile="$f"
            fileHeavierSize="$fileSize"
        fi
    done
    fileHeavierSizeMB=$(echo "scale=2; $fileHeavierSize/1024/1024" | bc)
    #======================================
    echo -e "   ->Heaviest File: $heavierFile\n"
    echo -e "       ->Size: $fileHeavierSizeMB MB"
    #======================================
    mostRecentFile="${files[0]}"
    olderFile="${files[0]}"
    
    mostRecentDate=$(get_file_date_sec "$mostRecentFile")
    olderDate=$mostRecentDate

    for f in "${files[@]}"; do
        fileDate=$(get_file_date_sec "$f")

        if [[ fileDate -gt mostRecentDate ]]; then
            mostRecentDate=$fileDate
            mostRecentFile="$f"
        fi

        if [[ fileDate -lt olderDate ]]; then
            olderDate=$fileDate
            olderFile="$f"
        fi
    done
    #========================================
    echo -e "   ->Newest File: $mostRecentFile\n"
    echo -e "   ->Oldest File: $olderFile\n"
    #========================================
    file_only=()
    directory=()
    for f in "${files[@]}"; do
        if [[ -d "$f" ]]; then
            directory+=("$f")
        else
            file_only+=("$f")
        fi
    done
    #========================================
    echo -e "   ->Types of files:\n"
    echo -e "       ->Directories:\n"
    for d in "${directory[@]}"; do
        echo -e "           ->$d\n"
    done
    echo -e "       ->Files\n"
    for f in "${file_only[@]}"; do
        echo -e "           ->$f\n"
    done
    log "STATUS" "Display recycle bin status"
    echo -e "============================================================="
    return 0
}
