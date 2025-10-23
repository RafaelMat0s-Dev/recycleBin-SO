#!/bin/bash

#################################################
# Script Query Comment
# Author: Joao Miguel Padrao
# Date: 2025-10-18
# Description: Creating the function that search a delete file 
# Version: 1.0
#################################################

#################################################
# Function: search_recycle()
# Description: Search in the file's folder from a file or a pattern and for each file extracts the file code saved in metadata.bd,the type, the basename, the size and the owner~/
# Parameters: This function has as paramter a name of a file or a pattern, it run like ./recycle_bin.sh "*.txt* (for instance)
# Returns: 0 on success, 1 on failure (in case the file config doesn't exists or the paramters doesn't mach with any of files)
#################################################

CONFIG_FILE_DIR="../ConfigRecycle.txt"
search_recycle() {
	
	#import global variable from config
	if [[ -f "$CONFIG_FILE_DIR" ]]; then
    		source "$CONFIG_FILE_DIR"
	else
    		echo "[ERROR] Config file not found: $CONFIG_FILE_DIR" >&2
    		return 1
	fi
	
	cd $FILE_DIR
	fileSearch=( $( find . -iname $1 ) )
	#Save the files in a array(-iname means Case-Insensitive)
	
	if [[ ${#fileSearch[@]} = 0 ]]; 
	do
		echo "[ERROR] File do not exist ou do not exist file with such paramters"
		return 1
	done
	
	#fazer tabela
	printf "%-10s %-40s %-20s %-10s %-40s\n" "Codigo" "Ficheiro" "Tipo de Ficheiro" "Tamanho" "Owner"
	for f in "${fileSearch[@]}"; do
		fileCode=( $( grep f $METADATA_FILE | awk '{print $1}'))
		fileSpace=( $( ls -ldh f | awk '{print $5}' ))
		fileType=( $( ls -ldh f | awk '{print $1}' | cut -c1 ))
		fileOwner=( $( ls -ldh f  | awk '{print $3}' ))
		if [[ $fileType = '-' ]];
		then
			fileType='f'
		fi
		printf "%-10s %-40s %-20s %-20s %-20s\n" "$fileCode" "$f" "$fileSpace" "$fileType" "$fileOwner"
	done
	#registar do log
	echo "$(date '+%Y-%m-%d %H:%M:%S') [SEARCH] Search done by $1" >> "$LOG_FILE"
}
