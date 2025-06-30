# Template Sync Operations Guide

Quick reference for template synchronization operations, focusing on common tasks and workflows for maintaining template consistency across the development handbook.

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
# Check if templates need synchronization
bin/markdown-sync-embedded-documents --dry-run | grep -E "(Template|Summary)"

# Verify all embedded templates exist
grep -r 'path="dev-handbook/templates/' dev-handbook/workflow-instructions/ | cut -d'"' -f2 | while read path; do
  [ -f "$path" ] || echo "Missing: $path"
done

# Count embedded templates
grep -r "<template path=" dev-handbook/workflow-instructions/ | wc -l
```

## Common Workflows

### Daily Development

```bash
# 1. Check for template changes (morning routine)
bin/markdown-sync-embedded-documents --dry-run

# 2. If changes needed, apply them
bin/markdown-sync-embedded-documents --verbose

# 3. Review and commit changes
git diff
git add -A && git commit -m "chore: sync embedded templates"
```

### Template Updates

```bash
# After modifying a template file:
# 1. Identify affected workflow files
grep -r "path=\"dev-handbook/templates/your-template.template.md\"" dev-handbook/workflow-instructions/

# 2. Preview synchronization
bin/markdown-sync-embedded-documents --dry-run --verbose

# 3. Apply synchronization
bin/markdown-sync-embedded-documents --verbose

# 4. Commit both template and workflow changes
git add dev-handbook/templates/your-template.template.md
git add dev-handbook/workflow-instructions/
git commit -m "feat: update template and sync embedded instances"
```

### Pre-Release Checklist

```bash
# 1. Ensure all templates are synchronized
bin/markdown-sync-embedded-documents --dry-run
if [ $? -eq 0 ]; then echo "✅ All templates in sync"; else echo "❌ Templates need sync"; fi

# 2. Verify template directory organization
tree dev-handbook/templates -L 2

# 3. Check for broken template references
find dev-handbook/workflow-instructions -name "*.wf.md" -exec grep -l "<template path=" {} \; | while read file; do
  grep 'path="[^"]*"' "$file" | grep -o '"[^"]*"' | tr -d '"' | while read path; do
    [ -f "$path" ] || echo "Broken reference in $file: $path"
  done
done

# 4. Final synchronization and commit
bin/markdown-sync-embedded-documents --verbose --commit
```

### Troubleshooting Quick Fixes

```bash
# Fix XML format issues
# Find malformed template sections
grep -rn "<templates>" dev-handbook/workflow-instructions/ | grep -v "</templates>"

# Find template sections without closing tags
grep -rn "<template" dev-handbook/workflow-instructions/ | grep -v "</template>"

# Find missing path attributes
grep -rn "<template[^>]*>" dev-handbook/workflow-instructions/ | grep -v 'path='

# Reset and re-sync if needed
git checkout -- dev-handbook/workflow-instructions/
bin/markdown-sync-embedded-documents --verbose
```

## Template Management Operations

### Adding New Templates

```bash
# 1. Create template file
mkdir -p dev-handbook/templates/new-category
touch dev-handbook/templates/new-category/new-template.template.md

# 2. Edit template content
# (Use your preferred editor)

# 3. Add reference in workflow file
# (Add XML template section manually)

# 4. Synchronize to populate embedded content
bin/markdown-sync-embedded-documents --verbose

# 5. Commit everything
git add dev-handbook/templates/new-category/new-template.template.md
git add dev-handbook/workflow-instructions/
git commit -m "feat: add new template and embed in workflow"
```

### Moving Templates

```bash
# 1. Move template file
git mv dev-handbook/templates/old-path/template.md dev-handbook/templates/new-path/template.md

# 2. Update path references in workflow files
grep -r "old-path/template.md" dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | while read file; do
  sed -i 's|old-path/template\.md|new-path/template.md|g' "$file"
done

# 3. Synchronize (should be no changes if paths updated correctly)
bin/markdown-sync-embedded-documents --dry-run

# 4. Commit the move and path updates
git add -A
git commit -m "refactor: move template and update references"
```

### Removing Templates

```bash
# 1. Find all references to template
template_path="dev-handbook/templates/category/template.template.md"
grep -r "path=\"$template_path\"" dev-handbook/workflow-instructions/

# 2. Remove XML template sections from workflow files
# (Manual edit required)

# 3. Remove template file
git rm "$template_path"

# 4. Verify no references remain
bin/markdown-sync-embedded-documents --dry-run

# 5. Commit removal
git add -A
git commit -m "remove: unused template and references"
```

## Monitoring and Maintenance

### Daily Checks

```bash
# Add to daily development routine
echo "Checking template synchronization..."
if bin/markdown-sync-embedded-documents --dry-run --verbose | grep -q "Template synchronized\|Summary.*synchronized: [1-9]"; then
  echo "⚠️  Templates need synchronization"
  echo "Run: bin/markdown-sync-embedded-documents --verbose"
else
  echo "✅ All templates in sync"
fi
```

### Weekly Maintenance

```bash
#!/bin/bash
# weekly-template-maintenance.sh

echo "=== Weekly Template Maintenance ==="

echo "1. Checking template synchronization..."
bin/markdown-sync-embedded-documents --dry-run --verbose

echo "2. Validating template references..."
find dev-handbook/workflow-instructions -name "*.wf.md" -exec grep -l "<template path=" {} \; | while read file; do
  grep 'path="[^"]*"' "$file" | grep -o '"[^"]*"' | tr -d '"' | while read path; do
    [ -f "$path" ] || echo "❌ Broken reference in $file: $path"
  done
done

echo "3. Template directory overview..."
tree dev-handbook/templates -L 2

echo "4. Template count by category..."
find dev-handbook/templates -name "*.template.md" | cut -d/ -f3 | sort | uniq -c

echo "=== Maintenance Complete ==="
```

### Monthly Reports

```bash
#!/bin/bash
# monthly-template-report.sh

echo "=== Monthly Template Report ==="
echo "Report Date: $(date)"
echo

echo "Template Statistics:"
echo "- Total templates: $(find dev-handbook/templates -name '*.template.md' | wc -l)"
echo "- Embedded instances: $(grep -r '<template path=' dev-handbook/workflow-instructions/ | wc -l)"
echo "- Workflow files with templates: $(grep -r '<templates>' dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | wc -l)"

echo
echo "Template Usage by Category:"
find dev-handbook/templates -name "*.template.md" | cut -d/ -f3 | sort | uniq -c | sort -nr

echo
echo "Recent Template Changes:"
git log --since="1 month ago" --grep="template" --oneline --no-merges

echo
echo "Synchronization Status:"
if bin/markdown-sync-embedded-documents --dry-run --verbose | grep -q "Template synchronized"; then
  echo "❌ Templates out of sync - run synchronization"
else
  echo "✅ All templates synchronized"
fi

echo "=== Report Complete ==="
```

## Integration Scripts

### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Checking template synchronization..."
if ! bin/markdown-sync-embedded-documents --dry-run >/dev/null 2>&1; then
  echo "❌ Template synchronization would make changes"
  echo "Run: bin/markdown-sync-embedded-documents --verbose"
  echo "Then commit the synchronized templates"
  exit 1
fi

echo "✅ Template synchronization check passed"
```

### Git Alias Setup

```bash
# Add to ~/.gitconfig or run as commands
git config alias.sync-templates '!bin/markdown-sync-embedded-documents --verbose'
git config alias.check-templates '!bin/markdown-sync-embedded-documents --dry-run'
git config alias.sync-and-commit '!bin/markdown-sync-embedded-documents --verbose --commit'

# Usage:
# git sync-templates
# git check-templates  
# git sync-and-commit
```

### Editor Integration

**VS Code Tasks (.vscode/tasks.json):**

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Sync Templates",
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
      "label": "Check Templates",
      "type": "shell", 
      "command": "bin/markdown-sync-embedded-documents",
      "args": ["--dry-run", "--verbose"],
      "group": "test"
    }
  ]
}
```

## Emergency Procedures

### Template Corruption Recovery

```bash
# If templates become corrupted or sync fails:

# 1. Backup current state
git stash push -m "backup before template recovery"

# 2. Reset to last known good state
git checkout HEAD~1 -- dev-handbook/templates/
git checkout HEAD~1 -- dev-handbook/workflow-instructions/

# 3. Re-apply template changes gradually
# (Manual process - restore templates one by one)

# 4. Re-synchronize
bin/markdown-sync-embedded-documents --verbose

# 5. Verify and commit
git add -A
git commit -m "recover: restore template synchronization"
```

### Mass Template Update

```bash
# For major template format changes across all templates:

# 1. Create backup branch
git checkout -b template-mass-update-backup

# 2. Update all template files
# (Use find/sed or custom scripts)

# 3. Synchronize everything
bin/markdown-sync-embedded-documents --verbose

# 4. Verify changes are correct
git diff --stat

# 5. Commit mass update
git add -A
git commit -m "refactor: mass template format update"

# 6. Merge back to main branch
git checkout main
git merge template-mass-update-backup
```

## Performance Tips

### Large Repository Optimization

```bash
# For repositories with many workflow files:

# Sync specific directories only
bin/markdown-sync-embedded-documents --path dev-handbook/workflow-instructions/core/

# Use parallel processing for validation
find dev-handbook/workflow-instructions -name "*.wf.md" | xargs -P 4 -I {} grep -l "<template" {}

# Cache template file readings
# (Script already optimizes this internally)
```

### Selective Synchronization

```bash
# Sync only specific templates
grep -r "specific-template.template.md" dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | while read file; do
  echo "Checking $file..."
  # Manual validation/update as needed
done
```

This operations guide provides practical, command-line focused guidance for day-to-day template synchronization tasks, complementing the comprehensive [Template Synchronization Guide](./template-synchronization.md).
