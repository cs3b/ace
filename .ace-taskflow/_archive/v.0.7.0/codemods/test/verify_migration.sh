#!/bin/bash

# Enhanced verification script for ACE migration
# Correctly checks for OLD references that should be migrated

set -e  # Exit on error

# Set paths
PROJECT_ROOT="${PROJECT_ROOT_PATH:-$(pwd)}"
ACE_PATH="${ACE_PATH:-${PROJECT_ROOT}/.ace}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0
PASSES=0

echo "========================================="
echo "ACE Migration Verification (Enhanced)"
echo "========================================="
echo ""

# Function to check for old patterns
check_old_pattern() {
    local pattern="$1"
    local description="$2"
    local path="${3:-.}"

    echo -n "Checking for old ${description}... "

    # Use grep to search, but don't fail if nothing found
    count=$(grep -r "${pattern}" "${path}" \
        --exclude-dir=.git \
        --exclude-dir=node_modules \
        --exclude-dir=backups \
        --exclude-dir=coverage \
        --exclude-dir=vendor \
        --exclude-dir=tmp \
        --exclude-dir=codemods \
        --exclude="*.log" \
        --exclude="CHANGELOG.md" \
        2>/dev/null | wc -l | tr -d ' ')

    if [ "$count" -eq 0 ]; then
        echo -e "${GREEN}✓ None found${NC}"
        PASSES=$((PASSES + 1))
        return 0
    else
        echo -e "${RED}✗ Found ${count} occurrences${NC}"
        ERRORS=$((ERRORS + 1))

        # Show first few occurrences for debugging
        echo "  First occurrences:"
        grep -r "${pattern}" "${path}" \
            --exclude-dir=.git \
            --exclude-dir=node_modules \
            --exclude-dir=backups \
            --exclude-dir=coverage \
            --exclude-dir=vendor \
            --exclude-dir=tmp \
            --exclude-dir=codemods \
            --exclude="*.log" \
            --exclude="CHANGELOG.md" \
            2>/dev/null | head -3 | sed 's/^/    /'
        return 1
    fi
}

# Function to check if directory exists
check_directory() {
    local dir="$1"
    local should_exist="$2"

    echo -n "Checking directory ${dir}... "

    if [ -d "${dir}" ]; then
        if [ "${should_exist}" = "true" ]; then
            echo -e "${GREEN}✓ Exists${NC}"
            PASSES=$((PASSES + 1))
            return 0
        else
            echo -e "${RED}✗ Should not exist${NC}"
            ERRORS=$((ERRORS + 1))
            return 1
        fi
    else
        if [ "${should_exist}" = "false" ]; then
            echo -e "${GREEN}✓ Does not exist${NC}"
            PASSES=$((PASSES + 1))
            return 0
        else
            echo -e "${RED}✗ Should exist${NC}"
            ERRORS=$((ERRORS + 1))
            return 1
        fi
    fi
}

# Function to check if file exists
check_file() {
    local file="$1"
    local should_exist="$2"

    echo -n "Checking file ${file}... "

    if [ -f "${file}" ]; then
        if [ "${should_exist}" = "true" ]; then
            echo -e "${GREEN}✓ Exists${NC}"
            PASSES=$((PASSES + 1))
            return 0
        else
            echo -e "${RED}✗ Should not exist${NC}"
            ERRORS=$((ERRORS + 1))
            return 1
        fi
    else
        if [ "${should_exist}" = "false" ]; then
            echo -e "${GREEN}✓ Does not exist${NC}"
            PASSES=$((PASSES + 1))
            return 0
        else
            echo -e "${RED}✗ Should exist${NC}"
            ERRORS=$((ERRORS + 1))
            return 1
        fi
    fi
}

echo "1. Checking for OLD path references (dev-*)..."
echo "-----------------------------------------"
check_old_pattern "dev-tools" "dev-tools references" "${PROJECT_ROOT}"
check_old_pattern "dev-handbook" "dev-handbook references" "${PROJECT_ROOT}"
check_old_pattern "dev-taskflow" "dev-taskflow references" "${PROJECT_ROOT}"
echo ""

echo "2. Checking for OLD module references..."
echo "-----------------------------------------"
check_old_pattern "CodingAgentTools" "CodingAgentTools module references" "${ACE_PATH}/tools"
check_old_pattern "coding_agent_tools\\.gemspec" "coding_agent_tools.gemspec references" "${ACE_PATH}/tools"
check_old_pattern "coding-agent-tools" "coding-agent-tools gem references" "${ACE_PATH}/tools"
echo ""

echo "3. Checking NEW directory structure exists..."
echo "-----------------------------------------"
# New structure should exist
check_directory "${ACE_PATH}/tools/lib/ace_tools" true
check_directory "${ACE_PATH}/tools/spec/ace_tools" true
check_file "${ACE_PATH}/tools/lib/ace_tools.rb" true
check_file "${ACE_PATH}/tools/ace_tools.gemspec" true

# Old structure should not exist
check_directory "${ACE_PATH}/tools/lib/coding_agent_tools" false
check_directory "${ACE_PATH}/tools/spec/coding_agent_tools" false
check_file "${ACE_PATH}/tools/lib/coding_agent_tools.rb" false
check_file "${ACE_PATH}/tools/coding_agent_tools.gemspec" false
echo ""

echo "4. Checking Ruby module loading..."
echo "-----------------------------------------"
echo -n "Testing Ruby module loading... "
if (cd "${ACE_PATH}/tools" && ruby -e "require_relative 'lib/ace_tools'" 2>/dev/null); then
    echo -e "${GREEN}✓ Module loads successfully${NC}"
    PASSES=$((PASSES + 1))
else
    echo -e "${RED}✗ Module loading failed${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

echo "5. Checking configuration files..."
echo "-----------------------------------------"
echo -n "Checking YAML validity... "
yaml_valid=true
for file in ${PROJECT_ROOT}/.coding-agent/*.yml; do
    if [ -f "$file" ]; then
        if ! ruby -ryaml -e "YAML.load_file('$file')" 2>/dev/null; then
            yaml_valid=false
            echo "  Invalid: $file"
            break
        fi
    fi
done
if [ "$yaml_valid" = true ]; then
    echo -e "${GREEN}✓ All YAML files valid${NC}"
    PASSES=$((PASSES + 1))
else
    echo -e "${RED}✗ Some YAML files invalid${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

echo "6. Quick CLI command test..."
echo "-----------------------------------------"
echo -n "Testing task-manager --help... "
if task-manager --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Command works${NC}"
    PASSES=$((PASSES + 1))
else
    echo -e "${RED}✗ Command failed${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

echo "========================================="
echo "Verification Summary"
echo "========================================="
echo -e "${GREEN}✓ Passed: ${PASSES} checks${NC}"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ Warnings: ${WARNINGS}${NC}"
fi
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}✗ Failed: ${ERRORS} checks${NC}"
fi

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Migration verified successful.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Migration complete with ${WARNINGS} warning(s)${NC}"
    exit 0
else
    echo -e "${RED}✗ Migration has ${ERRORS} issue(s) that need attention${NC}"
    echo ""
    echo "Please review the errors above and fix any remaining migration issues."
    exit 1
fi