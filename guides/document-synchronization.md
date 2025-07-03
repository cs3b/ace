# Document Synchronization System

This guide covers the operational aspects of the document synchronization system, including script usage, maintenance procedures, and troubleshooting. The system supports embedding both templates and guides within workflow instructions using a universal document embedding format.

## Overview

The document synchronization system keeps embedded documents in workflow instructions synchronized with their corresponding source files. This ensures consistency and enables automated document updates across the development handbook.

### Key Components

- **Sync Script**: `bin/markdown-sync-embedded-documents` - CLI tool for synchronization
- **Template Directory**: `dev-handbook/templates/` - Central template repository  
- **Guide Directory**: `dev-handbook/guides/` - Reference documentation and best practices
- **Workflow Instructions**: `dev-handbook/workflow-instructions/` - Files with embedded documents
- **XML Format**: Standardized embedding format for automated parsing

## Script Usage

### Basic Operations

The synchronization script provides several modes of operation:

```bash
# Basic synchronization (default)
bin/markdown-sync-embedded-documents

# Preview changes without modifying files
bin/markdown-sync-embedded-documents --dry-run

# Detailed output with verbose logging
bin/markdown-sync-embedded-documents --verbose

# Automatic commit after synchronization
bin/markdown-sync-embedded-documents --commit

# Custom directory path
bin/markdown-sync-embedded-documents --path dev-handbook/workflow-instructions
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
bin/markdown-sync-embedded-documents --dry-run

# 2. Apply changes with detailed output
bin/markdown-sync-embedded-documents --verbose

# 3. Review changes manually
git diff

# 4. Commit if satisfied
git add -A && git commit -m "chore: sync embedded documents"
```

**Automated/CI Workflow:**

```bash
# Single command for automated synchronization
bin/markdown-sync-embedded-documents --verbose --commit
```

**Troubleshooting Workflow:**

```bash
# Check for issues without changes
bin/markdown-sync-embedded-documents --dry-run --verbose
```

## Document Directory Organization

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

## Universal Document Embedding Format

### New Format Structure

The system now supports a universal document embedding format using `<documents>` containers:

```xml
<documents>
    <template path="dev-handbook/templates/release-tasks/task.template.md">
        <!-- Template content -->
    </template>
    
    <guide path="dev-handbook/guides/development/testing.g.md">
        <!-- Guide content -->
    </guide>
</documents>
```

### Supported Document Types

#### Templates (`<template>` tags)

- **Path Pattern**: `dev-handbook/templates/**/*.template.md`
- **Purpose**: Reusable template content for document creation
- **Validation**: Must exist in templates directory

#### Guides (`<guide>` tags)

- **Path Pattern**: `dev-handbook/guides/**/*.g.md`
- **Purpose**: Reference documentation and best practices
- **Validation**: Must exist in guides directory

### Backward Compatibility

The system maintains backward compatibility with the legacy `<templates>` format:

```xml
<templates>
    <template path="dev-handbook/templates/release-tasks/task.template.md">
        <!-- Template content -->
    </template>
</templates>
```

Both formats are supported during the transition period.

## Synchronization Process

### How Synchronization Works

1. **Discovery**: Script scans workflow instruction files for `<documents>` and `<templates>` sections
2. **Extraction**: Parses XML to find `path` attributes and embedded content
3. **Comparison**: Compares embedded content with actual source files
4. **Synchronization**: Updates embedded content when differences are found
5. **Reporting**: Provides summary of changes made

### What Gets Synchronized

- **Document Content**: Complete content from source files
- **Formatting**: Preserves original document formatting and structure
- **Metadata**: YAML frontmatter and all document sections

### What Doesn't Get Synchronized

- **Workflow Instructions**: Only document sections are modified
- **Comments**: XML comments and workflow logic remain unchanged
- **File Structure**: No files are created or deleted, only content updated

## Maintenance Procedures

### Regular Synchronization

**Monthly Review:**

```bash
# Check for out-of-sync documents
bin/markdown-sync-embedded-documents --dry-run --verbose

# Apply updates if needed
bin/markdown-sync-embedded-documents --verbose --commit
```

**Before Releases:**

```bash
# Ensure all documents are synchronized
bin/markdown-sync-embedded-documents --verbose
git add -A && git commit -m "chore: sync documents before release"
```

**After Document Changes:**

```bash
# Immediate synchronization after updating documents
bin/markdown-sync-embedded-documents --verbose --commit
```

### Document Management

**Adding New Templates:**

1. Create template file in appropriate `dev-handbook/templates/` subdirectory
2. Add XML reference in workflow instruction files using `<documents>` format
3. Run synchronization to populate embedded content

**Adding New Guides:**

1. Create guide file in appropriate `dev-handbook/guides/` subdirectory with `.g.md` extension
2. Add XML reference in workflow instruction files using `<guide>` tag
3. Run synchronization to populate embedded content

**Updating Existing Documents:**

1. Modify source file in `dev-handbook/templates/` or `dev-handbook/guides/`
2. Run synchronization to update all embedded instances
3. Review changes and commit

**Removing Documents:**

1. Remove XML document references from workflow files
2. Delete source file from appropriate directory
3. Commit changes

### Validation and Quality Control

**Check Document Consistency:**

```bash
# Verify all embedded documents are up-to-date
bin/markdown-sync-embedded-documents --dry-run
```

**Validate XML Format:**

```bash
# Use grep to find potential format issues
grep -r "<documents>" dev-handbook/workflow-instructions/
grep -r "</documents>" dev-handbook/workflow-instructions/
grep -r "<templates>" dev-handbook/workflow-instructions/
grep -r "</templates>" dev-handbook/workflow-instructions/
```

**Check for Missing Documents:**

```bash
# Find broken template references
find dev-handbook/templates -name "*.template.md" -exec basename {} \; | sort > /tmp/templates.txt
grep -r 'path="dev-handbook/templates/' dev-handbook/workflow-instructions/ | grep -o '[^"]*\.template\.md' | sort > /tmp/referenced.txt
diff /tmp/templates.txt /tmp/referenced.txt

# Find broken guide references
find dev-handbook/guides -name "*.g.md" -exec basename {} \; | sort > /tmp/guides.txt
grep -r 'path="dev-handbook/guides/' dev-handbook/workflow-instructions/ | grep -o '[^"]*\.g\.md' | sort > /tmp/guide-refs.txt
diff /tmp/guides.txt /tmp/guide-refs.txt
```

## Troubleshooting

### Common Issues

**Document Not Synchronizing:**

Check these potential causes:

1. XML format errors in workflow file
2. Incorrect path attribute in document reference
3. Source file doesn't exist at specified path
4. File permissions preventing writes

```bash
# Debug with verbose output
bin/markdown-sync-embedded-documents --dry-run --verbose
```

**Script Execution Errors:**

```bash
# Verify script exists and is executable
ls -la bin/markdown-sync-embedded-documents
```

**Path Resolution Issues:**

```bash
# Check if document files exist
find dev-handbook/templates -name "*.template.md" | head -10
find dev-handbook/guides -name "*.g.md" | head -10
```

**Content Differences Persist:**

1. Check for hidden characters or encoding issues
2. Verify source file contains expected content  
3. Ensure XML document section is properly formatted

### Guide-Specific Troubleshooting

**Guide Not Found:**

```bash
# Verify guide exists with correct extension
ls -la dev-handbook/guides/**/*.g.md
```

**Mixed Document Types:**

```bash
# Find workflows using both formats
grep -r -l "<documents>" dev-handbook/workflow-instructions/ | while read file; do
  if grep -q "<templates>" "$file"; then
    echo "Mixed format in: $file"
  fi
done
```

### Error Messages

**"Template file not found":**

- Verify path attribute points to existing file
- Check for typos in template path
- Ensure template file has `.template.md` extension

**"Guide file not found":**

- Verify path attribute points to existing file
- Check for typos in guide path
- Ensure guide file has `.g.md` extension

**"Invalid XML format":**

- Check for missing closing tags (`</template>`, `</guide>`, `</documents>`)
- Verify proper nesting of document sections
- Ensure path attribute is properly quoted

**"Permission denied":**

- Check file permissions on workflow instruction files
- Ensure write access to target directory
- Run with appropriate user permissions

### Recovery Procedures

**Restore from Backup:**

```bash
# If synchronization caused issues, restore from git
git checkout HEAD -- dev-handbook/workflow-instructions/
```

**Manual Synchronization:**

```bash
# Copy document content manually if script fails
cp dev-handbook/templates/path/to/template.md /tmp/
cp dev-handbook/guides/path/to/guide.g.md /tmp/
# Edit workflow file manually to embed content
```

**Reset and Re-sync:**

```bash
# Reset to clean state and re-synchronize
git stash
bin/markdown-sync-embedded-documents --verbose
```

## Integration with Project Workflows

### Development Workflow Integration

**Pre-commit Hook (Optional):**

```bash
#!/bin/sh
# .git/hooks/pre-commit
bin/markdown-sync-embedded-documents --dry-run
if [ $? -ne 0 ]; then
  echo "Document synchronization would make changes. Run sync first."
  exit 1
fi
```

**IDE Integration:**

- Configure editor to run sync script as custom task
- Set up file watchers on template and guide directories for automatic sync
- Use project-specific commands in IDE terminal

### CI/CD Integration

**GitHub Actions Example:**

```yaml
- name: Synchronize Documents
  run: |
    bin/markdown-sync-embedded-documents --verbose
    if [ -n "$(git status --porcelain)" ]; then
      git config user.name "Document Sync Bot"
      git config user.email "bot@example.com"
      git add -A
      git commit -m "chore: sync embedded documents [bot]"
      git push
    fi
```

**Local Automation:**

```bash
# Add to project bin/ scripts for common tasks
echo '#!/bin/bash' > bin/sync-documents
echo 'bin/markdown-sync-embedded-documents --verbose --commit' >> bin/sync-documents
chmod +x bin/sync-documents
```

## Best Practices

### Document Development

1. **Test Documents Thoroughly**: Verify document content before embedding
2. **Use Descriptive Paths**: Choose clear, logical document paths
3. **Maintain Consistency**: Follow established naming and organization patterns
4. **Document Changes**: Include document updates in commit messages

### Synchronization Workflow

1. **Dry Run First**: Always preview changes before applying
2. **Review Changes**: Manually inspect diffs after synchronization  
3. **Atomic Commits**: Commit document changes separately from other modifications
4. **Regular Maintenance**: Run synchronization regularly to prevent drift

### Collaboration

1. **Coordinate Updates**: Communicate document changes to team members
2. **Batch Updates**: Group related document changes together
3. **Clear Commit Messages**: Use consistent commit message format for document sync
4. **Document Rationale**: Explain significant document changes in commit messages

## Architecture References

This system is built on the following architectural decisions:

- [ADR-004: Consistent Path Standards](../../docs/decisions/ADR-004-consistent-path-standards.md)
- [ADR-005: Universal Document Embedding System](../../docs/decisions/ADR-005-universal-document-embedding-system.md)

## Related Documentation

- [Document Sync Operations Guide](./document-sync-operations.md) - Quick reference for common operations
- [Workflow Instructions](../workflow-instructions/) - Implementation examples
- [Project Management Guide](./project-management.g.md) - Development workflow context
- [Version Control Guide](./version-control-system.g.md) - Git workflow integration

This comprehensive guide ensures the document synchronization system can be maintained and used effectively by all team members, supporting consistent and up-to-date document content across the development handbook.
