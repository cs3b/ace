#!/bin/bash

# Master execution script for ACE migration
# Orchestrates all migration phases in the correct sequence

set -e  # Exit on error

# Set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate from .ace/taskflow/current/v.0.6.0-ace-migration/codemods to project root (5 levels up)
PROJECT_ROOT="${PROJECT_ROOT_PATH:-$(cd "${SCRIPT_DIR}/../../../../../" && pwd)}"
ACE_PATH="${ACE_PATH:-${PROJECT_ROOT}/.ace}"
CODEMODS_DIR="${SCRIPT_DIR}"

# Debug output
echo "Script dir: ${SCRIPT_DIR}"
echo "Project root: ${PROJECT_ROOT}"
echo "ACE path: ${ACE_PATH}"
echo "Codemods dir: ${CODEMODS_DIR}"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DRY_RUN=true
SKIP_BACKUP=false
VERBOSE=false
LOG_FILE="${CODEMODS_DIR}/migration.log"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--apply)
      DRY_RUN=false
      shift
      ;;
    --skip-backup)
      SKIP_BACKUP=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -a, --apply       Apply changes (default is dry-run)"
      echo "  --skip-backup     Skip backup creation (not recommended)"
      echo "  -v, --verbose     Show detailed output"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Setup logging
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "========================================="
echo "ACE Migration Script"
echo "Started: $(date)"
echo "========================================="
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}MODE: DRY RUN - No changes will be applied${NC}"
    echo "Use -a or --apply flag to actually perform the migration"
else
    echo -e "${RED}MODE: APPLY - Changes will be applied${NC}"
fi
echo ""

# Phase 1: Create backup (unless skipped)
if [ "$SKIP_BACKUP" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${BLUE}Phase 1: Creating backup...${NC}"
    echo "========================================="
    cd "${PROJECT_ROOT}" && "${CODEMODS_DIR}/backup.sh"
    echo ""
else
    if [ "$SKIP_BACKUP" = true ]; then
        echo -e "${YELLOW}Skipping backup (--skip-backup flag)${NC}"
    else
        echo -e "${YELLOW}Skipping backup in dry-run mode${NC}"
    fi
    echo ""
fi

# Phase 2: Update paths (dev-* to .ace/*)
echo -e "${BLUE}Phase 2: Updating paths...${NC}"
echo "========================================="
CMD="ruby ${CODEMODS_DIR}/update_paths.rb"
if [ "$DRY_RUN" = false ]; then
    CMD="$CMD --apply"
fi
if [ "$VERBOSE" = true ]; then
    CMD="$CMD --verbose"
fi
CMD="$CMD --root ${PROJECT_ROOT} --mappings ${CODEMODS_DIR}/path_mappings.yml"
echo "Running: $CMD"
cd "${PROJECT_ROOT}" && eval $CMD
echo ""

# Phase 3: Update Ruby modules (CodingAgentTools to AceTools)
echo -e "${BLUE}Phase 3: Updating Ruby modules...${NC}"
echo "========================================="
CMD="ruby ${CODEMODS_DIR}/rename_ruby_module.rb"
if [ "$DRY_RUN" = false ]; then
    CMD="$CMD --apply"
fi
if [ "$VERBOSE" = true ]; then
    CMD="$CMD --verbose"
fi
CMD="$CMD --root ${ACE_PATH}/tools --mappings ${CODEMODS_DIR}/module_mappings.yml"
echo "Running: $CMD"
cd "${PROJECT_ROOT}" && eval $CMD
echo ""

# Phase 4: Rename files and directories
echo -e "${BLUE}Phase 4: Renaming files and directories...${NC}"
echo "========================================="
CMD="${CODEMODS_DIR}/rename_files.sh"
if [ "$DRY_RUN" = false ]; then
    CMD="$CMD --apply"
fi
if [ "$VERBOSE" = true ]; then
    CMD="$CMD --verbose"
fi
CMD="$CMD --root ${ACE_PATH}/tools"
echo "Running: $CMD"
cd "${PROJECT_ROOT}" && eval $CMD
echo ""

# Phase 5: Update version file (special handling)
if [ "$DRY_RUN" = false ]; then
    echo -e "${BLUE}Phase 5: Updating version file...${NC}"
    echo "========================================="
    VERSION_FILE="${ACE_PATH}/tools/lib/ace_tools/version.rb"
    if [ -f "${ACE_PATH}/tools/lib/coding_agent_tools/version.rb" ]; then
        echo "Moving and updating version.rb..."
        mkdir -p "$(dirname "$VERSION_FILE")"
        sed 's/CodingAgentTools/AceTools/g' "${ACE_PATH}/tools/lib/coding_agent_tools/version.rb" > "$VERSION_FILE"
        echo "Version file updated"
    elif [ -f "$VERSION_FILE" ]; then
        echo "Updating existing version.rb..."
        sed -i '' 's/CodingAgentTools/AceTools/g' "$VERSION_FILE"
        echo "Version file updated"
    fi
    echo ""
fi

# Phase 6: Verification
echo -e "${BLUE}Phase 6: Running verification...${NC}"
echo "========================================="
cd "${PROJECT_ROOT}" && "${CODEMODS_DIR}/verify.sh" || true  # Don't fail the whole script if verification has issues
echo ""

# Summary
echo "========================================="
echo "Migration Complete"
echo "Finished: $(date)"
echo "========================================="

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}This was a DRY RUN. Review the output above.${NC}"
    echo "If everything looks good, run with -a flag to apply changes:"
    echo "  $0 --apply"
else
    echo ""
    echo -e "${GREEN}Migration has been applied!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review the verification output above"
    echo "2. Run tests: cd ${ACE_PATH}/tools && bundle exec rspec"
    echo "3. Commit the changes: git add -A && git commit -m 'Complete ACE migration'"
fi

echo ""
echo "Log file: $LOG_FILE"