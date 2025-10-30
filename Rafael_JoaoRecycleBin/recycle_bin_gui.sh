#!/bin/bash


PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$PROJECT_ROOT/recycle_bin.sh"

# --- Helper Functions for Consistent UI ---
show_info()    { zenity --info --title="Info" --text="$1" 2>/dev/null; }
show_error()   { zenity --error --title="Error" --text="$1" 2>/dev/null; }
show_output()  { zenity --text-info --title="$1" --width=800 --height=400 --filename=<(echo "$2") 2>/dev/null; }
confirm_action() {
    zenity --question --title="Confirm" --text="$1" 2>/dev/null
}

# --- Main Menu Loop ---
while true; do
    ACTION=$(zenity --list --title="🗑️ Recycle Bin Manager" \
        --column="Select an Action" --width=420 --height=350 \
        "🧰 Initialize Recycle Bin" \
        "🗑️ Delete File(s)" \
        "📂 List Files in Recycle Bin" \
        "👁️ Preview File" \
        "♻️ Restore File" \
        "🚪 Exit" 2>/dev/null)

    [[ $? -ne 0 ]] && break  # user pressed cancel

    case "$ACTION" in
        "🧰 Initialize Recycle Bin")
            output=$("$SCRIPT" 2>&1)
            if [[ $? -eq 0 ]]; then
                show_output "Initialization Result" "$output"
            else
                show_error "$output"
            fi
            ;;

        "🗑️ Delete File(s)")
            FILES=$(zenity --file-selection --multiple --separator="|" --title="Select Files to Delete" 2>/dev/null)
            [[ -z "$FILES" ]] && continue
            confirm_action "Are you sure you want to delete the selected file(s)?"
            [[ $? -ne 0 ]] && continue

            IFS="|" read -r -a FILE_ARRAY <<< "$FILES"
            output=$("$SCRIPT" delete "${FILE_ARRAY[@]}" 2>&1)
            [[ $? -eq 0 ]] && show_output "Deletion Result" "$output" || show_error "$output"
            ;;

        "📂 List Files in Recycle Bin")
            output=$("$SCRIPT" list 2>&1)
            if [[ $? -eq 0 ]]; then
                show_output "Recycle Bin Contents" "$output"
            else
                show_error "$output"
            fi
            ;;

        "👁️ Preview File")
            FILE_ID=$(zenity --entry --title="Preview File" --text="Enter File ID to preview:" 2>/dev/null)
            [[ -z "$FILE_ID" ]] && continue

            output=$("$SCRIPT" preview "$FILE_ID" 2>&1)
            [[ $? -eq 0 ]] && show_output "File Preview" "$output" || show_error "$output"
            ;;

        "♻️ Restore File")
            FILE_ID=$(zenity --entry --title="Restore File" --text="Enter File ID or File Name to restore:" 2>/dev/null)
            [[ -z "$FILE_ID" ]] && continue

            confirm_action "Are you sure you want to restore this file?"
            [[ $? -ne 0 ]] && continue

            output=$("$SCRIPT" restore "$FILE_ID" 2>&1)
            [[ $? -eq 0 ]] && show_info "$output" || show_error "$output"
            ;;

        "🚪 Exit")
            break
            ;;
    esac
done
