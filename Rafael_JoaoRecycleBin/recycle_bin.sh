#!/bin/bash
#################################################
# recycle_bin.sh - Main Script
#################################################

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="$PROJECT_ROOT/bashFunctions"

# === Source only the scripts that define functions, not the initialize script ===
source "$FUNCTIONS_DIR/deleteFiles.sh"
source "$FUNCTIONS_DIR/listRecycled.sh"
source "$FUNCTIONS_DIR/restoreFile.sh"
source "$FUNCTIONS_DIR/previewFile.sh"
source "$FUNCTIONS_DIR/search_recycle.sh"

initialize_recyclebinupdated() {
    # Instead of running bash <file>, do this:

    unset -f initialize_recyclebin 2>/dev/null  # clear old function if it exists
    source "$FUNCTIONS_DIR/initialize_recyclebin.sh"
    initialize_recyclebin

}

# === Main Command Routing ===
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
    
    * )
        echo "[ERROR] Unknown command: $1"
        echo "Usage:"
        echo "  ./recycle_bin.sh                     # Initialize"
        echo "  ./recycle_bin.sh delete file1.txt    # Delete files"
        echo "  ./recycle_bin.sh list [--detailed]   # List files"
        echo "  ./recycle_bin.sh restore <fileID>    # Restore file"
        echo "  ./recycle_bin.sh preview <filename>  # Preview file"
        echo "  ./recycle_bin.sh search <pattern>    # Search files"
        ;;
esac
