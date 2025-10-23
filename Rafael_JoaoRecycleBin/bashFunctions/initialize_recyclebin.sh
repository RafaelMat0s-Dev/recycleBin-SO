#!/bin/bash

#################################################
# Script Header Comment
# Author: Rafael da Costa Matos
# Date: 2025-10-18
# Description: Function to initialize the Recycle Bin
# Version: 1.1
#################################################

#################################################
# Function: initialize_recyclebin()
# Description: Creates, if it doesn't exist, the recycle bin folder in the user's home directory (~)
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################

initialize_recyclebin() {
    local RECYCLE_DIR="$HOME/.recycle_bin"
    local FILES_DIR="$RECYCLE_DIR/files"
    local METADATA_FILE="$RECYCLE_DIR/metadata.csv"
    local CONFIG_FILE="$RECYCLE_DIR/config"
    local LOG_FILE="$RECYCLE_DIR/recyclebin.log"

    # Verifica se $HOME está definido e é válido
    if [[ -z "$HOME" || ! -d "$HOME" ]]; then
        echo "[ERROR] Home environment variable is not set or invalid" >&2
        return 1
    fi

    # Evita sobreescrever se o recycle bin já existe
    if [[ -d "$RECYCLE_DIR" ]]; then
        echo "[WARNING] Recycle bin already exists at $RECYCLE_DIR"
        echo "          Skipping re-initialization to avoid overwriting data"
        return 0
    fi

    echo "[INFO] Initializing Recycle Bin at: $RECYCLE_DIR"

    # Cria a estrutura de diretórios
    mkdir -p "$FILES_DIR"
    if [[ $? -ne 0 || ! -d "$FILES_DIR" ]]; then
        echo "[ERROR] Failed to create directory structure at: $FILES_DIR" >&2
        return 1
    fi

    # Cria o ficheiro metadata.csv com cabeçalho se não existir
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

    # Cria ficheiro de configuração se não existir
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

    # Lê configurações
    local MAX_SIZE RETENTION
    MAX_SIZE=$(grep -E '^MAX_SIZE_MB=' "$CONFIG_FILE" | cut -d'=' -f2)
    RETENTION=$(grep -E '^RETENTION_DAYS=' "$CONFIG_FILE" | cut -d'=' -f2)

    # Valida configurações
    if [[ -z "$MAX_SIZE" || "$MAX_SIZE" =~ [^0-9] ]]; then
        echo "[ERROR] Invalid MAX_SIZE_MB value in config: '$MAX_SIZE'" >&2
        return 1
    fi
    if [[ -z "$RETENTION" || "$RETENTION" =~ [^0-9] ]]; then
        echo "[ERROR] Invalid RETENTION_DAYS value in config: '$RETENTION'" >&2
        return 1
    fi

    # Cria ficheiro de log se não existir
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
        if [[ $? -ne 0 ]]; then
            echo "[ERROR] Failed to create recyclebin.log at $LOG_FILE" >&2
            return 1
        fi
        echo "[INFO] Created recyclebin.log"
    fi

    # Verifica permissões de escrita no log
    if [[ ! -w "$LOG_FILE" ]]; then
        echo "[ERROR] recyclebin.log is not writable at $LOG_FILE" >&2
        return 1
    fi

    # Escreve no log
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INIT] Recycle Bin initialized successfully" >> "$LOG_FILE"

    echo "[SUCCESS] Recycle Bin initialized successfully at $RECYCLE_DIR"
    return 0
}

# Para executar a função quando o script é chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    initialize_recyclebin
fi
