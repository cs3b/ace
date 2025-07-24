# Documents Embedded Synchronization Guide

This guide covers the operational aspects of the document synchronization system, focusing on the `handbook sync-templates` tool usage, maintenance procedures, and troubleshooting. The system supports embedding both templates and guides within workflow instructions using the universal `<documents>` container format.

## Overview

The document synchronization system keeps embedded documents in workflow instructions synchronized with their corresponding source files. This ensures consistency and enables automated document updates across the development handbook.

### Key Components

- **Sync Script**: `handbook sync-templates` - CLI tool for synchronization
- **Template Directory**: `dev-handbook/templates/` - Central template repository  
- **Guide Directory**: `dev-handbook/guides/` - Reference documentation and best practices
- **Workflow Instructions**: `dev-handbook/workflow-instructions/` - Files with embedded documents
- **Universal Format**: `<documents>` container with `<template>` and `<guide>` tags

## Script Usage

### Basic Operations

The synchronization script provides several modes of operation:

```bash
# Basic synchronization (default)
handbook sync-templates

# Preview changes without modifying files
handbook sync-templates --dry-run

# Detailed output with verbose logging
handbook sync-templates --verbose

# Automatic commit after synchronization
handbook sync-templates --commit

# Custom directory path
handbook sync-templates --path dev-handbook/workflow-instructions
```

### Command Options

| Option | Description | Use Case |
|--------|-------------|----------|
| `--dry-run` | Preview changes without modifying files | Testing changes before applying |
| `--verbose` | Show detailed processing information | Debugging synchronization issues |
| `--path PATH` | Directory to scan (default: dev-handbook/workflow-instructions) | Custom workflow locations |
| `--commit` | Automatically commit changes after synchronization | Automated workflows and CI |
| `-h, --help` | Show help message | Reference and option discovery |

### Common Usage Patterns

**Development Workflow:**

```bash
# 1. Preview changes first
handbook sync-templates --dry-run

# 2. Apply changes with detailed output
handbook sync-templates --verbose

# 3. Review changes manually
git diff

# 4. Commit if satisfied
git add -A && git commit -m "chore: sync embedded documents"
```

**Automated/CI Workflow:**

```bash
# Single command for automated synchronization
handbook sync-templates --verbose --commit
```

**Troubleshooting Workflow:**

```bash
# Check for issues without changes
handbook sync-templates --dry-run --verbose
```

## Quick Commands Reference

### Essential Operations

```bash
# Preview what will change
handbook sync-templates --dry-run

# Synchronize with detailed output  
handbook sync-templates --verbose

# Synchronize and auto-commit
handbook sync-templates --verbose --commit

# Check script help
handbook sync-templates --help
```

### Status Checks

```bash
# Check if documents need synchronization
handbook sync-templates --dry-run | grep -E "(Template|Guide|Summary)"

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
handbook sync-templates --dry-run

# 2. If changes needed, apply them
handbook sync-templates --verbose

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
handbook sync-templates --dry-run --verbose

# 3. Apply synchronization
handbook sync-templates --verbose

# 4. Commit both source and workflow changes
git add dev-handbook/templates/ dev-handbook/guides/
git add dev-handbook/workflow-instructions/
git commit -m "feat: update document and sync embedded instances"
```

### Pre-Release Checklist

```bash
# 1. Ensure all documents are synchronized
handbook sync-templates --dry-run
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
handbook sync-templates --verbose --commit
```

## Troubleshooting

### Quick Fixes

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

# Find mixed format usage (documents + legacy containers)
grep -r -l "<documents>" dev-handbook/workflow-instructions/ | while read file; do
  if grep -q "<templates>" "$file"; then
    echo "Mixed format in: $file"
  fi
done

# Reset and re-sync if needed
git checkout -- dev-handbook/workflow-instructions/
handbook sync-templates --verbose
```

### Common Issues

#### Missing Source Files

```bash
# Check for broken references
handbook sync-templates --dry-run --verbose | grep "ERROR"

# Fix by creating missing files or updating paths
```

#### XML Format Errors

```bash
# Validate XML structure in workflow files
find dev-handbook/workflow-instructions -name "*.wf.md" -exec xmllint --xpath "//documents" {} \; 2>/dev/null

# Look for common XML issues
grep -r "<documents>" dev-handbook/workflow-instructions/ | grep -v -E "(</documents>|<!--)"
```

#### Sync Failures

```bash
# Run with verbose output to identify issues
handbook sync-templates --dry-run --verbose

# Check file permissions
ls -la dev-handbook/workflow-instructions/*.wf.md

# Verify Git status
git status dev-handbook/workflow-instructions/
```

## Document Management Operations

### Adding New Templates

```bash
# 1. Create template file
touch dev-handbook/templates/new-category/new-template.template.md

# 2. Add content to template

# 3. Embed in workflow file using documents format
echo '<documents>
    <template path="dev-handbook/templates/new-category/new-template.template.md">
    <!-- Content will be synced automatically -->
    </template>
</documents>' >> workflow-file.wf.md

# 4. Run initial sync
handbook sync-templates --verbose
```

### Adding New Guides

```bash
# 1. Create guide file
touch dev-handbook/guides/new-guide.g.md

# 2. Add content to guide

# 3. Embed in workflow file using documents format
echo '<documents>
    <guide path="dev-handbook/guides/new-guide.g.md">
    <!-- Content will be synced automatically -->
    </guide>
</documents>' >> workflow-file.wf.md

# 4. Run initial sync
handbook sync-templates --verbose
```

### Removing Documents

```bash
# 1. Remove embedded references from workflow files
grep -r "path=\"path/to/document\"" dev-handbook/workflow-instructions/

# 2. Delete the source file
rm dev-handbook/templates/path/to/template.template.md
# or
rm dev-handbook/guides/path/to/guide.g.md

# 3. Verify no broken references remain
handbook sync-templates --dry-run --verbose
```

### Moving Documents

```bash
# 1. Move the source file
mv dev-handbook/templates/old/path.template.md dev-handbook/templates/new/path.template.md

# 2. Update all embedded path references
grep -r "old/path.template.md" dev-handbook/workflow-instructions/ | cut -d: -f1 | sort -u | while read file; do
  sed -i 's|old/path.template.md|new/path.template.md|g' "$file"
done

# 3. Sync to update content
handbook sync-templates --verbose
```

## Directory Organization

### Template Directory Structure

Templates are organized by purpose and type:

```
dev-handbook/templates/
├── code-docs/               # API and code documentation
│   ├── javascript-jsdoc.template.md
│   └── ruby-yard.template.md
├── project-docs/            # Core project documentation
│   ├── architecture.template.md
│   ├── blueprint.template.md
│   ├── decisions/
│   │   └── adr.template.md
│   ├── prd.template.md
│   └── vision.template.md
├── release-docs/            # Release documentation
│   └── documentation.template.md
├── release-management/      # Release planning and tracking
│   ├── changelog.template.md
│   └── release-overview.template.md
├── release-planning/        # Release preparation
│   └── release-readme.template.md
├── release-reflections/     # Post-release analysis
│   └── retrospective.template.md
├── release-tasks/           # Task templates
│   └── task.template.md
├── release-testing/         # Testing templates
│   └── test-case.template.md
├── session-management/      # Session and context templates
│   └── session-context.template.md
└── user-docs/               # User-facing documentation
    └── user-guide.template.md
```

### Guide Directory Structure

Guides are organized by purpose and include `.g.md` extension:

```
dev-handbook/guides/
├── development/             # Development practices
│   ├── testing.g.md
│   ├── code-review.g.md
│   └── debugging.g.md
├── project-management/      # Project management guides
│   ├── task-management.g.md
│   └── release-planning.g.md
├── documentation/           # Documentation standards
│   ├── writing-style.g.md
│   └── template-creation.g.md
└── workflows/               # Workflow-specific guides
    ├── git-workflow.g.md
    └── deployment.g.md
```

### Naming Conventions

- **Template Extension**: All templates use `.template.md` extension
- **Guide Extension**: All guides use `.g.md` extension
- **Directory Names**: Descriptive, kebab-case names indicating purpose
- **File Names**: Clear, specific names without redundant type prefix

## Integration with Development Workflow

### Git Hooks Integration

```bash
# Pre-commit hook to ensure documents are synchronized
#!/bin/bash
# .git/hooks/pre-commit

echo "Checking document synchronization..."
if ! handbook sync-templates --dry-run --verbose; then
  echo "❌ Documents out of sync. Run: handbook sync-templates --verbose"
  exit 1
fi
echo "✅ Documents synchronized"
```

### CI/CD Integration

```yaml
# GitHub Actions example
name: Document Sync Check
on: [push, pull_request]

jobs:
  check-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Check document synchronization
        run: |
          handbook sync-templates --dry-run --verbose
          if [ $? -ne 0 ]; then
            echo "Documents need synchronization"
            exit 1
          fi
```

## Performance Considerations

### Large Document Sets

```bash
# Process specific directories only
handbook sync-templates --path dev-handbook/workflow-instructions/specific-dir/

# Use dry-run for quick checks
handbook sync-templates --dry-run

# Parallelize for large repositories (advanced)
find dev-handbook/workflow-instructions -name "*.wf.md" | xargs -P 4 -I {} handbook sync-templates --path {}
```

### Optimization Tips

1. **Regular Sync**: Run synchronization regularly to catch issues early
2. **Dry-Run First**: Always preview changes before applying
3. **Focused Paths**: Use specific paths when working on subsets
4. **Batch Operations**: Group related document changes together
5. **Monitor Performance**: Use verbose output to identify slow operations

## Related Documentation

- [Documents Embedding Guide](dev-handbook/guides/documents-embedding.g.md) - XML standards and principles
- [Workflow Instructions Organization](dev-handbook/guides/workflow-instructions-organization.g.md) - Workflow structure
- [Template Creation Guide](dev-handbook/guides/template-creation.g.md) - Creating new templates

This guide provides comprehensive coverage of the `handbook sync-templates` tool and related operational procedures for maintaining document synchronization across the development handbook system.
