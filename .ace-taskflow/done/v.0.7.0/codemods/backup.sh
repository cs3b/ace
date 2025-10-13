#!/bin/bash

# Backup script for ACE migration
# Creates a timestamped backup of critical directories before migration

set -e  # Exit on error

# Set paths - this script should be run from project root
PROJECT_ROOT="${PROJECT_ROOT_PATH:-$(pwd)}"
ACE_PATH="${ACE_PATH:-${PROJECT_ROOT}/.ace}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create timestamp for backup directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${PROJECT_ROOT}/backups/migration-${TIMESTAMP}"

echo -e "${YELLOW}Creating backup in ${BACKUP_DIR}...${NC}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Backup critical directories
echo "Backing up .ace directory..."
if [ -d "${ACE_PATH}" ]; then
    cp -r "${ACE_PATH}" "${BACKUP_DIR}/"
fi

echo "Backing up .coding-agent directory..."
if [ -d "${PROJECT_ROOT}/.coding-agent" ]; then
    cp -r "${PROJECT_ROOT}/.coding-agent" "${BACKUP_DIR}/"
fi

echo "Backing up docs directory..."
if [ -d "${PROJECT_ROOT}/docs" ]; then
    cp -r "${PROJECT_ROOT}/docs" "${BACKUP_DIR}/"
fi

# Create backup metadata
cat > "${BACKUP_DIR}/backup_info.txt" << EOF
Backup created: ${TIMESTAMP}
Purpose: ACE Migration (dev-* to .ace/*, CodingAgentTools to AceTools)
Contents:
- .ace/ - Main submodules directory
- .coding-agent/ - Configuration files
- docs/ - Documentation
- codemods/ - Migration scripts
EOF

# Calculate backup size
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)

echo -e "${GREEN}✓ Backup completed successfully!${NC}"
echo "  Location: ${BACKUP_DIR}"
echo "  Size: ${BACKUP_SIZE}"
echo ""
echo "To restore from this backup:"
echo "  cp -r ${BACKUP_DIR}/.ace ."
echo "  cp -r ${BACKUP_DIR}/.coding-agent ."
echo "  cp -r ${BACKUP_DIR}/docs ."