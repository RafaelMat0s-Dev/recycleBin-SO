#!/bin/bash



# GLOBAL VARIABLES
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="$PROJECT_ROOT/bashFunctions"


# source "$FUNCTIONS_DIR/deleteFiles.sh"
# source "$FUNCTIONS_DIR/listRecycled.sh"
# source "$FUNCTIONS_DIR/restoreFile.sh"
# source "$FUNCTIONS_DIR/previewFile.sh"
# source "$FUNCTIONS_DIR/search_recycle.sh"

log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

delete_file() {

    local RECYCLE_DIR="$HOME/.recycle_bin"
    local FILES_DIR="$RECYCLE_DIR/files"
    local METADATA_FILE="$RECYCLE_DIR/metadata.csv"
    local CONFIG_FILE="$RECYCLE_DIR/config"
    local LOG_FILE="$RECYCLE_DIR/recyclebin.log"

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
        echo "          Skipping re-initialization to avoid overwriting dataaaaa"
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



list_recycled() {
	: "${RECYCLE_DIR:="$HOME/.recycle_bin"}"
	: "${FILES_DIR:="$RECYCLE_DIR/files"}"
	: "${METADATA_FILE:="$RECYCLE_DIR/metadata.csv"}"
	: "${LOG_FILE:="$RECYCLE_DIR/recyclebin.log"}"

	local detailedOption=false
	[[ "$1" == "--detailed" ]] && detailedOption=true

	if [[ ! -s "$METADATA_FILE" ]]; then
		echo "[INFO] Recycle Bin is empty."
		log "INFO" "User listed recycle bin: empty"
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
		
		# Skip empty or invalid lines
		if [[ -z "$id" || "$id" == "ID" ]]; then
			continue
		fi

		total_count=$((total_count + 1))
		total_size=$((total_size + file_size))

		# Convert file size to human-readable
		local hr_size
		if command -v numfmt &>/dev/null; then
			hr_size=$(numfmt --to=iec --suffix=B "$file_size")
		else
			hr_size="${file_size}B"
		fi

		# Display info
		if [[ "$detailedOption" == true ]]; then
			echo "🆔 ID:           $id"
			echo "📄 Name:         $original_name"
			echo "📂 Original Path: $original_path"
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

	# Summary
	echo ""
	echo "Total items: $total_count"
	if command -v numfmt &>/dev/null; then
		echo "Total size: $(numfmt --to=iec --suffix=B "$total_size")"
	else
		echo "Total size: ${total_size}B"
	fi

	log "INFO" "Listed $total_count items (total size: ${total_size}B)"
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





initialize_recyclebinupdated() {
    # Clear any old function
    unset -f initialize_recyclebin 2>/dev/null

    # Source the file to load the function
    source "$FUNCTIONS_DIR/initialize_recyclebin.sh"

    # Call the function
    initialize_recyclebin
}



main() {

    case "$1" in
        "" )
            echo "[INFO] Initializing Recycle Bin..."
            initialize_recyclebinupdated
            ;;
        
        delete )
            shift
            delete_file "$@"
            ;;
        
        list )
            shift
            list_recycled "$@"
            ;;
        
        restore )
            shift
            restore_file "$@"
            ;;
        
        preview )
            shift
            preview_file "$@"
            ;;
        
        # search )
        #     shift
        #     search_recycle "$@"
        #     ;;
        
    esac


}

main "$@"