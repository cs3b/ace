---
doc-type: user
title: ace-docs Usage Guide
purpose: Documentation for ace-docs/docs/usage.md
ace-docs:
  last-updated: 2026-03-08
  last-checked: 2026-03-21
---

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
- `--package PACKAGE` - Scope to one or more package roots (repeatable)
- `--glob PATTERN` - Scope by project-root glob (repeatable)

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

# Scope to one package
ace-docs status --package ace-assign

# Scope by glob (bare path is normalized)
ace-docs status --glob ace-assign
ace-docs status --glob "ace-assign/docs/**/*.md"
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

**NEW in v0.4.3** - LLM-powered documentation analysis with multi-subject diff support for targeted change analysis.

```bash
ace-docs analyze [FILES...] [OPTIONS]
```

**Arguments:**
- `FILES...` - Specific files to analyze (optional)

**Options:**
- `--all` - Analyze all managed documents
- `--needs-update` - Analyze only documents needing updates (default if no files specified)
- `--type TYPE` - Filter by document type (guide, context, workflow, etc.)
- `--freshness STATUS` - Filter by freshness (current, stale, outdated)
- `--since DATE` - Override automatic time range (e.g., '1 week ago', '2025-01-01')
- `--exclude-renames` - Exclude renamed files from diff analysis
- `--exclude-moves` - Exclude moved files from diff analysis

**Multi-Subject Support:**
Documents can define multiple subjects to generate separate diffs for different categories:
- Each subject generates its own diff file (e.g., code.diff, config.diff, docs.diff)
- Allows focused analysis of specific change types
- Reduces noise by separating concerns

**Output:**
- Session directory: `.ace-local/docs/analyze-{timestamp}/`
- Files generated:
  - `analysis.md` - LLM-powered analysis report with recommendations
  - Subject diff files (when multi-subject configured):
    - `code.diff` - Code changes only
    - `config.diff` - Configuration changes
    - `docs.diff` - Documentation changes
  - Or single `repo-diff.diff` for single-subject documents
  - `context.md` - Combined context with embedded diffs
  - `prompt-system.md` - System prompt used for analysis
  - `prompt-user.md` - User prompt with full context
  - `metadata.yml` - Session metadata

**Examples:**
```bash
# Analyze specific document with multi-subject support
ace-docs analyze docs/architecture.md

# Analyze all documents needing updates
ace-docs analyze --needs-update

# Analyze with custom time range
ace-docs analyze docs/tools.md --since "2 weeks ago"

# Analyze by document type
ace-docs analyze --type guide --freshness stale

# Analyze all documents, excluding renames
ace-docs analyze --all --exclude-renames --exclude-moves
```

**How It Works:**
1. Determines time range from document's `last-updated` date or --since option
2. For multi-subject documents:
   - Generates separate git diff for each subject's filters
   - Creates individual diff files (code.diff, config.diff, etc.)
3. For single-subject documents:
   - Generates one diff with all configured filters
   - Creates repo-diff.diff file
4. Builds context with ace-bundle integration, embedding all diffs
5. Sends to LLM for intelligent analysis and recommendations
6. Saves comprehensive session data for review and iteration

**Error Messages:**
- "No documents match the specified criteria" - No documents found with given filters
- "No changes detected in the specified period" - No git changes in time range
- "Request timeout" - LLM service timeout, try again or use different model
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
- Saves analysis to `.ace-local/docs/diff-{timestamp}.md`
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
- `--package PACKAGE` - Scope updates to package(s) (repeatable)
- `--glob PATTERN` - Scope updates by glob(s) (repeatable)

**Supported Fields:**
- `last-updated` - Update date/datetime (see Timestamp Formats below)
- `last-checked` - Last review date/datetime (see Timestamp Formats below)
- `version` - Document version
- Any custom fields defined in frontmatter

**Timestamp Formats:**
- **Date-only**: `YYYY-MM-DD` (e.g., `2025-11-01`)
- **Date+time**: `YYYY-MM-DD HH:MM` (e.g., `2025-11-01 14:30`)
- **Special values**:
  - `today` - Current date without time (e.g., `2025-11-01`)
  - `now` - Current date and time (e.g., `2025-11-01 14:30`)

**Examples:**
```bash
# Update last-updated with current date only
ace-docs update docs/guide.md --set last-updated:today

# Update last-updated with current date and time
ace-docs update docs/guide.md --set last-updated:now

# Set explicit date+time timestamp
ace-docs update docs/changelog.md --set last-updated:"2025-11-01 14:30"

# Update multiple fields
ace-docs update docs/api.md --set last-updated:now --set version:2.0

# Bulk update by preset with date+time
ace-docs update --preset standard --set last-checked:now

# Bulk update scoped to one package
ace-docs update --package ace-assign --set last-checked:today

# Bulk update scoped by glob
ace-docs update --glob "ace-assign/docs/**/*.md" --set last-updated:today
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
- `--package PACKAGE` - Scope validation to package(s) (repeatable)
- `--glob PATTERN` - Scope validation by glob(s) (repeatable)

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

# Validate only docs in one package
ace-docs validate --package ace-assign --all

# Validate only a scoped glob
ace-docs validate --glob "ace-assign/docs/**/*.md" --syntax
```

## Configuration

ace-docs uses ace-core's configuration cascade system. Configuration is searched from current directory up to home directory, with nearest configuration winning.

### Global Configuration

Create `.ace/docs/config.yml` in your project:

```yaml
# Cache directory for analysis and diff reports
cache_dir: .ace-local/docs

# LLM integration settings for analyze command
llm_temperature: 0.3        # Lower for deterministic analysis (default: 0.3)
# llm_model: gflash         # Override default (uses ace-llm defaults)

# Warning threshold for large diffs
max_diff_lines_warning: 100000  # Warn when diff exceeds this size

# Validation settings
validation_enabled: true
ace_lint_path: ace-lint     # Path to ace-lint executable

# Document freshness thresholds in days
default_freshness_days:
  current: 14     # Documents updated within 2 weeks
  stale: 30       # Documents updated within 1 month
  outdated: 60    # Documents older than 2 months

# Document type definitions
document_types:
  bundle:
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

### Multi-Subject Configuration in Documents

Documents can configure multiple subjects for targeted diff analysis. Add to your document's frontmatter:

```yaml
---
ace-docs:
  subject:
    - code:
        diff:
          paths:
            - "lib/**/*.rb"
            - "test/**/*.rb"
    - config:
        diff:
          paths:
            - "**/*.yml"
            - "**/*.yaml"
            - ".ace/**/*"
    - docs:
        diff:
          paths:
            - "**/*.md"
            - "!**/node_modules/**"
---
```

This generates separate diff files:
- `code.diff` - Only Ruby source and test files
- `config.diff` - YAML configuration files
- `docs.diff` - Markdown documentation

### Single Subject Configuration (Backward Compatible)

Traditional single-subject configuration still works:

```yaml
---
ace-docs:
  subject:
    diff:
      paths:
        - "**/*.rb"
        - "**/*.md"
---
```

This generates a single `repo-diff.diff` file with all changes.

See `.ace-defaults/docs/config.yml` in the ace-docs gem for the complete configuration reference.

## Frontmatter Schema

### Required Fields

All ace-docs managed documents must have:

```yaml
---
doc-type: guide                    # Required: document type
purpose: Brief description          # Required: document purpose
---
```

### ace-docs Namespace (Recommended)

The `ace-docs` namespace provides enhanced configuration with backward compatibility:

```yaml
---
ace-docs:
  # Update tracking
  last-updated: '2026-03-08'
  last-checked: '2025-10-18'       # Last review date
  frequency: weekly                # daily, weekly, monthly, on-change

  # Multi-subject configuration (NEW in v0.4.3)
  subject:
    - code:                        # Named subject for code changes
        diff:
          paths:
            - "lib/**/*.rb"
            - "test/**/*.rb"
    - config:                      # Configuration changes
        diff:
          paths:
            - "**/*.yml"
            - ".ace/**/*"
    - docs:                        # Documentation changes
        diff:
          paths:
            - "**/*.md"

  # Context configuration for ace-bundle integration
  bundle:
    preset: project                # ace-bundle preset to use
    files:                        # Additional files to include
      - CHANGELOG.md
      - docs/architecture.md
    keywords:                     # LLM relevance keywords
      - architecture
      - implementation

  # Validation rules
  rules:
    max-lines: 500                # Maximum line count
    sections:                     # Required sections
      - Overview
      - Usage
    no-duplicate-from:           # Avoid duplication
      - README.md

doc-type: guide
purpose: Comprehensive usage guide
---
```

### Legacy Format (Backward Compatible)

The root-level format is still supported but deprecated:

```yaml
---
doc-type: guide                    # Required
purpose: Brief description          # Required

# Legacy update configuration (deprecated, use ace-docs namespace)
update:
  frequency: weekly
  last-updated: 2024-10-01
  last-checked: 2024-10-10
  focus:                           # Legacy: use ace-docs.context.keywords
    - implementation
    - architecture

# Legacy context (deprecated, use ace-docs.context)
bundle:
  preset: standard
  includes:
    - docs/*.md
  excludes:
    - test/**/*

# Legacy rules (deprecated, use ace-docs.rules)
rules:
  max-lines: 500
  sections:
    - Overview
    - Usage

# Optional metadata (not deprecated)
metadata:
  version: 1.0.0
  author: Team Name
  tags:
    - documentation
    - guide
---
```

### Migration Path

To migrate from legacy to ace-docs namespace:

1. Move `update.*` fields to `ace-docs.*`
2. Move `context.*` to `ace-docs.context.*`
3. Move `rules.*` to `ace-docs.rules.*`
4. Convert `update.focus` to `ace-docs.context.keywords`
5. Add multi-subject configuration if needed

The system automatically handles both formats with ace-docs namespace taking precedence.

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

**Multi-Subject Analysis Workflow (NEW in v0.4.3):**

```bash
# 1. Configure document with multi-subject in frontmatter
cat docs/architecture.md
# ---
# ace-docs:
#   subject:
#     - code:
#         diff:
#           paths: ["lib/**/*.rb"]
#     - docs:
#         diff:
#           paths: ["**/*.md"]
# ---

# 2. Analyze with multi-subject support
ace-docs analyze docs/architecture.md

# 3. Review generated diff files
ls .ace-local/docs/analyze-*/
# code.diff    - Ruby code changes only
# docs.diff    - Documentation changes only
# analysis.md  - LLM analysis with recommendations

# 4. Review the targeted analysis
cat .ace-local/docs/analyze-*/analysis.md

# 5. Update document based on specific subject changes
$EDITOR docs/architecture.md

# 6. Update frontmatter
ace-docs update docs/architecture.md --set last-updated:today

# 7. Validate and commit
ace-docs validate docs/architecture.md --all
git add docs/architecture.md
git commit -m "docs: Update architecture with code and doc changes"
```

**Standard Workflow (Single Subject):**

```bash
# 1. Check current status
ace-docs status --needs-update

# 2. Analyze with LLM-powered recommendations
ace-docs analyze --needs-update

# 3. Review the analysis report
cat .ace-local/docs/analyze-*/analysis.md

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

### Integration with ace-bundle

```bash
# Load context for documentation work
ace-bundle --preset docs

# Check documentation status in context
ace-docs status | ace-bundle add --tag doc-status

# Analyze changes with context
ace-docs diff --all
ace-llm --prompt "Summarize documentation changes" < .ace-local/docs/diff-*.md
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
- Verify ace-llm is installed and accessible
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

**Multi-subject configuration issues:**
- Verify subject is an array with named hash entries (e.g., `- code:`)
- Each subject name must be unique within the document
- Check filter patterns match actual file paths using `git ls-files`
- Test filters individually: `git diff --name-only -- "pattern"`
- If no diff generated for a subject, verify files exist matching the filters

**Multi-subject diff not generating:**
- Ensure using `ace-docs.subject` array format, not single object
- Check that filters use git-compatible glob patterns
- Verify time range includes changes for filtered files
- Use `--since` to expand time range if needed
- Check session directory for individual diff files

### Debug Mode

Enable debug output with environment variable:

```bash
DEBUG=1 ace-docs status
DEBUG=1 ace-docs analyze docs/file.md  # Shows subject processing
TRACE=1 ace-docs diff  # Even more verbose
```

To debug multi-subject filters:
```bash
# Test if files match your filter patterns
git ls-files | grep -E "lib/.*\.rb"

# Check what changes exist for a filter
git diff --name-only HEAD~10 -- "lib/**/*.rb"

# Verify multi-subject configuration is parsed
DEBUG=1 ace-docs analyze docs/file.md 2>&1 | grep -i subject
```

## Best Practices

1. **Use Multi-Subject Analysis**: Configure multiple subjects for targeted diff analysis (v0.4.3+)
2. **Leverage LLM Analysis**: Use `ace-docs analyze` for intelligent recommendations
3. **Regular Updates**: Run `ace-docs status` weekly to identify stale documentation
4. **Automated Validation**: Include `ace-docs validate --all` in CI/CD pipelines
5. **Use ace-docs Namespace**: Migrate to `ace-docs.*` frontmatter for enhanced features
6. **Change Analysis**: Review analysis reports before major releases
7. **Bulk Operations**: Use `--preset` for consistent updates across document sets
8. **Version Tracking**: Update version fields for significant changes
9. **Context Integration**: Leverage ace-bundle for comprehensive project awareness
10. **ADR Management**: Use dedicated workflows for Architecture Decision Records:
    - Create ADRs: See `ace-docs/handbook/workflow-instructions/create-adr.wf.md`
    - Maintain ADRs: See `ace-docs/handbook/workflow-instructions/maintain-adrs.wf.md`

## See Also

- [README.md](../README.md) - Overview and quick start
- [update-docs.wf.md](../handbook/workflow-instructions/update-docs.wf.md) - Documentation update workflow
- [create-adr.wf.md](../handbook/workflow-instructions/create-adr.wf.md) - ADR creation workflow
- [maintain-adrs.wf.md](../handbook/workflow-instructions/maintain-adrs.wf.md) - ADR maintenance workflow
- [ace-change-analyzer.system.md](../handbook/prompts/ace-change-analyzer.system.md) - Dual analysis prompt
- [ace-bundle](../../ace-bundle/README.md) - Context management
- [ace-llm](../../ace-llm/README.md) - LLM integration for analysis
- [ace-core](../../ace-core/README.md) - Configuration cascade system
