# Document Sync Operations Guide

Quick reference for document synchronization operations, focusing on common tasks and workflows for maintaining document consistency across the development handbook.

## Quick Commands

### Essential Operations

```bash
# Preview what will change
bin/markdown-sync-embedded-documents --dry-run

# Synchronize with detailed output  
bin/markdown-sync-embedded-documents --verbose

# Synchronize and auto-commit
bin/markdown-sync-embedded-documents --verbose --commit

# Check script help
bin/markdown-sync-embedded-documents --help
```

### Status Checks

```bash
# Check if documents need synchronization
bin/markdown-sync-embedded-documents --dry-run | grep -E "(Template|Guide|Summary)"

# Verify all embedded templates exist
grep -r 'path="dev-handbook/templates/' dev-handbook/workflow-instructions/ | cut -d'"' -f2 | while read path; do
  [ -f "$path" ] || echo "Missing template: $path"
done

# Verify all embedded guides exist
grep -r 'path="dev-handbook/guides/' dev-handbook/workflow-instructions/ | cut -d'"' -f2 | while read path; do
  [ -f "$path" ] || echo "Missing guide: $path"
done

# Count embedded documents
echo "Templates: $(grep -r "<template path=" dev-handbook/workflow-instructions/ | wc -l)"
echo "Guides: $(grep -r "<guide path=" dev-handbook/workflow-instructions/ | wc -l)"
echo "Total: $(grep -r -E "(<template|<guide) path=" dev-handbook/workflow-instructions/ | wc -l)"
```

## Common Workflows

### Daily Development

```bash
# 1. Check for document changes (morning routine)
bin/markdown-sync-embedded-documents --dry-run

# 2. If changes needed, apply them
bin/markdown-sync-embedded-documents --verbose

# 3. Review and commit changes
git diff
git add -A && git commit -m "chore: sync embedded documents"
```

### Document Updates

```bash
# After modifying a template file:
# 1. Identify affected workflow files
grep -r "path=\"dev-handbook/templates/your-template.template.md\"" dev-handbook/workflow-instructions/

# After modifying a guide file:
# 1. Identify affected workflow files
grep -r "path=\"dev-handbook/guides/your-guide.g.md\"" dev-handbook/workflow-instructions/

# 2. Preview synchronization
bin/markdown-sync-embedded-documents --dry-run --verbose

# 3. Apply synchronization
bin/markdown-sync-embedded-documents --verbose

# 4. Commit both source and workflow changes
git add dev-handbook/templates/ dev-handbook/guides/
git add dev-handbook/workflow-instructions/
git commit -m "feat: update document and sync embedded instances"
```

### Pre-Release Checklist

```bash
# 1. Ensure all documents are synchronized
bin/markdown-sync-embedded-documents --dry-run
if [ $? -eq 0 ]; then echo "✅ All documents in sync"; else echo "❌ Documents need sync"; fi

# 2. Verify document directory organization
echo "Template structure:"
tree dev-handbook/templates -L 2
echo "Guide structure:"
tree dev-handbook/guides -L 2

# 3. Check for broken document references
echo "Checking template references..."
find dev-handbook/workflow-instructions -name "*.wf.md" -exec grep -l "<template path=" {} \; | while read file; do
  grep 'path="[^"]*"' "$file" | grep -o '"[^"]*"' | tr -d '"' | while read path; do
    [ -f "$path" ] || echo "Broken template reference in $file: $path"
  done
done

echo "Checking guide references..."
find dev-handbook/workflow-instructions -name "*.wf.md" -exec grep -l "<guide path=" {} \; | while read file; do
  grep 'path="[^"]*"' "$file" | grep -o '"[^"]*"' | tr -d '"' | while read path; do
    [ -f "$path" ] || echo "Broken guide reference in $file: $path"
  done
done

# 4. Final synchronization and commit
bin/markdown-sync-embedded-documents --verbose --commit
```

### Troubleshooting Quick Fixes

```bash
# Fix XML format issues
# Find malformed documents sections
grep -rn "<documents>" dev-handbook/workflow-instructions/ | grep -v "</documents>"

# Find template sections without closing tags
grep -rn "<template" dev-handbook/workflow-instructions/ | grep -v "</template>"

# Find guide sections without closing tags
grep -rn "<guide" dev-handbook/workflow-instructions/ | grep -v "</guide>"

# Find missing path attributes
grep -rn "<template[^>]*>" dev-handbook/workflow-instructions/ | grep -v 'path='
grep -rn "<guide[^>]*>" dev-handbook/workflow-instructions/ | grep -v 'path='

# Find mixed format usage (documents + templates containers)
grep -r -l "<documents>" dev-handbook/workflow-instructions/ | while read file; do
  if grep -q "<templates>" "$file"; then
    echo "Mixed format in: $file"
  fi
done

# Reset and re-sync if needed
git checkout -- dev-handbook/workflow-instructions/
bin/markdown-sync-embedded-documents --verbose
```

## Document Management Operations

### Adding New Templates

```bash
# 1. Create template file
mkdir -p dev-handbook/templates/new-category
touch dev-handbook/templates/new-category/new-template.template.md

# 2. Edit template content
# (Use your preferred editor)

# 3. Add reference in workflow file using <documents> format
# Example XML structure:
# <documents>
#     <template path="dev-handbook/templates/new-category/new-template.template.md">
#     </template>
# </documents>

# 4. Synchronize to populate embedded content
bin/markdown-sync-embedded-documents --verbose

# 5. Commit everything
git add dev-handbook/templates/new-category/new-template.template.md
git add dev-handbook/workflow-instructions/
git commit -m "feat: add new template and embed in workflow"
```

### Adding New Guides

```bash
# 1. Create guide file
mkdir -p dev-handbook/guides/new-category
touch dev-handbook/guides/new-category/new-guide.g.md

# 2. Edit guide content
# (Use your preferred editor)

# 3. Add reference in workflow file using <documents> format
# Example XML structure:
# <documents>
#     <guide path="dev-handbook/guides/new-category/new-guide.g.md">
#     </guide>
# </documents>

# 4. Synchronize to populate embedded content
bin/markdown-sync-embedded-documents --verbose

# 5. Commit everything
git add dev-handbook/guides/new-category/new-guide.g.md
git add dev-handbook/workflow-instructions/
git commit -m "feat: add new guide and embed in workflow"
```

### Moving Documents

```bash
# Moving templates
# 1. Move template file
git mv dev-handbook/templates/old-path/template.template.md dev-handbook/templates/new-path/template.template.md

# 2. Update path references in workflow files
grep -r "old-path/template\.template\.md" dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | while read file; do
  sed -i 's|old-path/template\.template\.md|new-path/template.template.md|g' "$file"
done

# Moving guides
# 1. Move guide file
git mv dev-handbook/guides/old-path/guide.g.md dev-handbook/guides/new-path/guide.g.md

# 2. Update path references in workflow files
grep -r "old-path/guide\.g\.md" dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | while read file; do
  sed -i 's|old-path/guide\.g\.md|new-path/guide.g.md|g' "$file"
done

# 3. Synchronize (should be no changes if paths updated correctly)
bin/markdown-sync-embedded-documents --dry-run

# 4. Commit the move and path updates
git add -A
git commit -m "refactor: move document and update references"
```

### Removing Documents

```bash
# Removing templates
# 1. Find all references to template
template_path="dev-handbook/templates/category/template.template.md"
grep -r "path=\"$template_path\"" dev-handbook/workflow-instructions/

# 2. Remove XML template sections from workflow files
# (Manual edit required)

# 3. Remove template file
git rm "$template_path"

# Removing guides
# 1. Find all references to guide
guide_path="dev-handbook/guides/category/guide.g.md"
grep -r "path=\"$guide_path\"" dev-handbook/workflow-instructions/

# 2. Remove XML guide sections from workflow files
# (Manual edit required)

# 3. Remove guide file
git rm "$guide_path"

# 4. Verify no references remain
bin/markdown-sync-embedded-documents --dry-run

# 5. Commit removal
git add -A
git commit -m "remove: unused document and references"
```

### Format Migration Operations

```bash
# Migrate from <templates> to <documents> format
# 1. Find workflows using old format
grep -r -l "<templates>" dev-handbook/workflow-instructions/

# 2. For each file, convert format manually:
# OLD:
# <templates>
#     <template path="...">content</template>
# </templates>
#
# NEW:
# <documents>
#     <template path="...">content</template>
# </documents>

# 3. Validate conversion
bin/markdown-sync-embedded-documents --dry-run

# 4. Apply synchronization to ensure content integrity
bin/markdown-sync-embedded-documents --verbose

# 5. Commit migration
git add dev-handbook/workflow-instructions/
git commit -m "refactor: migrate to universal document format"
```

## Monitoring and Maintenance

### Daily Checks

```bash
# Add to daily development routine
echo "Checking document synchronization..."
if bin/markdown-sync-embedded-documents --dry-run --verbose | grep -q "Template synchronized\|Guide synchronized\|Summary.*synchronized: [1-9]"; then
  echo "⚠️  Documents need synchronization"
  echo "Run: bin/markdown-sync-embedded-documents --verbose"
else
  echo "✅ All documents in sync"
fi
```

### Weekly Maintenance

```bash
#!/bin/bash
# weekly-document-maintenance.sh

echo "=== Weekly Document Maintenance ==="

echo "1. Checking document synchronization..."
bin/markdown-sync-embedded-documents --dry-run --verbose

echo "2. Validating template references..."
find dev-handbook/workflow-instructions -name "*.wf.md" -exec grep -l "<template path=" {} \; | while read file; do
  grep 'path="[^"]*"' "$file" | grep -o '"[^"]*"' | tr -d '"' | while read path; do
    [ -f "$path" ] || echo "❌ Broken template reference in $file: $path"
  done
done

echo "3. Validating guide references..."
find dev-handbook/workflow-instructions -name "*.wf.md" -exec grep -l "<guide path=" {} \; | while read file; do
  grep 'path="[^"]*"' "$file" | grep -o '"[^"]*"' | tr -d '"' | while read path; do
    [ -f "$path" ] || echo "❌ Broken guide reference in $file: $path"
  done
done

echo "4. Document directory overview..."
echo "Templates:"
tree dev-handbook/templates -L 2
echo "Guides:"
tree dev-handbook/guides -L 2

echo "5. Document count by category..."
echo "Templates by category:"
find dev-handbook/templates -name "*.template.md" | cut -d/ -f3 | sort | uniq -c
echo "Guides by category:"
find dev-handbook/guides -name "*.g.md" | cut -d/ -f3 | sort | uniq -c

echo "=== Maintenance Complete ==="
```

### Monthly Reports

```bash
#!/bin/bash
# monthly-document-report.sh

echo "=== Monthly Document Report ==="
echo "Report Date: $(date)"
echo

echo "Document Statistics:"
echo "- Total templates: $(find dev-handbook/templates -name '*.template.md' | wc -l)"
echo "- Total guides: $(find dev-handbook/guides -name '*.g.md' | wc -l)"
echo "- Embedded template instances: $(grep -r '<template path=' dev-handbook/workflow-instructions/ | wc -l)"
echo "- Embedded guide instances: $(grep -r '<guide path=' dev-handbook/workflow-instructions/ | wc -l)"
echo "- Workflow files with documents: $(grep -r '<documents>' dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | wc -l)"
echo "- Workflow files with legacy format: $(grep -r '<templates>' dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | wc -l)"

echo
echo "Template Usage by Category:"
find dev-handbook/templates -name "*.template.md" | cut -d/ -f3 | sort | uniq -c | sort -nr

echo
echo "Guide Usage by Category:"
find dev-handbook/guides -name "*.g.md" | cut -d/ -f3 | sort | uniq -c | sort -nr

echo
echo "Recent Document Changes:"
git log --since="1 month ago" --grep="template\|guide\|document" --oneline --no-merges

echo
echo "Format Migration Status:"
documents_count=$(grep -r '<documents>' dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | wc -l)
templates_count=$(grep -r '<templates>' dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | wc -l)
echo "- Files using <documents> format: $documents_count"
echo "- Files using <templates> format: $templates_count"
if [ $templates_count -gt 0 ]; then
  echo "⚠️  Migration to universal format incomplete"
else
  echo "✅ All files using universal format"
fi

echo
echo "Synchronization Status:"
if bin/markdown-sync-embedded-documents --dry-run --verbose | grep -q "Template synchronized\|Guide synchronized"; then
  echo "❌ Documents out of sync - run synchronization"
else
  echo "✅ All documents synchronized"
fi

echo "=== Report Complete ==="
```

## Integration Scripts

### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Checking document synchronization..."
if ! bin/markdown-sync-embedded-documents --dry-run >/dev/null 2>&1; then
  echo "❌ Document synchronization would make changes"
  echo "Run: bin/markdown-sync-embedded-documents --verbose"
  echo "Then commit the synchronized documents"
  exit 1
fi

echo "✅ Document synchronization check passed"
```

### Git Alias Setup

```bash
# Add to ~/.gitconfig or run as commands
git config alias.sync-docs '!bin/markdown-sync-embedded-documents --verbose'
git config alias.check-docs '!bin/markdown-sync-embedded-documents --dry-run'
git config alias.sync-and-commit '!bin/markdown-sync-embedded-documents --verbose --commit'

# Usage:
# git sync-docs
# git check-docs  
# git sync-and-commit
```

### Editor Integration

**VS Code Tasks (.vscode/tasks.json):**

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Sync Documents",
      "type": "shell",
      "command": "bin/markdown-sync-embedded-documents",
      "args": ["--verbose"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Check Documents",
      "type": "shell", 
      "command": "bin/markdown-sync-embedded-documents",
      "args": ["--dry-run", "--verbose"],
      "group": "test"
    }
  ]
}
```

## Emergency Procedures

### Document Corruption Recovery

```bash
# If documents become corrupted or sync fails:

# 1. Backup current state
git stash push -m "backup before document recovery"

# 2. Reset to last known good state
git checkout HEAD~1 -- dev-handbook/templates/
git checkout HEAD~1 -- dev-handbook/guides/
git checkout HEAD~1 -- dev-handbook/workflow-instructions/

# 3. Re-apply document changes gradually
# (Manual process - restore documents one by one)

# 4. Re-synchronize
bin/markdown-sync-embedded-documents --verbose

# 5. Verify and commit
git add -A
git commit -m "recover: restore document synchronization"
```

### Mass Document Update

```bash
# For major document format changes across all documents:

# 1. Create backup branch
git checkout -b document-mass-update-backup

# 2. Update all document files
# (Use find/sed or custom scripts)

# 3. Synchronize everything
bin/markdown-sync-embedded-documents --verbose

# 4. Verify changes are correct
git diff --stat

# 5. Commit mass update
git add -A
git commit -m "refactor: mass document format update"

# 6. Merge back to main branch
git checkout main
git merge document-mass-update-backup
```

## Performance Tips

### Large Repository Optimization

```bash
# For repositories with many workflow files:

# Sync specific directories only
bin/markdown-sync-embedded-documents --path dev-handbook/workflow-instructions/core/

# Use parallel processing for validation
find dev-handbook/workflow-instructions -name "*.wf.md" | xargs -P 4 -I {} grep -l "<template\|<guide" {}

# Cache document file readings
# (Script already optimizes this internally)
```

### Selective Synchronization

```bash
# Sync only specific templates
grep -r "specific-template.template.md" dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | while read file; do
  echo "Checking $file..."
  # Manual validation/update as needed
done

# Sync only specific guides
grep -r "specific-guide.g.md" dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | while read file; do
  echo "Checking $file..."
  # Manual validation/update as needed
done
```

## Format Conversion Utilities

### Automated Format Migration

```bash
#!/bin/bash
# migrate-to-universal-format.sh

echo "=== Migrating to Universal Document Format ==="

# Find files using old format
old_format_files=$(grep -r -l "<templates>" dev-handbook/workflow-instructions/)

if [ -z "$old_format_files" ]; then
  echo "✅ No files need migration"
  exit 0
fi

echo "Files to migrate:"
echo "$old_format_files"

# Backup before migration
git stash push -m "backup before format migration"

# Convert each file
echo "$old_format_files" | while read file; do
  echo "Converting $file..."
  sed -i 's/<templates>/<documents>/g' "$file"
  sed -i 's/<\/templates>/<\/documents>/g' "$file"
done

# Validate migration
echo "Validating migration..."
bin/markdown-sync-embedded-documents --dry-run

# Apply synchronization
echo "Synchronizing documents..."
bin/markdown-sync-embedded-documents --verbose

# Commit migration
git add dev-handbook/workflow-instructions/
git commit -m "refactor: migrate to universal document format"

echo "=== Migration Complete ==="
```

This operations guide provides practical, command-line focused guidance for day-to-day document synchronization tasks, complementing the comprehensive [Document Synchronization Guide](./document-synchronization.md).
