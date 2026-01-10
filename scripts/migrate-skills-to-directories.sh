#!/bin/bash
# Migrate skill files from flat .md files to directory/SKILL.md format
# Usage: ./scripts/migrate-skills-to-directories.sh [--dry-run]

set -e

SKILLS_DIR=".claude/skills"
DRY_RUN=false

if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "DRY RUN MODE - no changes will be made"
fi

echo "Migrating skills from flat files to directory format..."
echo ""

# Find all .md files in the skills directory
find "$SKILLS_DIR" -name "*.md" -type f | while read -r file; do
    # Get the directory and filename
    dir=$(dirname "$file")
    filename=$(basename "$file" .md)

    # Create new directory path
    new_dir="$dir/$filename"
    new_file="$new_dir/SKILL.md"

    # Skip if already in correct format (SKILL.md inside a directory)
    if [[ "$filename" == "SKILL" ]]; then
        echo "SKIP: $file (already in correct format)"
        continue
    fi

    echo "MIGRATE: $file -> $new_file"

    if [[ "$DRY_RUN" == "false" ]]; then
        # Create directory
        mkdir -p "$new_dir"

        # Move file
        mv "$file" "$new_file"
    fi
done

echo ""
echo "Migration complete!"
if [[ "$DRY_RUN" == "true" ]]; then
    echo "Re-run without --dry-run to apply changes"
fi
