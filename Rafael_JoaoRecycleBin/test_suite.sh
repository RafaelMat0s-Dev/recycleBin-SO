#!/bin/bash
# ============================================================
# Recycle Bin Test Suite
# Author: Rafael da Costa Matos
# ============================================================

SCRIPT="./recycle_bin.sh"
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
    $SCRIPT delete "$TEST_DIR/restore_test.txt" > /dev/null 2>&1
    local ID
    ID=$($SCRIPT list | grep "restore_test" | awk '{print $1}')
    $SCRIPT restore "$ID" > /dev/null 2>&1
    assert_success "Restore file from recycle bin"
    [ -f "$TEST_DIR/restore_test.txt" ] && echo "✓ File successfully restored"
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
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" > /dev/null 2>&1
    assert_success "Delete multiple files"
    teardown
}

test_delete_empty_directory() {
    log_section "Test: Delete Empty Directory"
    setup
    mkdir "$TEST_DIR/empty_dir"
    $SCRIPT delete "$TEST_DIR/empty_dir" > /dev/null 2>&1
    assert_success "Delete empty directory"
    teardown
}

test_delete_directory_with_contents() {
    log_section "Test: Delete Directory With Contents"
    setup
    mkdir -p "$TEST_DIR/nested/dir"
    echo "inside" > "$TEST_DIR/nested/dir/file.txt"
    $SCRIPT delete "$TEST_DIR/nested" > /dev/null 2>&1
    assert_success "Delete directory recursively"
    teardown
}

test_restore_nonexistent_path() {
    log_section "Test: Restore to Nonexistent Path"
    setup
    mkdir -p "$TEST_DIR"
    echo "test" > "$TEST_DIR/file.txt"
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
    $SCRIPT delete "$TEST_DIR/missing.txt" > /dev/null 2>&1
    assert_fail "Delete non-existent file should fail"
    teardown
}

test_restore_invalid_id() {
    log_section "Test: Restore Invalid ID"
    setup
    $SCRIPT restore "00000000-0000-0000-0000-000000000000" > /dev/null 2>&1
    assert_fail "Restore with invalid ID should fail"
    teardown
}

test_filename_with_spaces() {
    log_section "Test: Handle Filename with Spaces"
    setup
    echo "data" > "$TEST_DIR/file with spaces.txt"
    $SCRIPT delete "$TEST_DIR/file with spaces.txt" > /dev/null 2>&1
    assert_success "Delete file with spaces"
    teardown
}

test_filename_special_chars() {
    log_section "Test: Handle Filename with Special Characters"
    setup
    echo "special" > "$TEST_DIR/file!@#$.txt"
    $SCRIPT delete "$TEST_DIR/file!@#$.txt" > /dev/null 2>&1
    assert_success "Delete file with special characters"
    teardown
}

test_hidden_file() {
    log_section "Test: Handle Hidden File"
    setup
    echo "hidden" > "$TEST_DIR/.hidden.txt"
    $SCRIPT delete "$TEST_DIR/.hidden.txt" > /dev/null 2>&1
    assert_success "Delete hidden file"
    teardown
}

test_symlink_handling() {
    log_section "Test: Handle Symbolic Links"
    setup
    echo "target" > "$TEST_DIR/original.txt"
    ln -s "$TEST_DIR/original.txt" "$TEST_DIR/link.txt"
    $SCRIPT delete "$TEST_DIR/link.txt" > /dev/null 2>&1
    assert_success "Delete symbolic link"
    teardown
}

test_large_metadata_search() {
    log_section "Test: Search in Large Metadata File"
    setup
    for i in $(seq 1 100); do
        echo "file $i" > "$TEST_DIR/file_$i.txt"
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
    test_restore_single_file
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
else
    echo -e "${YELLOW}Running basic mode: Core tests only${NC}"
    test_initialization
    test_delete_single_file
    test_list_empty
    test_restore_single_file
fi

teardown

echo "========================================="
echo "Results: $PASS passed, $FAIL failed"
echo "========================================="

[ $FAIL -eq 0 ] && exit 0 || exit 1
