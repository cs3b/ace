# ace-docs Usage Guide

Comprehensive documentation for using ace-docs commands and features.

## Table of Contents

- [Overview](#overview)
- [Commands](#commands)
  - [status](#status-command)
  - [discover](#discover-command)
  - [diff](#diff-command)
  - [update](#update-command)
  - [validate](#validate-command)
- [Configuration](#configuration)
- [Frontmatter Schema](#frontmatter-schema)
- [Workflow Integration](#workflow-integration)
- [Examples](#examples)

## Overview

ace-docs is a documentation management system that uses YAML frontmatter to track document metadata, analyze changes, and ensure documentation stays current. It integrates with git for change detection and supports rule-based validation.

## Commands

### version Command

Display the current version of ace-docs.

```bash
ace-docs version
```

**Output:**
- Version number in format: `ace-docs version X.Y.Z`

**Examples:**
```bash
# Check installed version
ace-docs version
```

### status Command

Display the status of all managed documents with freshness indicators.

```bash
ace-docs status [OPTIONS]
```

**Options:**
- `--type TYPE` - Filter by document type (guide, api, workflow, etc.)
- `--needs-update` - Show only documents needing update
- `--freshness STATUS` - Filter by freshness (current, stale, outdated)

**Output:**
- Table showing document name, type, last updated date, and freshness status
- Color-coded freshness indicators (green=current, yellow=stale, red=outdated)

**Examples:**
```bash
# Show all documents
ace-docs status

# Show only guides needing update
ace-docs status --type guide --needs-update

# Show stale documents
ace-docs status --freshness stale
```

### discover Command

Find and list all managed documents in the project.

```bash
ace-docs discover
```

**Output:**
- Lists all markdown files with ace-docs frontmatter
- Shows document path and type
- Useful for initial setup verification

**Examples:**
```bash
# Discover all managed documents
ace-docs discover
```

### analyze Command

**NEW in v0.3.0** - Batch analyze documents with LLM-powered diff compaction for efficient documentation updates.

```bash
ace-docs analyze [FILES...] [OPTIONS]
```

**Arguments:**
- `FILES...` - Specific files to analyze (optional)

**Options:**
- `--needs-update` - Analyze only documents needing updates (default if no files specified)
- `--type TYPE` - Filter by document type (guide, context, workflow, etc.)
- `--freshness STATUS` - Filter by freshness (current, stale, outdated)
- `--since DATE` - Override automatic time range (e.g., '1 week ago', '2025-01-01')
- `--exclude-renames` - Exclude renamed files from diff analysis
- `--exclude-moves` - Exclude moved files from diff analysis
- `--output FORMAT` - Output format: compact|detailed (default: compact)

**Output:**
- Analysis report saved to `.cache/ace-docs/analysis-{timestamp}.md`
- Report includes:
  - YAML frontmatter with metadata (generated date, time range, document list)
  - LLM-compacted change summary organized by impact level
  - Relevant changes with noise removed
  - Statistics (commits, files changed, relevant changes)

**Examples:**
```bash
# Analyze all documents needing updates
ace-docs analyze --needs-update

# Analyze specific documents
ace-docs analyze docs/architecture.md docs/tools.md

# Analyze with custom time range
ace-docs analyze --needs-update --since "2 weeks ago"

# Analyze by document type
ace-docs analyze --type guide --freshness stale

# Exclude renames and moves for cleaner diffs
ace-docs analyze --all --exclude-renames --exclude-moves
```

**How It Works:**
1. Determines time range from oldest `last-updated` date in selected documents
2. Generates git diff for the entire codebase from that time range
3. Sends diff to LLM (via ace-llm-query) for noise removal and compaction
4. Returns organized markdown report with relevant changes only
5. Saves to cache for workflow integration

**Error Messages:**
- "No documents match the specified criteria" - No documents found with given filters
- "No changes detected in the specified period" - No git changes in time range
- LLM errors will show clear messages with suggestions

### diff Command

Analyze changes affecting documents using git history.

```bash
ace-docs diff [FILE] [OPTIONS]
```

**Arguments:**
- `FILE` - Specific file to analyze (optional)

**Options:**
- `--all` - Analyze all managed documents
- `--needs-update` - Analyze documents needing update (default)
- `--since DATE` - Date or commit to diff from
- `--exclude-renames` - Exclude renamed files from diff
- `--exclude-moves` - Exclude moved files from diff

**Output:**
- Saves analysis to `.cache/ace-docs/diff-{timestamp}.md`
- Shows summary of documents with changes
- Full git diff with `-w` flag (ignores whitespace)

**Examples:**
```bash
# Analyze documents needing update
ace-docs diff

# Analyze all documents since last week
ace-docs diff --all --since "7 days ago"

# Analyze specific document
ace-docs diff docs/api.md

# Analyze excluding file renames
ace-docs diff --all --exclude-renames
```

### update Command

Update document frontmatter fields.

```bash
ace-docs update FILE [OPTIONS]
```

**Arguments:**
- `FILE` - Document file to update

**Options:**
- `--set key:value` - Fields to update (can be used multiple times)
- `--preset PRESET` - Update all documents matching preset

**Supported Fields:**
- `last-updated` - Update date (use "today" for current date)
- `last-checked` - Last review date
- `version` - Document version
- Any custom fields defined in frontmatter

**Examples:**
```bash
# Update last-updated date
ace-docs update docs/guide.md --set last-updated:today

# Update multiple fields
ace-docs update docs/api.md --set last-updated:today --set version:2.0

# Bulk update by preset
ace-docs update --preset standard --set last-checked:today
```

### validate Command

Validate documents against configured rules.

```bash
ace-docs validate [FILE|PATTERN] [OPTIONS]
```

**Arguments:**
- `FILE|PATTERN` - Specific file or glob pattern (optional)

**Options:**
- `--syntax` - Run syntax validation using linters (delegates to ace-lint when available)
- `--semantic` - **NEW in v0.3.0** - Run semantic validation using LLM
- `--all` - Run all validation types (default)

**Validation Checks:**

**Syntax Validation (--syntax):**
- Delegates to ace-lint for markdown, YAML, and frontmatter validation
- Checks required frontmatter fields
- Validates maximum line count limits
- Checks required document sections
- Custom validation rules from configuration

**Semantic Validation (--semantic):**
- LLM-powered semantic analysis
- Checks for content accuracy and relevance
- Validates document purpose alignment

**Output:**
- ✓ Valid / warnings count for each document
- Specific rule violations
- Warnings for non-critical issues
- ace-lint output when available

**Examples:**
```bash
# Validate all documents (syntax + semantic)
ace-docs validate

# Validate specific document
ace-docs validate docs/guide.md

# Validate all guides
ace-docs validate "**/*.g.md"

# Run only syntax validation
ace-docs validate --syntax

# Run only semantic validation with LLM
ace-docs validate --semantic

# Validate with both
ace-docs validate docs/guide.md --all
```

## Configuration

ace-docs can be configured via `.ace/docs/config.yml`:

```yaml
# Cache directory for analysis and diff reports (v0.3.0+)
cache_dir: .cache/ace-docs

# LLM integration settings for analyze command (v0.3.0+)
llm_temperature: 0.3        # Lower for deterministic compaction (default: 0.3)
# llm_model: gflash         # Override default (uses ace-llm-query defaults)

# Warning threshold for large diffs (v0.3.0+)
max_diff_lines_warning: 100000  # Warn when diff exceeds this size

# Validation settings (v0.3.0+)
validation_enabled: true
ace_lint_path: ace-lint     # Path to ace-lint executable

# Document freshness thresholds in days
default_freshness_days:
  current: 14     # Documents updated within 2 weeks
  stale: 30       # Documents updated within 1 month
  outdated: 60    # Documents older than 2 months

# Document type definitions
document_types:
  context:
    paths:
      - "docs/*.md"
      - "!docs/archive/**"    # Exclude archived
    defaults:
      update_frequency: weekly
      max_lines: 150
      required_sections:
        - overview
        - scope

  guide:
    paths:
      - "**/*.g.md"
      - "handbook/guides/**/*.md"
    defaults:
      update_frequency: monthly
      max_lines: 500

  workflow:
    paths:
      - "**/*.wf.md"
    defaults:
      update_frequency: on-change

# Global validation rules (merged with type-specific, type wins)
global_rules:
  max_lines: 1000
  required_frontmatter:
    - doc-type
    - purpose

# Ignored paths
ignore:
  - "**/node_modules/**"
  - "**/vendor/**"
  - "**/.git/**"
  - "**/tmp/**"
```

See `.ace.example/docs/config.yml` in the ace-docs gem for the complete configuration reference.

## Frontmatter Schema

Required frontmatter for ace-docs managed documents:

```yaml
---
doc-type: guide                    # Required: document type
purpose: Brief description          # Required: document purpose

# Optional update configuration
update:
  frequency: weekly                 # daily, weekly, monthly, on-change
  last-updated: 2024-10-01         # ISO date format
  last-checked: 2024-10-10         # Last review date
  focus:                           # LLM relevance hints
    - implementation
    - architecture

# Optional context requirements
context:
  preset: standard                 # ace-context preset name
  includes:                        # Additional files to include
    - docs/*.md
  excludes:                        # Files to exclude
    - test/**/*

# Optional validation rules
rules:
  max-lines: 500                   # Maximum line count
  sections:                        # Required sections
    - Overview
    - Usage
    - Examples
  no-duplicate-from:              # Avoid duplication from these files
    - README.md
    - CONTRIBUTING.md
  auto-generate:                  # Sections to auto-generate
    - tools-index
    - decision-log

# Optional metadata
metadata:
  version: 1.0.0
  author: Team Name
  tags:
    - documentation
    - guide
---
```

## Workflow Integration

### With Claude Commands

Use the `/update-docs` command to run the full workflow:

```bash
/update-docs                    # Update documents needing updates
/update-docs --type guide       # Update all guides
/update-docs --all             # Update all documents
```

### With Git Hooks

Add to pre-commit hook for validation:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Validate changed markdown files
changed_files=$(git diff --cached --name-only -- '*.md')
if [ -n "$changed_files" ]; then
  ace-docs validate $changed_files || exit 1
fi
```

### With CI/CD

GitHub Actions example:

```yaml
name: Documentation Check
on: [push, pull_request]

jobs:
  validate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: |
          ace-docs validate
          ace-docs status --needs-update
```

## Examples

### Complete Workflow Example

**Using the NEW analyze command (v0.3.0+) for efficient batch updates:**

```bash
# 1. Check current status
ace-docs status --needs-update

# 2. Batch analyze with LLM compaction
ace-docs analyze --needs-update

# 3. Review the analysis report
cat .cache/ace-docs/analysis-*.md

# 4. Update document content based on analysis
$EDITOR docs/guide.md

# 5. Update frontmatter
ace-docs update docs/guide.md --set last-updated:today

# 6. Validate the updated document
ace-docs validate docs/guide.md --all

# 7. Commit changes
git add docs/guide.md
git commit -m "docs: Update guide with latest changes"
```

**Traditional workflow (using diff instead of analyze):**

```bash
# 1. Check current status
ace-docs status

# 2. Analyze changes for stale documents
ace-docs diff --needs-update

# 3. Review the diff report
cat .cache/ace-docs/diff-*.md

# 4. Update document content manually
$EDITOR docs/guide.md

# 5. Update frontmatter
ace-docs update docs/guide.md --set last-updated:today

# 6. Validate the document
ace-docs validate docs/guide.md

# 7. Commit changes
git add docs/guide.md
git commit -m "docs: Update guide with latest changes"
```

### Bulk Operations Example

```bash
# Find all outdated documents
ace-docs status --freshness outdated

# Generate analysis for all guides
ace-docs diff --type guide --since "30 days ago"

# Bulk update last-checked date
for file in $(ace-docs discover | grep guide | awk '{print $1}'); do
  ace-docs update $file --set last-checked:today
done

# Validate all updated documents
ace-docs validate
```

### Integration with ace-context

```bash
# Load context for documentation work
ace-context load --preset docs

# Check documentation status in context
ace-docs status | ace-context add --tag doc-status

# Analyze changes with context
ace-docs diff --all
ace-llm-query --prompt "Summarize documentation changes" < .cache/ace-docs/diff-*.md
```

## Troubleshooting

### Common Issues

**No documents found:**
- Ensure markdown files have valid ace-docs frontmatter
- Check that `doc-type` and `purpose` fields are present
- Verify file paths match configuration patterns

**Analyze command returns "No changes detected":**
- Check the time range being used (based on `last-updated` dates)
- Try using `--since` to specify a longer time range
- Verify git repository has commits in the specified period
- Check if the specific documents have changes in that time range

**LLM errors during analyze:**
- Verify ace-llm-query is installed and accessible
- Check LLM API credentials are configured
- Try again if rate limited (error message will indicate this)
- For very large diffs (>100K lines), use `--exclude-renames` or `--exclude-moves`

**Diff shows no changes:**
- Check the `--since` date parameter
- Verify git repository is initialized
- Ensure changes are committed to git

**Validation failures:**
- Review validation rules in frontmatter
- Check global rules in `.ace/docs/config.yml`
- Use `--syntax` or `--semantic` to isolate issues
- If ace-lint is not available, install it or validation will use basic checks only

**ace-lint integration issues:**
- Verify ace-lint gem is installed: `gem list ace-lint`
- Check ace_lint_path in configuration points to correct executable
- ace-lint will gracefully degrade if external linters (markdownlint, yamllint) are not available

**Frontmatter parsing errors:**
- Validate YAML syntax
- Ensure proper `---` delimiters
- Check for invalid date formats

### Debug Mode

Enable debug output with environment variable:

```bash
DEBUG=1 ace-docs status
TRACE=1 ace-docs diff  # Even more verbose
```

## Best Practices

1. **Use Batch Analysis**: Leverage `ace-docs analyze` for efficient LLM-powered change summaries (v0.3.0+)
2. **Regular Updates**: Run `ace-docs status` weekly to identify stale documentation
3. **Automated Validation**: Include `ace-docs validate` in CI/CD pipelines
4. **Consistent Frontmatter**: Use templates for new documents
5. **Change Analysis**: Review analysis reports before major releases
6. **Bulk Operations**: Use `--preset` for consistent updates across document sets
7. **Version Tracking**: Update version fields for significant changes
8. **Context Integration**: Leverage ace-context for comprehensive project awareness

## See Also

- [README.md](../README.md) - Overview and quick start
- [update-docs.wf.md](../handbook/workflow-instructions/update-docs.wf.md) - Workflow orchestration
- [ace-context](../../ace-context/README.md) - Context management
- [ace-llm-query](../../ace-llm/README.md) - LLM integration for analysis