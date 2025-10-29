#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$PROJECT_ROOT/recycle_bin.sh"

while true; do
    ACTION=$(zenity --list --title="Recycle Bin Manager" \
        --column="Action" --width=400 --height=300 \
        "Initialize Recycle Bin" \
        "Delete File(s)" \
        "List Files in Recycle Bin" \
        "Preview File" \
        "Restore File" \
        "Exit")

    case "$ACTION" in
        "Initialize Recycle Bin")
            output=$("$SCRIPT")
            zenity --info --title="Initialization" --text="$output"
            ;;

        "Delete File(s)")
            FILES=$(zenity --file-selection --multiple --title="Select Files to Delete")
            if [[ -n "$FILES" ]]; then
                IFS="|" read -r -a FILE_ARRAY <<< "$FILES"
                output=$("$SCRIPT" delete "${FILE_ARRAY[@]}")
                zenity --text-info --title="Deletion Result" --width=600 --height=400 --filename=<(echo "$output")
            fi
            ;;

        "List Files in Recycle Bin")
            output=$("$SCRIPT" list)
            zenity --text-info --title="Recycle Bin Contents" --width=800 --height=400 --filename=<(echo "$output")
            ;;

        "Preview File")
            FILE_ID=$(zenity --entry --title="Preview File" --text="Enter File ID:")
            [[ -n "$FILE_ID" ]] && output=$("$SCRIPT" preview "$FILE_ID") && \
                zenity --text-info --title="File Preview" --width=600 --height=400 --filename=<(echo "$output")
            ;;

        "Restore File")
            FILE_ID=$(zenity --entry --title="Restore File" --text="Enter File ID or Name:")
            [[ -n "$FILE_ID" ]] && output=$("$SCRIPT" restore "$FILE_ID") && \
                zenity --info --title="Restore Result" --text="$output"
            ;;

        "Exit")
            break
            ;;
        *)
            break
            ;;
    esac
done
