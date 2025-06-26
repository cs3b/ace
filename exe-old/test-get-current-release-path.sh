#!/usr/bin/env bash
# test-get-current-release-path.sh: Test script for get-current-release-path tool
# Tests both scenarios: current release exists and no current release (backlog)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_test_header() {
    echo -e "${YELLOW}=== $1 ===${NC}"
}

print_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((TESTS_FAILED++))
}

run_test() {
    ((TESTS_RUN++))
    if "$@"; then
        return 0
    else
        return 1
    fi
}

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOL_PATH="$SCRIPT_DIR/get-current-release-path.sh"

# Create temporary test environment
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

print_test_header "Testing get-current-release-path tool"

# Test 1: Current release exists scenario
test_current_release_exists() {
    print_test_header "Test 1: Current release directory exists"
    
    # Setup: Create mock directory structure with current release
    mkdir -p docs-project/current
    mkdir -p docs-dev/backlog/tasks
    mkdir -p "docs-project/current/v.1.2.3-test-release"
    
    # Run the tool
    output=$("$TOOL_PATH" 2>&1)
    exit_code=$?
    
    # Parse output
    path_line=$(echo "$output" | sed -n '1p')
    version_line=$(echo "$output" | sed -n '2p')
    
    # Assertions
    if [[ $exit_code -eq 0 ]]; then
        print_pass "Tool executed successfully (exit code 0)"
    else
        print_fail "Tool failed with exit code $exit_code"
        echo "Output: $output"
        return 1
    fi
    
    if [[ "$path_line" == "docs-project/current/v.1.2.3-test-release" ]]; then
        print_pass "Correct path returned: $path_line"
    else
        print_fail "Expected 'docs-project/current/v.1.2.3-test-release', got '$path_line'"
        return 1
    fi
    
    if [[ "$version_line" == "v.1.2.3" ]]; then
        print_pass "Correct version returned: $version_line"
    else
        print_fail "Expected 'v.1.2.3', got '$version_line'"
        return 1
    fi
}

# Test 2: No current release scenario  
test_no_current_release() {
    print_test_header "Test 2: No current release directory exists"
    
    # Setup: Create mock directory structure without current release
    rm -rf docs-project docs-dev
    mkdir -p docs-project/current
    mkdir -p docs-dev/backlog/tasks
    # No release directory created this time
    
    # Run the tool
    output=$("$TOOL_PATH" 2>&1)
    exit_code=$?
    
    # Parse output
    path_line=$(echo "$output" | sed -n '1p')
    version_line=$(echo "$output" | sed -n '2p')
    
    # Assertions
    if [[ $exit_code -eq 0 ]]; then
        print_pass "Tool executed successfully (exit code 0)"
    else
        print_fail "Tool failed with exit code $exit_code"
        echo "Output: $output"
        return 1
    fi
    
    if [[ "$path_line" == "docs-dev/backlog/tasks" ]]; then
        print_pass "Correct backlog path returned: $path_line"
    else
        print_fail "Expected 'docs-dev/backlog/tasks', got '$path_line'"
        return 1
    fi
    
    if [[ -z "$version_line" ]]; then
        print_pass "Empty version returned correctly"
    else
        print_fail "Expected empty version, got '$version_line'"
        return 1
    fi
}

# Test 3: Multiple release directories (edge case)
test_multiple_release_directories() {
    print_test_header "Test 3: Multiple release directories exist"
    
    # Setup: Create multiple release directories
    rm -rf docs-project docs-dev
    mkdir -p docs-project/current
    mkdir -p docs-dev/backlog/tasks
    mkdir -p "docs-project/current/v.1.0.0-first"
    mkdir -p "docs-project/current/v.2.0.0-second"
    
    # Run the tool
    output=$("$TOOL_PATH" 2>&1)
    exit_code=$?
    
    # Parse output
    path_line=$(echo "$output" | sed -n '1p')
    version_line=$(echo "$output" | sed -n '2p')
    
    # Assertions
    if [[ $exit_code -eq 0 ]]; then
        print_pass "Tool executed successfully (exit code 0)"
    else
        print_fail "Tool failed with exit code $exit_code"
        echo "Output: $output"
        return 1
    fi
    
    # Should pick one of the directories (implementation picks first lexicographically)
    if [[ "$path_line" =~ ^docs-project/current/v\.[0-9]+\.[0-9]+\.[0-9]+- ]]; then
        print_pass "Valid release path returned: $path_line"
    else
        print_fail "Expected release path pattern, got '$path_line'"
        return 1
    fi
    
    if [[ "$version_line" =~ ^v\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_pass "Valid version pattern returned: $version_line"
    else
        print_fail "Expected version pattern, got '$version_line'"
        return 1
    fi
}

# Test 4: Help option
test_help_option() {
    print_test_header "Test 4: Help option works"
    
    # Test --help
    output=$("$TOOL_PATH" --help 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_pass "Help option executed successfully"
    else
        print_fail "Help option failed with exit code $exit_code"
        return 1
    fi
    
    if [[ "$output" =~ "Usage:" ]]; then
        print_pass "Help output contains usage information"
    else
        print_fail "Help output missing usage information"
        return 1
    fi
}

# Test 5: Invalid option
test_invalid_option() {
    print_test_header "Test 5: Invalid option handling"
    
    # Test invalid option
    output=$("$TOOL_PATH" --invalid 2>&1)
    exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        print_pass "Invalid option correctly failed with non-zero exit code"
    else
        print_fail "Invalid option should have failed but returned success"
        return 1
    fi
    
    if [[ "$output" =~ "Error:" ]]; then
        print_pass "Error message displayed for invalid option"
    else
        print_fail "No error message for invalid option"
        return 1
    fi
}

# Run tests
run_test test_current_release_exists
run_test test_no_current_release
run_test test_multiple_release_directories
run_test test_help_option
run_test test_invalid_option

# Print test results
print_test_header "Test Results"
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi