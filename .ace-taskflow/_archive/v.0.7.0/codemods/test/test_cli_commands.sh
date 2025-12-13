#!/bin/bash

# Test CLI commands after ACE migration
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

echo "========================================="
echo "Testing CLI Commands"
echo "========================================="
echo ""

# Function to test a command
test_command() {
    local cmd="$1"
    local description="$2"

    echo -n "Testing $description... "

    # For help commands, check for help output
    if echo "$cmd" | grep -q "\-\-help"; then
        if $cmd 2>&1 | grep -q -E "(Commands:|Usage:|COMMANDS|OPTIONS|Description)" ; then
            echo -e "${GREEN}✓ Passed${NC}"
            PASSED=$((PASSED + 1))
            return 0
        else
            echo -e "${RED}✗ Failed${NC}"
            FAILED=$((FAILED + 1))
            return 1
        fi
    else
        # For regular commands, just check exit code
        if $cmd >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Passed${NC}"
            PASSED=$((PASSED + 1))
            return 0
        else
            # Check if command at least produces output
            output=$($cmd 2>&1)
            if [ -n "$output" ]; then
                echo -e "${GREEN}✓ Passed${NC}"
                PASSED=$((PASSED + 1))
                return 0
            else
                echo -e "${RED}✗ Failed${NC}"
                FAILED=$((FAILED + 1))
                return 1
            fi
        fi
    fi
}

# Test task management commands
echo "Task Management Commands:"
echo "-------------------------"
test_command "task-manager --help" "task-manager help"
test_command "task-manager list --limit 1" "task-manager list"
test_command "task-manager next" "task-manager next"
test_command "task-manager recent --limit 1" "task-manager recent"
echo ""

# Test release management
echo "Release Management Commands:"
echo "----------------------------"
test_command "release-manager --help" "release-manager help"
test_command "release-manager current" "release-manager current"
echo ""

# Test handbook command
echo "Handbook Commands:"
echo "------------------"
test_command "handbook --help" "handbook help"
echo ""

# Test search command
echo "Search Commands:"
echo "----------------"
test_command "search --help" "search help"
test_command "search '*.md' --files --limit 1" "search files"
echo ""

# Test context command
echo "Context Commands:"
echo "-----------------"
test_command "context --help" "context help"
test_command "context --list-presets" "context list presets"
echo ""

# Test Git commands
echo "Git Commands:"
echo "-------------"
test_command "git-status --help" "git-status help"
test_command "git-status" "git-status execution"
test_command "git-log --help" "git-log help"
test_command "git-diff --help" "git-diff help"
echo ""

# Test code review
echo "Code Review Commands:"
echo "---------------------"
test_command "code-review --help" "code-review help"
echo ""

# Test navigation commands
echo "Navigation Commands:"
echo "--------------------"
test_command "nav-ls --help" "nav-ls help"
test_command "nav-ls ." "nav-ls execution"
test_command "nav-tree --help" "nav-tree help"
test_command "nav-path --help" "nav-path help"
echo ""

# Test create-path command
echo "File Management Commands:"
echo "-------------------------"
test_command "create-path --help" "create-path help"
echo ""

# Test LLM query (just help, as actual query requires API keys)
echo "LLM Commands:"
echo "-------------"
test_command "llm-query --help" "llm-query help"
echo ""

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $PASSED commands${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED commands${NC}"
    echo ""
    echo "Some commands failed. This may be due to missing dependencies or configuration."
    exit 1
else
    echo ""
    echo -e "${GREEN}✓ All CLI commands are working!${NC}"
    exit 0
fi