#!/bin/bash
# ============================================================
# Recycle Bin Test Suite
# Author: Rafael da Costa Matos
# ============================================================

SCRIPT="./recycle_bin.sh"
FILES_DIR="$HOME/.recycle_bin/files"
TEST_DIR="test_data"
PASS=0
FAIL=0

# ============================================================
# Color setup for readable output
# ============================================================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================
# Helper Functions
# ============================================================
setup() {
    rm -rf "$TEST_DIR" "$HOME/.recycle_bin"
    mkdir -p "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
    rm -rf "$HOME/.recycle_bin"
}

log_section() {
    echo -e "\n${CYAN}=== $1 ===${NC}"
}

assert_success() {
    local message="$1"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        ((FAIL++))
    fi
}

assert_fail() {
    local message="$1"
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        ((FAIL++))
    fi
}

# ============================================================
# === BASIC TEST CASES (run by default)
# ============================================================

test_initialization() {
    log_section "Test: Initialization"
    setup
    $SCRIPT init > /dev/null 2>&1
    assert_success "Initialize recycle bin"
    [ -d "$HOME/.recycle_bin" ] && echo "✓ Directory structure created"
    teardown
}

test_delete_single_file() {
    log_section "Test: Delete Single File"
    setup
    echo "test content" > "$TEST_DIR/test.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/test.txt" > /dev/null 2>&1
    assert_success "Delete existing file"
    [ ! -f "$TEST_DIR/test.txt" ] && echo "✓ File removed from original location"
    teardown
}

test_list_empty() {
    log_section "Test: List Empty Bin"
    setup
    $SCRIPT list | grep -q "empty"
    assert_success "List empty recycle bin"
    teardown
}

test_restore_single_file() {
    log_section "Test: Restore Single File"
    setup
    echo "restore me" > "$TEST_DIR/restore_test.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/restore_test.txt" > /dev/null 2>&1
    local ID
    ID=$($SCRIPT list | grep "restore_test" | awk '{print $1}')
    $SCRIPT restore "$ID" > /dev/null 2>&1
    assert_success "Restore file from recycle bin"
    #this function works properly
    [ -f "$TEST_DIR/restore_test.txt" ] && echo "✓ File successfully restored"
    teardown
}

test_empty_single_file() {
    log_section "Test: Empty single file"
    setup
    echo "delete me" > "$TEST_DIR/emptySingleFile.txt" > /dev/null 2>&1
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/emptySingleFile.txt" > /dev/null 2>&1
    local ID
    ID=$($SCRIPT list | grep "emptySingleFile.txt" | awk '{print $1}')
    $SCRIPT empty --force "$ID" > /dev/null 2>&1
    assert_success "File deleted permanently"
    # Checks if the function works as properly
    #this function works properly
    if [ ! -e "$FILES_DIR/emptySingleFile_test.txt" ]; then
        echo "file deleted successfully"
    else
        echo "file not deleted"
    fi
    teardown
}

test_search_file() {
    log_section "Test: Search for a file"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    echo "c" > "$TEST_DIR/c.txt"
    echo "d" > "$TEST_DIR/d.txt"
    echo "e" > "$TEST_DIR/e.txt"
    echo "f" > "$TEST_DIR/f.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" "$TEST_DIR/c.txt" "$TEST_DIR/d.txt" "$TEST_DIR/e.txt" "$TEST_DIR/f.txt" > /dev/null 2>&1
    $SCRIPT search "d" > /dev/null 2>&1
    assert_success "Search for a file"
    teardown
}

test_display_help() {
    log_section "Test: display help(help)"
    setup
    $SCRIPT help > /dev/null 2>&1
    assert_success "Display help"
    teardown
}

# ============================================================
# === DETAILED / STRESS / EDGE CASE TESTS (run with --detailed)
# ============================================================

test_delete_multiple_files() {
    log_section "Test: Delete Multiple Files"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" > /dev/null 2>&1
    assert_success "Delete multiple files"
    teardown
}

test_delete_empty_directory() {
    log_section "Test: Delete Empty Directory"
    setup
    mkdir "$TEST_DIR/empty_dir"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/empty_dir" > /dev/null 2>&1
    assert_success "Delete empty directory"
    teardown
}

test_delete_directory_with_contents() {
    log_section "Test: Delete Directory With Contents"
    setup
    mkdir -p "$TEST_DIR/nested/dir"
    echo "inside" > "$TEST_DIR/nested/dir/file.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/nested" > /dev/null 2>&1
    assert_success "Delete directory recursively"
    teardown
}

test_restore_nonexistent_path() {
    log_section "Test: Restore to Nonexistent Path"
    setup
    mkdir -p "$TEST_DIR"
    echo "test" > "$TEST_DIR/file.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/file.txt" > /dev/null 2>&1
    local ID
    ID=$($SCRIPT list | grep "file.txt" | awk '{print $1}')
    rm -rf "$TEST_DIR"
    $SCRIPT restore "$ID" > /dev/null 2>&1
    assert_success "Restore recreates missing directories"
    teardown
}

test_delete_nonexistent_file() {
    log_section "Test: Delete Non-existent File"
    setup
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/missing.txt" > /dev/null 2>&1
    local exit_code=$?
    # Because this function was expected to fail then if it returns error code, it actually returns success
    if [[ $exit_code -ne 0 ]]; then
        assert_success "Delete non-existent file failed as expected"
    else
        assert_fail "Delete non-existent file unexpectedly succeeded"
    fi

    teardown
}

test_restore_invalid_id() {
    log_section "Test: Restore Invalid ID"
    setup

    $SCRIPT restore "00000000-0000-0000-0000-000000000000" > /dev/null 2>&1
    local exit_code=$?

    # Because this function was expected to fail then if it returns error code, it actually returns success
    if [[ $exit_code -ne 0 ]]; then
        assert_success "Restore with invalid ID failed as expected"
    else
        assert_fail "Restore with invalid ID unexpectedly succeeded"
    fi
    teardown
}

test_empty_empty() {
    log_section "Test: Empty recycle when it is already empty"
    setup
    $SCRIPT empty --force > /dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        assert_success "Empty an empty recycle bin return an error as expected "
    else
        assert_fail "Empty an empty recycle bin unexpectedly succeeded"
    fi
    teardown
}

test_empty_confirmation() {
    log_section "Test: Testing the confirmation"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    $SCRIPT > /dev/null 2>&1 > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" > /dev/null 2>&1
    IDa=$($SCRIPT list | grep "a.txt" | awk '{print $1}')
    echo "n" | $SCRIPT empty "$IDa" > /dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        assert_success "Abort proccess as expected"
    else
        assert_fail "Unexpectedly it didn't abort"
    fi
    teardown    
}

test_empty_recycle_without_arguments() {
    log_section "Test: empty Recycle without arguments"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    echo "c" > "$TEST_DIR/c.txt"
    echo "d" > "$TEST_DIR/d.txt"
    echo "e" > "$TEST_DIR/e.txt"
    echo "f" > "$TEST_DIR/f.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" "$TEST_DIR/c.txt" "$TEST_DIR/d.txt" "$TEST_DIR/e.txt" "$TEST_DIR/f.txt" > /dev/null 2>&1
    $SCRIPT empty --force > /dev/null 2>&1
    assert_success "Empty recycle without arguments"
    # Checks if the function works as properly
    #this function works properly
    if [ -z "$(ls -A "$FILES_DIR")" ]; then
        echo "Recycle is empty"
    else
        echo "Recycle is not empty"
    fi
    teardown
}

test_empty_recycle_with_all() {
    log_section "Test: empty Recycle using \"all\""
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    echo "c" > "$TEST_DIR/c.txt"
    echo "d" > "$TEST_DIR/d.txt"
    echo "e" > "$TEST_DIR/e.txt"
    echo "f" > "$TEST_DIR/f.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" "$TEST_DIR/c.txt" "$TEST_DIR/d.txt" "$TEST_DIR/e.txt" "$TEST_DIR/f.txt" > /dev/null 2>&1
    $SCRIPT empty --force all > /dev/null 2>&1
    assert_success "Empty recycle using all"
    # Checks if the function works as properly
    #this function works properly
    if [ -z "$(ls -A "$FILES_DIR")" ]; then
        echo "Recycle is empty"
    else
        echo "Recycle is not empty"
    fi
    teardown
}

test_empty_multiple_files() {
    log_section "Test: Delete permanently multiple files"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" > /dev/null 2>&1
    IDa=$($SCRIPT list | grep "a.txt" | awk '{print $1}')
    IDb=$($SCRIPT list | grep "b.txt" | awk '{print $1}')
    $SCRIPT empty --force "$IDa" "$IDb" > /dev/null 2>&1
    assert_success "Delete permanently multiple files"
    # Checks if the function works as properly
    #this function works properly
    if [ ! -e "$FILES_DIR/a.txt" ] && [ ! -e "$FILES_DIR/b.txt" ]; then
        echo "Files deleted successfully"
    else
        echo "Files not deleted"
    fi
    teardown
}

test_empty_empty_directory() {
    log_section "Test: Delete permanently a empty directory"
    setup
    mkdir "$TEST_DIR/empty_dir"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/empty_dir" > /dev/null 2>&1
    IDdir=$($SCRIPT list | grep "empty_dir" | awk '{print $1}') 
    $SCRIPT empty --force "$IDdir" > /dev/null 2>&1
    assert_success "Delete permanently an empty directory"
    # Checks if the function works as properly
    #this function works properly
    if [ ! -e "$FILES_DIR/empty_dir" ]; then
        echo "Empty folder deleted successfully"
    else
        echo "Empty folder not deleted"
    fi
    teardown
}

test_empty_directory_with_contents() {
    log_section "Test: Delete permanently a directory with content"
    setup
    mkdir -p "$TEST_DIR/nested/dir"
    echo "inside" > "$TEST_DIR/nested/dir/file.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/nested" > /dev/null 2>&1
    IDdir=$($SCRIPT list | grep "nested" | awk '{print $1}')
    $SCRIPT empty --force "$IDdir" > /dev/null 2>&1
    assert_success "Delete permanently a directory with content"
    # Checks if the function works as properly
    #this function works properly
    if [ ! -e "$FILES_DIR/nested" ]; then
        echo "Folder with content deleted successfully"
    else
        echo "Folder not deleted"
    fi
    teardown
}

test_empty_with_some_wrong_ids() {
    log_section "Test: Deleting files where one or more ids are invalid"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    echo "c" > "$TEST_DIR/c.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" "$TEST_DIR/c.txt" > /dev/null 2>&1
    IDa=$($SCRIPT list | grep "a.txt" | awk '{print $1}')
    IDb=$($SCRIPT list | grep "b.txt" | awk '{print $1}')
    IDc=$($SCRIPT list | grep "c.txt" | awk '{print $1}')
    rm -rf "$TEST_DIR/c.txt"
    $SCRIPT empty --force "$IDa" "$IDc" "$IDb" "00000000-0000-0000-0000-000000000000" > /dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        assert_success "Deleting files where one or more ids are invalid return an error"
    else
        assert_fail "Deleting files where one or more ids are invalid didn't return an error"
    fi
    # Checks if the function works as properly
    #this function works properly
    if [ ! -e "$FILES_DIR/a.txt" ] && [ ! -e "$FILES_DIR/b.txt" ] && [ ! -e "$FILES_DIR/c.txt" ]; then
        echo "Files deleted successfully"
    else
        echo "Files not deleted"
    fi
    teardown
}

test_empty_all_wrong_ids() {
    log_section "Test: Deleting files where all ids are invalid"
    setup
    $SCRIPT empty --force "00000000-0000-0000-0000-000000000000" "noen" "vfeoin" > /dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        assert_success "Deleting files where all ids are invalid return an error"
    else
        assert_fail "Deleting files where all ids are invalid didn't return an error"
    fi
    teardown
}

test_display_help_flag() {
    log_section "Test: display help(--help)"
    setup
    $SCRIPT --help > /dev/null 2>&1
    assert_success "Display help(--help)"
    teardown 
}

test_display_help_small_flag() {
    log_section "Test: display help(-h)"
    setup
    $SCRIPT -h > /dev/null 2>&1
    assert_success "Display help(-h)"
    teardown
}

test_status() {
    log_section "Test: status recycle"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    echo "c" > "$TEST_DIR/c.txt"
    echo "d" > "$TEST_DIR/d.txt"
    echo "e" > "$TEST_DIR/e.txt"
    echo "f" > "$TEST_DIR/f.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" "$TEST_DIR/c.txt" "$TEST_DIR/d.txt" "$TEST_DIR/e.txt" "$TEST_DIR/f.txt" > /dev/null 2>&1
    $SCRIPT status > /dev/null 2>&1
    assert_success "Status recycle"
    teardown
}

test_status_empty_recycle_test() {
    log_section "Test: status empty recycle"
    setup
    $SCRIPT status > /dev/null 2>&1
    assert_success "Status empty recycle"
    teardown
}



test_auto_clean_up() {
    log_section "Test: Auto Cleanup deleting old files"
    setup
    # Create a old and a new file
    echo "old file" > "$TEST_DIR/old.txt"
    echo "new file" > "$TEST_DIR/new.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/old.txt" "$TEST_DIR/new.txt" > /dev/null 2>&1

    # Adapt the metadata file to simulate an old file(<30 dias)
    METADATA_FILE="$HOME/.recycle_bin/metadata.csv"
    OLD_DATE=$(date -d "3 days ago" +"%Y-%m-%d %H:%M:%S")
    NEW_DATE=$(date +"%Y-%m-%d %H:%M:%S")

    sed -i "s|\(old.txt,[^,]*,[^,]*,\).*|\1$OLD_DATE|" "$METADATA_FILE"
    sed -i "s|\(new.txt,[^,]*,[^,]*,\).*|\1$NEW_DATE|" "$METADATA_FILE"

    $SCRIPT clean test > /dev/null 2>&1
    assert_success "Auto cleanup deleted old files"

    # Checks if the function works as properly
    if [ ! -e "$FILES_DIR/old.txt" ] && [ -e "$FILES_DIR/new.txt" ]; then
        echo "Old file auto-deleted, new file preserved"
    else
        echo "FAIL: Auto cleanup did not behave as expected"
    fi

    teardown
}

test_auto_clean_up_nothing() {
    log_section "Test: Auto Clean Up a already optimize recycle bin"
    setup
    echo "new file1" > "$TEST_DIR/a.txt"
    echo "new file2" > "$TEST_DIR/b.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" > /dev/null 2>&1
    $SCRIPT clean test > /dev/null 2>&1
    assert_success "Auto clean up was already optimize"
    teardown
}

test_search_pattern() {
    log_section "Test: Search using a pattern"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "ab" > "$TEST_DIR/ab.txt"
    echo "ac" > "$TEST_DIR/ac.txt"
    echo "d" > "$TEST_DIR/d.txt"
    echo "e" > "$TEST_DIR/e.txt"
    echo "f" > "$TEST_DIR/f.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/ab.txt" "$TEST_DIR/ac.txt" "$TEST_DIR/d.txt" "$TEST_DIR/e.txt" "$TEST_DIR/f.txt" > /dev/null 2>&1
    $SCRIPT search ^a.* > /dev/null 2>&1
    assert_success "Search using a pattern"
    teardown 
}

test_search_folder() {
    log_section "Test: Search for a directory"
    setup
    mkdir "$TEST_DIR/dir1"
    mkdir "$TEST_DIR/dir2"
    mkdir "$TEST_DIR/dir3"
    mkdir "$TEST_DIR/dir4"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/dir1" "$TEST_DIR/dir2" "$TEST_DIR/dir3" "$TEST_DIR/dir4" > /dev/null 2>&1
    $SCRIPT search "dir3" > /dev/null 2>&1
    assert_success "Search for a directory"
    teardown 
}

test_search_nothing() {
    log_section "Test: Search for nothing"
    setup
    $SCRIPT > /dev/null 2>&1
    $SCRIPT search > /dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        assert_success "Search for nothing return an error as expected"
    else
        assert_fail "Unexpectedly, search for nothing didn't return an error"
    fi
    teardown
}

test_search_didnt_find() {
    log_section "Test: Search for a paramter that it doesn't exist"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "ab" > "$TEST_DIR/b.txt"
    echo "ac" > "$TEST_DIR/c.txt"
    echo "d" > "$TEST_DIR/d.txt"
    echo "e" > "$TEST_DIR/e.txt"
    echo "f" > "$TEST_DIR/f.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" "$TEST_DIR/c.txt" "$TEST_DIR/d.txt" "$TEST_DIR/e.txt" "$TEST_DIR/f.txt" > /dev/null 2>&1
    $SCRIPT search "g" > /dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        assert_success "Search return error because it didn't find anything as expected"
    else
        assert_fail "Search din't return an error, unexpectedly"
    fi
    teardown
}

test_check() {
    log_section "Test: checking if recycle is full"
    setup
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" > /dev/null 2>&1
    echo "y" | $SCRIPT check test > /dev/null 2>&1
    assert_success "Checking if recycle is full"
    teardown
}

test_check_with_full_recycle_not_optimzed() {
    log_section "Test: Checking if recycle bin is full and optimize automatically"
    setup
    echo "big new file" > "$TEST_DIR/bigNew.txt"
    truncate -s 512k "$TEST_DIR/bigNew.txt"
    echo "big old file" > "$TEST_DIR/bigOld.txt"
    truncate -s 768k "$TEST_DIR/bigOld.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/bigOld.txt" "$TEST_DIR/bigNew.txt" > /dev/null 2>&1
    
    # Adapt the metadata file to simulate an old file(<30 dias)
    METADATA_FILE="$HOME/.recycle_bin/metadata.csv"
    OLD_DATE=$(date -d "3 days ago" +"%Y-%m-%d %H:%M:%S")
    NEW_DATE=$(date +"%Y-%m-%d %H:%M:%S")

    sed -i "s|\(bigOld.txt,[^,]*,[^,]*,\).*|\1$OLD_DATE|" "$METADATA_FILE"
    sed -i "s|\(bigNew.txt,[^,]*,[^,]*,\).*|\1$NEW_DATE|" "$METADATA_FILE"

    echo "y" | $SCRIPT check test > /dev/null 2>&1
    assert_success "Checking if recycle bin is full and optimize automatically"
    # Checks if the function works as properly
    #if [ ! -e "$FILES_DIR/bigOld.txt" ]; then
    #    echo "Old file auto-deleted, new file preserved"
    #else
    #    echo "FAIL: Auto cleanup did not behave as expected"
    #fi
    teardown
}
#===============================================
test_check_with_full_recycle_optimized() {
    log_section "Test: Checking if recycle bin is full but it can't be optimized"
    setup
    echo "big a file" > "$TEST_DIR/bigNew.txt"
    truncate -s 512K "$TEST_DIR/bigNew.txt"
    echo "big b file" > "$TEST_DIR/bigOld.txt"
    truncate -s 768k "$TEST_DIR/bigOld.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/bigOld.txt" "$TEST_DIR/bigNew.txt" > /dev/null 2>&1
    echo "y" | $SCRIPT check test > /dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        assert_success "Return an error as expected because even after clean, recycle is still full"
    else
        assert_fail "Unexpectedly, the function didn't return an error"
    fi
    teardown
}
#===============================================
test_filename_with_spaces() {
    log_section "Test: Handle Filename with Spaces"
    setup
    echo "data" > "$TEST_DIR/file with spaces.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/file with spaces.txt" > /dev/null 2>&1
    assert_success "Delete file with spaces"
    teardown
}

test_filename_special_chars() {
    log_section "Test: Handle Filename with Special Characters"
    setup
    echo "special" > "$TEST_DIR/file!@#$.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/file!@#$.txt" > /dev/null 2>&1
    assert_success "Delete file with special characters"
    teardown
}

test_hidden_file() {
    log_section "Test: Handle Hidden File"
    setup
    echo "hidden" > "$TEST_DIR/.hidden.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/.hidden.txt" > /dev/null 2>&1
    assert_success "Delete hidden file"
    teardown
}

test_symlink_handling() {
    log_section "Test: Handle Symbolic Links"
    setup
    echo "target" > "$TEST_DIR/original.txt"
    ln -s "$TEST_DIR/original.txt" "$TEST_DIR/link.txt"
    $SCRIPT > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/link.txt" > /dev/null 2>&1
    assert_success "Delete symbolic link"
    teardown
}

test_large_metadata_search() {
    log_section "Test: Search in Large Metadata File"
    setup
    for i in $(seq 1 100); do
        echo "file $i" > "$TEST_DIR/file_$i.txt"
        $SCRIPT > /dev/null 2>&1
        $SCRIPT delete "$TEST_DIR/file_$i.txt" > /dev/null 2>&1
    done
    $SCRIPT list | grep -q "file_99"
    assert_success "Find entry in large metadata file"
    teardown
}

# ============================================================
# === MAIN EXECUTION LOGIC
# ============================================================
echo "========================================="
echo "       Recycle Bin Test Suite             "
echo "========================================="

if [[ "$1" == "--detailed" ]]; then
    echo -e "${YELLOW}Running detailed mode: All test cases enabled${NC}"
    test_initialization
    test_delete_single_file
    test_list_empty 
    test_restore_single_file #this function works properly
    test_delete_multiple_files
    test_delete_empty_directory
    test_delete_directory_with_contents
    test_restore_nonexistent_path
    test_delete_nonexistent_file
    test_restore_invalid_id
    test_filename_with_spaces
    test_filename_special_chars
    test_hidden_file
    test_symlink_handling
    test_large_metadata_search
    test_empty_single_file #this function works properly
    test_empty_empty 
    test_empty_confirmation 
    test_empty_recycle_without_arguments #this function works properly
    test_empty_recycle_with_all #this function works properly
    test_empty_multiple_files #this function works properly
    test_empty_empty_directory #this function works properly
    test_empty_directory_with_contents #this function works properly
    test_empty_with_some_wrong_ids #this function works properly
    test_empty_all_wrong_ids 
    test_search_file
    test_search_pattern
    test_search_folder
    test_search_nothing 
    test_search_didnt_find 
    test_display_help
    test_display_help_flag
    test_display_help_small_flag
    test_status
    test_status_empty_recycle_test
    test_auto_clean_up #<--
    test_auto_clean_up_nothing #<--
    test_check
    test_check_with_full_recycle_not_optimzed #<--
    test_check_with_full_recycle_optimized 
else
    echo -e "${YELLOW}Running basic mode: Core tests only${NC}"
    test_initialization
    test_delete_single_file
    test_list_empty
    test_restore_single_file #this function works properly
    test_empty_single_file #this function works properly
    test_search_file
    test_display_help
fi

teardown

echo "========================================="
echo "Results: $PASS passed, $FAIL failed"
echo "========================================="

[ $FAIL -eq 0 ] && exit 0 || exit 1
