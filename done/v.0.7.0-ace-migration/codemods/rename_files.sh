#!/bin/bash

# File and directory renaming script for CodingAgentTools -> AceTools migration
# This script renames all files and directories using git mv to preserve history

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DRY_RUN=true
VERBOSE=false
ROOT_DIR="."

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--apply)
      DRY_RUN=false
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -r|--root)
      ROOT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -a, --apply     Apply changes (default is dry-run)"
      echo "  -v, --verbose   Show detailed output"
      echo "  -r, --root DIR  Root directory (default: current directory)"
      echo "  -h, --help      Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Navigate to the root directory
cd "$ROOT_DIR"

echo "Starting file renaming process..."
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}Mode: DRY RUN${NC}"
else
  echo -e "${GREEN}Mode: APPLY${NC}"
fi
echo "Root directory: $(pwd)"
echo "----------------------------------------"

# Counter for tracking operations
RENAMED_COUNT=0
ERROR_COUNT=0
ERRORS=()

# Function to rename a file or directory
rename_item() {
  local old_path="$1"
  local new_path="$2"

  if [ -e "$old_path" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo -e "${YELLOW}[DRY RUN]${NC} Would rename: $old_path -> $new_path"
    else
      # Create parent directory if it doesn't exist
      new_dir=$(dirname "$new_path")
      if [ ! -d "$new_dir" ]; then
        mkdir -p "$new_dir"
        [ "$VERBOSE" = true ] && echo "Created directory: $new_dir"
      fi

      # Use git mv if in a git repository, otherwise use regular mv
      if git rev-parse --git-dir > /dev/null 2>&1; then
        if git mv "$old_path" "$new_path" 2>/dev/null; then
          echo -e "${GREEN}[RENAMED]${NC} $old_path -> $new_path"
          ((RENAMED_COUNT++))
        else
          echo -e "${RED}[ERROR]${NC} Failed to rename: $old_path"
          ERRORS+=("Failed to rename: $old_path -> $new_path")
          ((ERROR_COUNT++))
        fi
      else
        if mv "$old_path" "$new_path"; then
          echo -e "${GREEN}[RENAMED]${NC} $old_path -> $new_path"
          ((RENAMED_COUNT++))
        else
          echo -e "${RED}[ERROR]${NC} Failed to rename: $old_path"
          ERRORS+=("Failed to rename: $old_path -> $new_path")
          ((ERROR_COUNT++))
        fi
      fi
    fi
  else
    [ "$VERBOSE" = true ] && echo "Skipping (not found): $old_path"
  fi
}

# Check if we're in the tools directory
TOOLS_DIR=".ace/tools"
if [ ! -d "$TOOLS_DIR" ]; then
  TOOLS_DIR="."
fi

echo "Processing directory: $TOOLS_DIR"
echo ""

# Step 1: Rename main library directory (must be done first)
echo "Step 1: Renaming main library directory..."
rename_item "$TOOLS_DIR/lib/coding_agent_tools" "$TOOLS_DIR/lib/ace_tools"
echo ""

# Step 2: Rename main library file
echo "Step 2: Renaming main library file..."
rename_item "$TOOLS_DIR/lib/coding_agent_tools.rb" "$TOOLS_DIR/lib/ace_tools.rb"
echo ""

# Step 3: Rename signature files
echo "Step 3: Renaming signature files..."
rename_item "$TOOLS_DIR/sig/coding_agent_tools.rbs" "$TOOLS_DIR/sig/ace_tools.rbs"
echo ""

# Step 4: Rename spec directory
echo "Step 4: Renaming spec directory..."
rename_item "$TOOLS_DIR/spec/coding_agent_tools" "$TOOLS_DIR/spec/ace_tools"
echo ""

# Step 5: Rename spec file
echo "Step 5: Renaming spec file..."
rename_item "$TOOLS_DIR/spec/coding_agent_tools_spec.rb" "$TOOLS_DIR/spec/ace_tools_spec.rb"
echo ""

# Step 6: Rename executable
echo "Step 6: Renaming executable..."
rename_item "$TOOLS_DIR/exe/coding-agent-tools" "$TOOLS_DIR/exe/ace-tools"
echo ""

# Step 7: Find and rename any other files with coding_agent_tools in the name
echo "Step 7: Looking for other files to rename..."
if [ "$VERBOSE" = true ]; then
  echo "Searching for files containing 'coding_agent_tools' or 'coding-agent-tools' in the name..."
fi

# Find all files with coding_agent_tools in the name (excluding already renamed ones)
while IFS= read -r -d '' file; do
  # Skip if already processed
  if [[ "$file" == *"/lib/coding_agent_tools"* ]] || \
     [[ "$file" == *"/lib/coding_agent_tools.rb" ]] || \
     [[ "$file" == *"/sig/coding_agent_tools.rbs" ]] || \
     [[ "$file" == *"/spec/coding_agent_tools"* ]] || \
     [[ "$file" == *"/spec/coding_agent_tools_spec.rb" ]] || \
     [[ "$file" == *"/exe/coding-agent-tools" ]]; then
    continue
  fi

  # Generate new name
  new_file=$(echo "$file" | sed 's/coding_agent_tools/ace_tools/g' | sed 's/coding-agent-tools/ace-tools/g')

  if [ "$file" != "$new_file" ]; then
    rename_item "$file" "$new_file"
  fi
done < <(find "$TOOLS_DIR" -type f \( -name "*coding_agent_tools*" -o -name "*coding-agent-tools*" \) -print0 2>/dev/null)

echo ""
echo "========================================"
echo "FILE RENAMING SUMMARY"
echo "========================================"
echo "Files renamed: $RENAMED_COUNT"
echo "Errors: $ERROR_COUNT"

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "Error details:"
  for error in "${ERRORS[@]}"; do
    echo "  - $error"
  done
fi

if [ "$DRY_RUN" = true ]; then
  echo ""
  echo -e "${YELLOW}[DRY RUN MODE]${NC} No files were actually renamed."
  echo "Run with --apply to make actual changes."
else
  echo ""
  echo -e "${GREEN}File renaming complete!${NC}"

  # Reminder about running the module rename codemod
  echo ""
  echo "Next steps:"
  echo "1. Run the module rename codemod to update references in files:"
  echo "   ruby rename_ruby_module.rb --apply"
  echo "2. Run tests to verify everything works:"
  echo "   cd $TOOLS_DIR && bundle exec rspec"
fi

exit 0