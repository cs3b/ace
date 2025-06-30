# Template Synchronization System

This guide covers the operational aspects of the template synchronization system, including script usage, maintenance procedures, and troubleshooting. For template embedding standards and format, see [Template Embedding Guide](./.meta/template-embedding.g.md).

## Overview

The template synchronization system keeps embedded templates in workflow instructions synchronized with their corresponding template files in the `dev-handbook/templates/` directory. This ensures consistency and enables automated template updates across the development handbook.

### Key Components

- **Sync Script**: `bin/markdown-sync-embedded-documents` - CLI tool for synchronization
- **Template Directory**: `dev-handbook/templates/` - Central template repository  
- **Workflow Instructions**: `dev-handbook/workflow-instructions/` - Files with embedded templates
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
git add -A && git commit -m "chore: sync embedded templates"
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

## Template Directory Organization

### Directory Structure

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

### Naming Conventions

- **File Extension**: All templates use `.template.md` extension
- **Directory Names**: Descriptive, kebab-case names indicating purpose
- **File Names**: Clear, specific names without redundant "template" prefix

### Template Path References

In workflow instructions, reference templates using full paths:

```xml
<templates>
    <template path="dev-handbook/templates/release-tasks/task.template.md">
    <!-- Template content -->
    </template>
</templates>
```

## Synchronization Process

### How Synchronization Works

1. **Discovery**: Script scans workflow instruction files for `<templates>` sections
2. **Extraction**: Parses XML to find `path` attributes and embedded content
3. **Comparison**: Compares embedded content with actual template files
4. **Synchronization**: Updates embedded content when differences are found
5. **Reporting**: Provides summary of changes made

### What Gets Synchronized

- **Template Content**: Complete content from template files
- **Formatting**: Preserves original template formatting and structure
- **Metadata**: YAML frontmatter and all template sections

### What Doesn't Get Synchronized

- **Workflow Instructions**: Only template sections are modified
- **Comments**: XML comments and workflow logic remain unchanged
- **File Structure**: No files are created or deleted, only content updated

## Maintenance Procedures

### Regular Synchronization

**Monthly Review:**

```bash
# Check for out-of-sync templates
bin/markdown-sync-embedded-documents --dry-run --verbose

# Apply updates if needed
bin/markdown-sync-embedded-documents --verbose --commit
```

**Before Releases:**

```bash
# Ensure all templates are synchronized
bin/markdown-sync-embedded-documents --verbose
git add -A && git commit -m "chore: sync templates before release"
```

**After Template Changes:**

```bash
# Immediate synchronization after updating templates
bin/markdown-sync-embedded-documents --verbose --commit
```

### Template Management

**Adding New Templates:**

1. Create template file in appropriate `dev-handbook/templates/` subdirectory
2. Add XML reference in workflow instruction files
3. Run synchronization to populate embedded content

**Updating Existing Templates:**

1. Modify template file in `dev-handbook/templates/`
2. Run synchronization to update all embedded instances
3. Review changes and commit

**Removing Templates:**

1. Remove XML template references from workflow files
2. Delete template file from `dev-handbook/templates/`
3. Commit changes

### Validation and Quality Control

**Check Template Consistency:**

```bash
# Verify all embedded templates are up-to-date
bin/markdown-sync-embedded-documents --dry-run
```

**Validate XML Format:**

```bash
# Use grep to find potential format issues
grep -r "<templates>" dev-handbook/workflow-instructions/
grep -r "</templates>" dev-handbook/workflow-instructions/
```

**Check for Missing Templates:**

```bash
# Find broken template references
find dev-handbook/templates -name "*.template.md" -exec basename {} \; | sort > /tmp/templates.txt
grep -r 'path="dev-handbook/templates/' dev-handbook/workflow-instructions/ | grep -o '[^"]*\.template\.md' | sort > /tmp/referenced.txt
diff /tmp/templates.txt /tmp/referenced.txt
```

## Troubleshooting

### Common Issues

**Template Not Synchronizing:**

Check these potential causes:

1. XML format errors in workflow file
2. Incorrect path attribute in template reference
3. Template file doesn't exist at specified path
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
# Check if template files exist
find dev-handbook/templates -name "*.template.md" | head -10
```

**Content Differences Persist:**

1. Check for hidden characters or encoding issues
2. Verify template file contains expected content  
3. Ensure XML template section is properly formatted

### Error Messages

**"Template file not found":**

- Verify path attribute points to existing file
- Check for typos in template path
- Ensure template file has `.template.md` extension

**"Invalid XML format":**

- Check for missing closing tags (`</template>`, `</templates>`)
- Verify proper nesting of template sections
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
# Copy template content manually if script fails
cp dev-handbook/templates/path/to/template.md /tmp/
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
  echo "Template synchronization would make changes. Run sync first."
  exit 1
fi
```

**IDE Integration:**

- Configure editor to run sync script as custom task
- Set up file watchers on template directory for automatic sync
- Use project-specific commands in IDE terminal

### CI/CD Integration

**GitHub Actions Example:**

```yaml
- name: Synchronize Templates
  run: |
    bin/markdown-sync-embedded-documents --verbose
    if [ -n "$(git status --porcelain)" ]; then
      git config user.name "Template Sync Bot"
      git config user.email "bot@example.com"
      git add -A
      git commit -m "chore: sync embedded templates [bot]"
      git push
    fi
```

**Local Automation:**

```bash
# Add to project bin/ scripts for common tasks
echo '#!/bin/bash' > bin/sync-templates
echo 'bin/markdown-sync-embedded-documents --verbose --commit' >> bin/sync-templates
chmod +x bin/sync-templates
```

## Best Practices

### Template Development

1. **Test Templates Thoroughly**: Verify template content before embedding
2. **Use Descriptive Paths**: Choose clear, logical template paths
3. **Maintain Consistency**: Follow established naming and organization patterns
4. **Document Changes**: Include template updates in commit messages

### Synchronization Workflow

1. **Dry Run First**: Always preview changes before applying
2. **Review Changes**: Manually inspect diffs after synchronization  
3. **Atomic Commits**: Commit template changes separately from other modifications
4. **Regular Maintenance**: Run synchronization regularly to prevent drift

### Collaboration

1. **Coordinate Updates**: Communicate template changes to team members
2. **Batch Updates**: Group related template changes together
3. **Clear Commit Messages**: Use consistent commit message format for template sync
4. **Document Rationale**: Explain significant template changes in commit messages

## Related Documentation

- [Template Embedding Guide](./.meta/template-embedding.g.md) - Standards and XML format
- [Workflow Instructions](../workflow-instructions/) - Implementation examples
- [Project Management Guide](./project-management.g.md) - Development workflow context
- [Version Control Guide](./version-control-system.g.md) - Git workflow integration

This operational guide ensures the template synchronization system can be maintained and used effectively by all team members, supporting consistent and up-to-date template content across the development handbook.
