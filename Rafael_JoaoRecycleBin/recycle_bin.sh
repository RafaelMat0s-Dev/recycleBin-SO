#!/bin/bash

# GLOBAL VARIABLES
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="$PROJECT_ROOT/bashFunctions"
CONFIG_FILE="./ConfigRecycle.txt"

#################################################
# Log Function - Helper Function to Log Messages to Avoid Repeating the Code
# Author: Rafael da Costa Matos
# Date: 2025-10-18
# Version: 1
# Parameters $1 level (Error, Success etc...) // $2 $message (Actual Message)
# Returns: Doesn't Return any value, only echoes
#################################################

log() {
    [[ -d "$(dirname "$LOG_FILE")" ]] || mkdir -p "$(dirname "$LOG_FILE")"
    [[ -f "$LOG_FILE" ]] || touch "$LOG_FILE"
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

# -------------------------------------------------------------------
#################################################
# get_file_date_sec -  helper in the show_statistic function to get the delection date from the metadate file
# Author: João Miguel Padrão Neves
# Date: 2025-10-28
# Version: 1
# Parameters: $1 -> the absolut path of the file
# Returns: Gives the delection date of the file given as argument 
#################################################

# Função para obter a data em segundos do arquivo no METADATA_FILE
get_file_date_sec() {
    local file="$1"
    local date_str
    date_str=$(grep -m1 ",$(basename "$file")," "$METADATA_FILE" | awk -F',' '{print $4}')
    date -d "$date_str" +%s
}

# -------------------------------------------------------------------
#################################################
# Delete File
# Author: Rafael da Costa Matos
# Date: 2025-10-18
# Last Version: 1.3
# Parameters $1...$N -> (File/Directory names to Delete)
# Returns: $0 on Sucess, $1 on Any Type of Error
# Description:
#       Function Created according to the rules in order to delete single/multiple_files
#################################################

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
        initialize_recyclebinupdated
        return 1
    fi

    for target in "$@"; do
        if [[ ! -e "$target" ]]; then
            echo "[ERROR] FILE or DIRECTORY not found: $target" >&2
            log "ERROR" "File/Directory not found: $target"
            continue
        fi

        local parent_dir
        parent_dir=$(dirname "$target")

        # Check if we have write & execute permissions in the parent directory
        if [[ ! -w "$parent_dir" || ! -x "$parent_dir" ]]; then
            echo "[ERROR] Cannot delete $target: no permission on parent directory" >&2
            log "ERROR" "Permission denied for $target (parent directory)"
            continue
        fi

        # Prevent the deletion of read-only files
        if [[ -f "$target" && ! -w "$target" ]]; then
            echo "[ERROR] Cannot delete $target: file is read-only" >&2
            log "ERROR" "File is read-only: $target"
            continue
        fi

        # For directories, ensure we can access for execution permission 
        if [[ -d "$target" && ! -x "$target" ]]; then
            echo "[ERROR] Cannot delete directory $target: no execute permission" >&2
            log "ERROR" "Cannot access directory: $target"
            continue
        fi

        # Generate unique ID for file so it doesn't confuse with the namaFile(in case there's duplicate fileNames)
        local id
        id=$(uuidgen 2>/dev/null || date +%s%N)
        local base_name
        base_name=$(basename "$target")
        local abs_path
        abs_path=$(realpath "$target")
        local dest_path="$FILES_DIR/$id"

        # Determine size of the file and type of the file
        local file_size file_type perms owner
        if [[ -d "$target" ]]; then
            file_type="directory"
            file_size=$(du -sb "$target" | cut -f1)
        else
            file_type="file"
            file_size=$(stat -c %s "$target")
        fi

        # Determine the permissions of the file
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


# -------------------------------------------------------------------
#################################################
# Initialize Recycle Bin Folder / SubArchives and Folders
# Author: Rafael da Costa Matos
# Date: 2025-10-16
# Last Version: 1.3
# Parameters: Doesn't Receive Any parameters and the script is called from the Source ./recycle_bin.sh
# Returns: $0 on Sucess, $1 on Any Type of Error + automatic Logs on the recyclelog file
# Description:
#       Function Created according to the rules in order as the base initialization of ~/.recycle_bin
#################################################

initialize_recyclebin() {
    local RECYCLE_DIR="$HOME/.recycle_bin"
    local FILES_DIR="$RECYCLE_DIR/files"
    local METADATA_FILE="$RECYCLE_DIR/metadata.csv"
    local CONFIG_FILE="$RECYCLE_DIR/config"
    local LOG_FILE="$RECYCLE_DIR/recyclebin.log"

    # Verify the $HOME env variable to see if it's valid
    if [[ -z "$HOME" || ! -d "$HOME" ]]; then
        echo "[ERROR] Home environment variable is not set or invalid" >&2
        return 1
    fi

    # Avoids Overwriting if RecycleBin Already Exists
    if [[ -d "$RECYCLE_DIR" ]]; then
        echo "[WARNING] Recycle bin already exists at $RECYCLE_DIR"
        echo "          Skipping re-initialization to avoid overwriting data"
        return 0
    fi

    echo "[INFO] Initializing Recycle Bin at: $RECYCLE_DIR"

    # Creates the subdirectory structure
    mkdir -p "$FILES_DIR"
    if [[ $? -ne 0 || ! -d "$FILES_DIR" ]]; then
        echo "[ERROR] Failed to create directory structure at: $FILES_DIR" >&2
        return 1
    fi

    # Creates the metadata.csv file if it doesn't exist (with header)
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

    # Creates the Config File for MAX_SIZE_MB and RETENTION_DAYS (Amount of time file) used  in auto cleanup and check_quota
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

    # Reads the COnfigurations
    local MAX_SIZE RETENTION
    MAX_SIZE=$(grep -E '^MAX_SIZE_MB=' "$CONFIG_FILE" | cut -d'=' -f2)
    RETENTION=$(grep -E '^RETENTION_DAYS=' "$CONFIG_FILE" | cut -d'=' -f2)

    # Makes sure the configuration are valid
    if [[ -z "$MAX_SIZE" || "$MAX_SIZE" =~ [^0-9] ]]; then
        echo "[ERROR] Invalid MAX_SIZE_MB value in config: '$MAX_SIZE'" >&2
        return 1
    fi
    if [[ -z "$RETENTION" || "$RETENTION" =~ [^0-9] ]]; then
        echo "[ERROR] Invalid RETENTION_DAYS value in config: '$RETENTION'" >&2
        return 1
    fi

    # Creates the Log file if it doesn't exist
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
        if [[ $? -ne 0 ]]; then
            echo "[ERROR] Failed to create recyclebin.log at $LOG_FILE" >&2
            return 1
        fi
        echo "[INFO] Created recyclebin.log"
    fi

    # Verifies writing permissions on log file
    if [[ ! -w "$LOG_FILE" ]]; then
        echo "[ERROR] recyclebin.log is not writable at $LOG_FILE" >&2
        return 1
    fi

    # Writes to Log File (Don't forget to change this after creation of Log function)
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INIT] Recycle Bin initialized successfully" >> "$LOG_FILE"

    echo "[SUCCESS] Recycle Bin initialized successfully at $RECYCLE_DIR"
    return 0
}



# -------------------------------------------------------------------
#################################################
# List Recycled
# Author: Rafael da Costa Matos
# Date: 2025-10-19
# Last Version: 1.2 
# Parameters: Can Receive 1 or Zero Parameters dependant on the mode ($1 receives de --detailed flag)
# Returns: $0 on Sucess, $1 on Any Type of Error + automatic Logs on the recyclelog file
# Description:
#################################################



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

	echo ""
	echo "Total items: $total_count"
	if command -v numfmt &>/dev/null; then
		echo "Total size: $(numfmt --to=iec --suffix=B "$total_size")"
	else
		echo "Total size: ${total_size}B"
	fi

	log "INFO" "Listed $total_count items (total size: ${total_size}B)"
}


# -------------------------------------------------------------------
#################################################
# Preview File
# Author: Rafael da Costa Matos
# Date: 2025-10-22
# Last Version: 1.2 
# Parameters: $1 Receives the File ID that wants to be previewed
# Returns: $0 on Sucess, $1 on Any Type of Error + automatic Logs on the recyclelog file
# Description:
#################################################


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

# -------------------------------------------------------------------
#################################################
# Restore File
# Author: Rafael da Costa Matos
# Date: 2025-10-19
# Last Version: 1.2 
# Parameters: $1 Receives either FileID or the FileName needed to restore file to current location
# Returns: $0 on Sucess, $1 on Any Type of Error + automatic Logs on the recyclelog file
# Description:
#       Function Created according to the rules in order as the base initialization of ~/.recycle_bin
#################################################


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


    if [[ ! -e "$source_path" ]]; then
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

    chmod "$perms" "$dest_path" 2>/dev/null
    chown "$owner" "$dest_path" 2>/dev/null


    grep -v "^$id," "$METADATA_FILE" > "${METADATA_FILE}.tmp" && mv "${METADATA_FILE}.tmp" "$METADATA_FILE"

    echo "[SUCCESS] File '$original_name' restore to '$dest_path'"
    log "RESTORE_SUCCESS" "Restored $original_name ($id) -> $dest_path"
    
}

# -------------------------------------------------------------------
#################################################
# Empty Recycle Bin
# Author: Joao Miguel Padrao
# Date: 2025-10-18
# Last Version: 1.0
# Parameters: This function has as paramter a file unique ID or the parameter 'all' or nothing to delete everything or the flag '--force' to skip confirmation, it run like "./recycle_bin.sh empty --force all" (for instance)
# Returns: 0 on success, 1 on failure (in case the file config doesn't exists or the ID doesn't mach with any of files or the user abort the process or an invalid caracter in the confirmation)
# Description: 
# Delete a file by a unique ID or delete everything and give a confirmation before proceed (we can use the flag --force to dont make any confirmation)
#################################################

empty_recyclebin() {
	
	: "${RECYCLE_DIR:="$HOME/.recycle_bin"}"
	: "${FILES_DIR:="$RECYCLE_DIR/files"}"
	: "${METADATA_FILE:="$RECYCLE_DIR/metadata.csv"}"
	: "${LOG_FILE:="$RECYCLE_DIR/recyclebin.log"}"
	shopt -s nullglob
	files=("$FILES_DIR"/*)
	shopt -u nullglob
	if [[ ${#files[@]} -eq 0 ]]; then
    	log "ERROR" "Recycle bin is already empty"
    	return 1
	fi
	argument=("$@")
	skip=0
	for i in "${!argument[@]}"; do
		if [[ "${argument[i]}" == "--force" ]]; then
			skip=1
			unset 'argument[i]'
			break
		fi
	done
	argument=("${argument[@]}")
	#=====================
	if [[ $skip -eq 0 ]]; then
		echo -e "Permanently deleted files cannot be restore\nDo you wish to continue[Y/n]?"
		read -r answer
		if [[ "${answer,,}" == "n" ]]; then
			echo "Abort process"
			return 1
		elif [[ "${answer,,}" != "y" ]]; then
			echo "Invalid caracter"
			return 1
		fi
	fi
	#====================
	#Cheking the arguments(if there's nothing or "all")
	
	if [[ "${#argument[@]}" -eq 0 || "${argument[0]}" == "all" ]]; then
		#remove files
		shopt -s nullglob
		for f in "$FILES_DIR"/*; do
    		rm -rf "$f"
    		echo -e "$(basename "$f") deleted successfully!\n"
		done
		shopt -u nullglob
		#clear the metadata.bd file
		head -n 1 "$METADATA_FILE" > "$METADATA_FILE.tmp"
		mv "$METADATA_FILE.tmp" "$METADATA_FILE"
		#write on log file and make the return
		log "EMPTY" "Successfully deleted all files"	
		return 0
	fi
	#====================
	#Checking the arguments individually
	error=0
	deletedFiles=0
	for fileID in "${argument[@]}"; do
		file=$( grep "$fileID" "$METADATA_FILE" | awk -F',' '{print $2}')
		if [[ -z "$file" ]]; then
			echo "[ERROR] File ID unknown: $fileID"
			((error++))
    		continue
		fi
		filePath="$FILES_DIR/$file"
		if [[ ! -e "$filePath" ]]; then
    		echo "[ERROR] File not found: $file"
			((error++))
    		continue
		fi
		rm -rf "$filePath"
		echo -e "$file deleted successfully!\n"
		((deletedFiles++))
		#remove file in metadata file
		sed -i "/^$fileID,/d" "$METADATA_FILE"
		#write on log file and make the return
		
	done
	if (( error > 0 && error != "${#argument[@]}" )); then
		log "ERROR" "Function empty_recycle couldn't delete $error files"
		log "EMPTY" "Successfully deleted $deletedFiles files"
		return 1
	elif (( error == "${#argument[@]}" )); then
		log "ERROR" "Function empty_recycle couldn't delete any of the files"
		return 1
	fi
	log "EMPTY" "Successfully deleted all files"
	return 0
	#====================
}

# -------------------------------------------------------------------
#################################################
# Search recycle
# Author: Joao Miguel Padrao
# Date: 2025-10-18
# Last Version: 1.1 (corrected)
# Parameters:
#   A filename or pattern (e.g. "*.txt")
# Returns:
#   0 on success, 1 on failure
# Description:
#   Function that searches deleted files in recycle bin
#   Search for a file or pattern in the recycle bin and display:
#   ID, name, type, size, and owner (from metadata.db)
#################################################

search_recycle() {
	
	: "${RECYCLE_DIR:="$HOME/.recycle_bin"}"
	: "${FILES_DIR:="$RECYCLE_DIR/files"}"
	: "${METADATA_FILE:="$RECYCLE_DIR/metadata.csv"}"
	: "${LOG_FILE:="$RECYCLE_DIR/recyclebin.log"}"

	if [[ -z "$1" ]]; then
		echo "[ERROR] Missing search pattern. Usage: ./recycle_bin.sh search <pattern>" >&2
		return 1
	fi

	local pattern="$1"

	cd "$FILES_DIR" || {
		echo "[ERROR] Cannot access recycle bin files directory: $FILES_DIR" >&2
		return 1
	}

	# Find matching files (case insensitive)
	mapfile -t fileSearch < <(find . -iname "$pattern")

	# If no matches found
	if [[ ${#fileSearch[@]} -eq 0 ]]; then
		echo "[ERROR] No files found matching pattern '$pattern'"
		return 1
	fi

	# Print table header
	printf "%-36s %-30s %-10s %-10s %-20s\n" "UNIQUE_ID" "FILENAME" "TYPE" "SIZE" "OWNER"
	echo "------------------------------------------------------------------------------------------"

	for f in "${fileSearch[@]}"; do
		local file_id
		file_id=$(basename "$f")

		# Find the line in metadata
		local metadata_line
		metadata_line=$(grep -m 1 "$file_id" "$METADATA_FILE")

		if [[ -z "$metadata_line" ]]; then
			continue
		fi

		IFS=',' read -r id original_name original_path deletion_date file_size file_type permissions owner <<< "$metadata_line"

		local hr_size
		if command -v numfmt &>/dev/null; then
			hr_size=$(numfmt --to=iec --suffix=B "$file_size")
		else
			hr_size="${file_size}B"
		fi

		printf "%-36s %-30s %-10s %-10s %-20s\n" "$id" "$original_name" "$file_type" "$hr_size" "$owner"
	done

	# Log search operation
	echo "$(date '+%Y-%m-%d %H:%M:%S') [SEARCH] Search executed for pattern '$pattern'" >> "$LOG_FILE"

	return 0
}

# -------------------------------------------------------------------
#################################################
# Display help
# Author: João Miguel Padrão Neves
# Date: 2025-10-18
# Last Version: 1.0
# Parameters: None
# Returns: It doesn't return any vallue
# Description: 
#   Function to present the features 
#   Provide informations about how to use the Recycle Bin (~)
#################################################

display_help() {
    echo -e "Use: ./recycle_bin [option] [Flags] [File/id]\n"
    echo -e "Recycle Bin Commands:\n"
    echo -e "Options:\n"
    echo -e "   'delete' -> Moves a file(s) to the recycle but do not delete it permanently. Acept as argument a file or a path\n"
    echo -e "       Examples:\n
                            ->./recycle_bin.sh delete myfile.txt\n
                            ->./recycle_bin.sh delete file1.txt file2.txt directory/\n"
    echo -e "   'list' -> Shows all the files in the recycle bin\n"
    echo -e "       -> To see in detail mode use the flag '--detail'\n" 
    echo -e "       Examples:\n
                            ->./recycle_bin.sh list\n
                            ->./recycle_bin.sh list --detailed\n"
    echo -e "   'restore' -> Moves the file in recycle to the original path, where it was before being move. Acept as argument a file or a ID of a file\n" 
    echo -e "       Examples:\n
                            ->./recycle_bin.sh restore 1696234567_abc123\n
                            ->./recycle_bin.sh restore myfile.txt\n"
    echo -e "   'search' -> Confirm if the file is in the recycle. Acept as argument a file or a pattern\n"
    echo -e "       Examples:\n
                            ->./recycle_bin.sh search \"report\"\n
                            ->./recycle_bin.sh search \"\*.pdf\"\n"
    echo -e "   'empty' -> Delete permanently a file or all de recycle\n"
    echo -e "       -> It will ask for permission.To skip that use the flag '--force'\n" 
    echo -e "       -> You can use 'all' or write nothing to delete all the file in the recycle" 
    echo -e "       Examples:\n
                            ->./recycle_bin.sh empty\n
                            ->./recycle_bin.sh empty 1696234567_abc123\n
                            ->./recycle_bin.sh empty --force\n"
    echo -e "   'status' -> Shows information about the recycle bin:\n"
    echo -e "       ->" 
    echo -e "       Examples:\n
                            ->./recycle_bin.sh status"    
    return 0
}

# -------------------------------------------------------------------
#################################################
# Show_statistic
# Author: João Miguel Padrão Neves
# Date: 2025-10-28
# Last Version: 1.0
# Parameters: None
# Returns: 0
# Description:
#   Function to show statistics 
#   Show informations about the recycle like the number of files the oldest the newest the heavier and show which files are diretories or files
#################################################

show_statistic() {
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
        if (( fileSize > fileHeavierSize )); then
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

        if (( fileDate > mostRecentDate )); then
            mostRecentDate=$fileDate
            mostRecentFile="$f"
        fi

        if (( fileDate < olderDate )); then
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

# -------------------------------------------------------------------
#################################################
# auto_cleanup
# Author: Joao Miguel Padrao
# Date: 2025-10-30
# Last Version: 1.0
# Parameters: This function can have the paramter test to make it easier to test, changing the MAX_SIZE_MB to a smaller number
# Returns: 0 on success
# Description: 
#   Checks if the Recycle has any file, that is in recycle more time than the number of days saved in the global variable RETENTION_DAYS and if it does delete it   
#   Cleans every file that is keep in recycle for too long
#################################################

auto_cleanup() {

    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    [[ -f "$METADATA_FILE" ]] || { echo "[ERROR] metadata.csv not found"; return 1; }

    if [[ "$1" == "test" ]]; then
        RETENTION_DAYS=1
        MAX_SIZE_MB=1
    fi

    if [[ -z "$RETENTION_DAYS" ]]; then
    RETENTION_DAYS=$(grep '^RETENTION_DAYS=' "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '"[:space:]')
    fi

    if [[ -z "$MAX_SIZE_MB" ]]; then
        MAX_SIZE_MB=$(grep '^MAX_SIZE_MB=' "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '"[:space:]')
    fi

    # Validate both are loaded
    if [[ -z "$RETENTION_DAYS" || -z "$MAX_SIZE_MB" ]]; then
        echo "[ERROR] RETENTION_DAYS or MAX_SIZE_MB not found in $CONFIG_FILE" >&2
        return 1
    fi

    echo "Current Max Size of Files - $MAX_SIZE_MB"
    echo "Current Retention Days Period - $RETENTION_DAYS"



    local curdate=$(date +%s)
    local curdateDays=$(( curdate / 86400 ))
    local deleted=0
    files=("$FILES_DIR"/*)
    for f in "${files[@]}" ; do
        [[ -e "$f" ]] || continue #<-
        file_id=$(basename "$f")
        fileDate=$(grep "^$file_id," "$METADATA_FILE" | awk -F',' '{print $4}')
        
        [[ -z "$fileDate" ]] && continue
        
        ts=$(date -d "$fileDate" +%s)
        fileDateDays=$(( ts / 86400 ))
        if (( curdateDays - fileDateDays >= RETENTION_DAYS )); then
            rm -rf "$f"
            sed -i "/^$file_id,/d" "$METADATA_FILE"
            echo "[INFO] File $f auto-deleted successfully"
            ((deleted++))
        fi
    done

    if (( deleted == 0 )); then
        log "CLEANUP" "Recycle Bin is already optimized"
    else
        log "CLEANUP" "Recycle Bin optimized successfully ($deleted files removed)"
    fi

    echo "[INFO] All files are within RETENTION DAYS Parameteres"
    return 0
}


# -------------------------------------------------------------------
#################################################
# check_quota
# Author: Joao Miguel Padrao
# Date: 2025-10-30
# Last Version: 1.0
# Parameters: This function can have the paramter test to make it easier to test, changing the MAX_SIZE_MB to a smaller number
# Returns: 
#   0 on success
#   1 on failure (in case of the recycle is still full even after we make a auto-cleanup or the user abort the process or an invalid caracter in the confirmation)
# Description: 
#   Checks if the Recycle size exceeds the global variable MAX_SIZE_MB and if it does the program ask the user if he can do a optimization(auto clean)
#   Checks if the Recycle bin is full 
#################################################

check_quota() {

    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    [[ -f "$METADATA_FILE" ]] || { 
        echo "[ERROR] metadata.csv not found in $RECYCLE_DIR" >&2
        return 1 
    }
    [[ -d "$FILES_DIR" ]] || {
        echo "[ERROR] Files directory $FILES_DIR not found" >&2
        return 1
    }
    if [[ "$1" == "test" ]]; then
        MAX_SIZE_MB=1
    fi

    if [[ -z "$MAX_SIZE_MB" ]]; then
        if grep -q '^MAX_SIZE_MB=' "$CONFIG_FILE"; then
            MAX_SIZE_MB=$(grep '^MAX_SIZE_MB=' "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '"')
        else
            echo "[ERROR] MAX_SIZE_MB not found in $CONFIG_FILE" >&2
            return 1
        fi
    fi
    
    local fileDirSize
    fileDirSize=$(du -sm "$FILES_DIR" | cut -f1)

    if (( fileDirSize >= MAX_SIZE_MB )); then
        log "WARN" "Recycle bin is full!"
        echo "Recycle bin is full. Proceed with optimization (Y/n)?"
        read -r anwser

        if [[ "${anwser,,}" == "y" ]]; then
            echo "$MAX_SIZE_MB"
            auto_cleanup "$@"
            fileDirSize=$(du -sm "$FILES_DIR" | cut -f1)
            echo "$fileDirSize"
            echo "$MAX_SIZE_MB"
            if (( fileDirSize >= MAX_SIZE_MB )); then
                echo "[ERROR] Recycle bin is still full after optimization."
                log "ERROR" "Recycle bin still full after cleanup"
                return 1
            fi
        elif [[ "${anwser,,}" == "n" ]]; then
            echo "Operation aborted."
            return 1
        else
            echo "Invalid character."
            return 1
        fi
    fi

    echo "[CHECK] Recycle bin usage within limit"
    log "CHECK" "Recycle bin usage within limit."
    return 0
}

# -------------------------------------------------------------------
#################################################
# Initialize Recycle Bin Updated
# Author: Rafael da Costa Matos
# Date: 2025-10-19
# Last Version: 1.2 
# Parameters: Doesn't Receive any Parameter
# Returns: It's a void function so it doesn't return anything
# Description:
#       This was a function created because of a bug i was having because of files being created before the initialization of the recycle bin and so this function was created 
#       for debugging
#################################################

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
        
        search )
            shift
            search_recycle "$@"
            ;;
        empty )
            shift
            empty_recyclebin "$@"
            ;;
        help | --help | -h )
            shift
            display_help "$@"
            ;;
        status )
            shift
            show_statistic "$@"
            ;;
        clean )
            shift
            auto_cleanup "$@"
            ;;
        check )
            shift
            check_quota "$@"
            ;;
        * ) 
            echo "./recycle_bin: Invalid option -- $1"        
    esac


}

main "$@"