# ace-docs Batch Analysis - Usage Guide

## Document Type: How-To Guide + Reference

## Overview

The ace-docs batch analysis feature provides efficient documentation maintenance through single-command analysis of multiple documents. It generates LLM-compacted change reports that remove noise while preserving details, enabling smooth document-by-document workflow iteration.

**Key Features:**
- Single command processes multiple documents (file list or filter criteria)
- Automatic time range detection from document staleness
- LLM-powered diff compaction (removes noise, keeps relevant changes)
- Markdown report organized by impact level (HIGH/MEDIUM/LOW)
- Workflow-optimized output for iterative document updates
- Integration with standalone ace-lint for validation

## Quick Start (5 minutes)

Get started with batch analysis for stale documents:

```bash
# Analyze all documents needing updates
ace-docs analyze --needs-update

# Expected output:
Analyzing changes for 5 documents...
Analyzing changes since: 2 weeks ago
Compacting changes with LLM...

✓ Analysis complete
  Documents: 5
  Period: 2 weeks ago to now
  Report: .cache/ace-docs/analysis-20251013-143000.md

Use this report to update your documents.
```

**Success criteria:** Markdown report generated in `.cache/ace-docs/` with organized change summary

## Command Interface

### Basic Usage

```bash
# Analyze documents needing updates (default)
ace-docs analyze --needs-update

# Analyze by document type
ace-docs analyze --type guide

# Analyze by freshness status
ace-docs analyze --freshness stale

# Analyze specific files
ace-docs analyze docs/architecture.md docs/tools.md
```

### Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `--needs-update` | Analyze documents needing updates based on frequency | `ace-docs analyze --needs-update` |
| `--type TYPE` | Filter by document type (guide, context, api, etc.) | `ace-docs analyze --type guide` |
| `--freshness STATUS` | Filter by freshness (current/stale/outdated) | `ace-docs analyze --freshness stale` |
| `--since DATE` | Override automatic time range detection | `ace-docs analyze --since "1 month ago"` |
| `--exclude-renames` | Exclude renamed files from diff | `ace-docs analyze --exclude-renames` |
| `--exclude-moves` | Exclude moved files from diff | `ace-docs analyze --exclude-moves` |
| `--output FORMAT` | Output format: compact (default) or detailed | `ace-docs analyze --output detailed` |

## Common Scenarios

### Scenario 1: Weekly Documentation Maintenance

**Goal**: Update all stale documentation in weekly maintenance cycle

**Commands**:
```bash
# Step 1: Check what needs updating
ace-docs status --needs-update

# Expected output:
Document Status:
  docs/architecture.md  guide      2 weeks ago   stale      weekly
  docs/tools.md         reference  2 weeks ago   stale      weekly
  docs/what-do-we-build.md context 2 weeks ago   stale      weekly

3 documents need updates

# Step 2: Generate batch analysis
ace-docs analyze --needs-update

# Expected output:
Analyzing changes for 3 documents...
Analyzing changes since: 2 weeks ago (oldest: docs/architecture.md)
Compacting changes with LLM...

✓ Analysis complete
  Documents: 3
  Period: 2025-09-29 to 2025-10-13
  Report: .cache/ace-docs/analysis-20251013-143000.md
```

**Next Steps**:
1. Read the analysis report
2. Update each document based on relevant changes
3. Update metadata: `ace-docs update docs/*.md --set last-updated=today`
4. Validate: `ace-lint docs/*.md --fix`

### Scenario 2: Targeted Guide Updates

**Goal**: Update all guide documents that are outdated

**Commands**:
```bash
# Generate analysis for outdated guides
ace-docs analyze --type guide --freshness outdated

# Expected output:
Analyzing changes for 2 documents...
Analyzing changes since: 1 month ago
Compacting changes with LLM...

✓ Analysis complete
  Documents: 2
  Period: 2025-09-13 to 2025-10-13
  Report: .cache/ace-docs/analysis-20251013-144500.md
```

**Next Steps**: Follow workflow to update guides based on analysis report

### Scenario 3: Specific Document Analysis

**Goal**: Analyze changes for specific documents regardless of staleness

**Commands**:
```bash
# Analyze two specific documents
ace-docs analyze docs/architecture.md docs/decisions.md

# Expected output:
Analyzing changes for 2 documents...
Analyzing changes since: 2 weeks ago
Compacting changes with LLM...

✓ Analysis complete
  Documents: 2
  Period: 2025-09-29 to 2025-10-13
  Report: .cache/ace-docs/analysis-20251013-145000.md
```

### Scenario 4: Custom Time Range

**Goal**: Analyze changes from specific date regardless of document staleness

**Commands**:
```bash
# Override automatic time detection
ace-docs analyze --needs-update --since "1 month ago"

# Expected output:
Analyzing changes for 5 documents...
Analyzing changes since: 1 month ago (override)
Compacting changes with LLM...

✓ Analysis complete
  Documents: 5
  Period: 2025-09-13 to 2025-10-13
  Report: .cache/ace-docs/analysis-20251013-150000.md
```

## Analysis Report Format

The generated markdown report has this structure:

```markdown
---
generated: 2025-10-13T14:30:00Z
since: 2 weeks ago
documents: 5
document_list:
  - docs/architecture.md
  - docs/tools.md
  - docs/what-do-we-build.md
  - docs/blueprint.md
  - docs/decisions.md
---

# Codebase Changes Analysis
Generated: 2025-10-13
Period: Last 2 weeks (2025-09-29 to 2025-10-13)

## Summary
3 high-priority changes affecting architecture documentation

## Significant Changes

### ace-docs Package (NEW) - HIGH Impact
**Impact: HIGH - New system component**

Created new documentation management gem with:
- Document discovery via frontmatter
- Change detection using git
- Validation rules engine
- CLI: status, diff, update, validate commands

Files:
- ace-docs/lib/ace/docs/**/*.rb (15 files)
- ace-docs/exe/ace-docs (CLI entry)

Relevant for:
- architecture.md: Add to component list
- tools.md: Add CLI documentation
- what-do-we-build.md: Add to capabilities

### ace-core Error Handling (REFACTORED) - MEDIUM Impact
**Impact: MEDIUM - Architecture change**

Refactored error hierarchy:
- Introduced BaseError class
- Standardized error messages
- Added error code system

Files:
- ace-core/lib/ace/core/errors.rb
- ace-core/lib/ace/core/error_reporter.rb

Relevant for:
- architecture.md: Update error handling section

## Ignored Changes (45)
- Test files: 32 changes
- Documentation: 8 changes (ace-docs README, usage docs)
- Formatting: 3 changes (rubocop auto-fixes)
- Dependencies: 2 changes (Gemfile updates)

## Change Statistics
- Total commits: 15
- Files changed: 87
- Additions: 1,234 lines
- Deletions: 456 lines
- Relevant changes: 3 major areas
```

## Workflow Integration

### Complete Update Workflow

```bash
# 1. Generate batch analysis
ace-docs analyze --needs-update
# → Saves: .cache/ace-docs/analysis-{timestamp}.md

# 2. Read report (in workflow/editor)
cat .cache/ace-docs/analysis-*.md | less

# 3. For each document in original list:
#    - Reference report for relevant changes
#    - Update document content (agent/human decision)
#    - Move to next document

# 4. Batch metadata update
ace-docs update docs/architecture.md docs/tools.md docs/what-do-we-build.md \
  --set last-updated=today

# Expected output:
Updated: docs/architecture.md
Updated: docs/tools.md
Updated: docs/what-do-we-build.md
Updated frontmatter for 3 document(s)

# 5. Validate all updated documents
ace-lint docs/architecture.md docs/tools.md docs/what-do-we-build.md --fix

# Expected output:
Linting: docs/architecture.md ✓
Linting: docs/tools.md ✓
Linting: docs/what-do-we-build.md ✓
Validated: 3 documents - All passed
```

## Complete Command Reference

### `ace-docs analyze [FILES...] [OPTIONS]`

**Purpose**: Generate LLM-compacted change analysis for batch document updates

**Syntax**:
```bash
ace-docs analyze [file1 file2 ...] [--needs-update] [--type TYPE] [--freshness STATUS] [--since DATE] [OPTIONS]
```

**Parameters**:
- `FILES...`: Optional explicit file list (space-separated paths)

**Filter Options** (mutually exclusive):
| Flag | Description | Example |
|------|-------------|---------|
| `--needs-update` | Documents needing updates by frequency | Default if no files |
| `--type TYPE` | Filter by document type | `--type guide` |
| `--freshness STATUS` | current/stale/outdated | `--freshness stale` |

**Analysis Options**:
| Flag | Description | Default |
|------|-------------|---------|
| `--since DATE` | Override time range | Auto-detect oldest |
| `--exclude-renames` | Skip renamed files | false |
| `--exclude-moves` | Skip moved files | false |
| `--output FORMAT` | compact/detailed | compact |

**Exit Codes**:
- `0`: Success - analysis generated
- `1`: Error - no documents match criteria
- `2`: Error - no changes detected
- `3`: Error - LLM unavailable
- `4`: Error - git repository issue

**Examples**:

```bash
# Example 1: Default - analyze documents needing updates
ace-docs analyze --needs-update
# Output:
Analyzing changes for 5 documents...
✓ Analysis complete
  Report: .cache/ace-docs/analysis-20251013-143000.md

# Example 2: Filter by type and freshness
ace-docs analyze --type guide --freshness stale
# Output:
Analyzing changes for 2 documents...
✓ Analysis complete
  Report: .cache/ace-docs/analysis-20251013-144000.md

# Example 3: Explicit file list
ace-docs analyze docs/architecture.md docs/tools.md
# Output:
Analyzing changes for 2 documents...
✓ Analysis complete
  Report: .cache/ace-docs/analysis-20251013-145000.md

# Example 4: Custom time range with detailed output
ace-docs analyze --needs-update --since "1 month ago" --output detailed
# Output:
Analyzing changes for 5 documents...
✓ Analysis complete (detailed report)
  Report: .cache/ace-docs/analysis-20251013-150000.md
```

### `ace-docs update FILE [OPTIONS]`

**Purpose**: Update document frontmatter metadata

**Syntax**:
```bash
ace-docs update FILE --set KEY=VALUE [--set KEY=VALUE ...]
```

**Examples**:
```bash
# Update single document
ace-docs update docs/tools.md --set last-updated=today
# Output: Updated: docs/tools.md

# Update multiple fields
ace-docs update docs/api.md --set last-updated=today --set version=2.0
# Output: Updated: docs/api.md
```

### `ace-docs validate [FILE] [OPTIONS]`

**Purpose**: Validate documents (delegates to ace-lint)

**Note**: Validation is now handled by the standalone `ace-lint` tool

**Syntax**:
```bash
ace-docs validate FILE       # Delegates to ace-lint
ace-lint FILE [OPTIONS]      # Direct ace-lint usage
```

**Examples**:
```bash
# Validate with ace-docs (delegates)
ace-docs validate docs/architecture.md

# Direct ace-lint usage (preferred)
ace-lint docs/architecture.md --fix
# Output:
Linting: docs/architecture.md
  ✓ Markdown syntax valid
  ✓ Frontmatter schema valid
  ⚠ Fixed 2 formatting issues
Validated: 1 document - Passed with fixes
```

## ace-lint Integration

### Standalone Validation Tool

ace-lint is a separate gem used by ace-docs and other ace-* packages:

```bash
# Lint specific files
ace-lint docs/*.md

# Auto-fix issues
ace-lint docs/*.md --fix

# Format documents
ace-lint docs/*.md --format

# Specify validation type
ace-lint docs/*.md --type markdown
ace-lint config.yml --type yaml
```

### Validation Types

| Type | Description | External Linter |
|------|-------------|-----------------|
| `markdown` | Markdown syntax and style | markdownlint (optional) |
| `yaml` | YAML syntax and schema | yamllint (optional) |
| `frontmatter` | Frontmatter schema validation | Built-in |

**Graceful Fallbacks**: If external linters (markdownlint, yamllint) are not installed, ace-lint provides basic validation without them.

## Configuration

### Project Configuration

Create `.ace/docs/config.yml`:

```yaml
document_types:
  guide:
    paths:
      - "dev-handbook/guides/**/*.md"
    defaults:
      update_frequency: monthly
      max_lines: 500

  context:
    paths:
      - "docs/*.md"
    defaults:
      update_frequency: weekly
      max_lines: 150

global_rules:
  max_lines: 1000
  required_frontmatter:
    - doc-type
    - purpose
```

### LLM Configuration

Configure via ace-llm-query (ace-docs uses it as subprocess):

```bash
# Set default model
export ACE_LLM_MODEL=gpt-4

# Or use configuration file
cat > ~/.ace/llm/config.yml <<EOF
default_model: claude-3.5-sonnet
temperature: 0.3
EOF
```

## Troubleshooting

### Problem: No documents match criteria

**Symptom**:
```
Error: No documents match criteria
  Filter: --needs-update
  Try: ace-docs status to see all documents
```

**Solution**:
```bash
# Check document status
ace-docs status

# Verify frontmatter exists
cat docs/architecture.md | head -20

# Check configuration
cat .ace/docs/config.yml
```

### Problem: LLM unavailable

**Symptom**:
```
Error: LLM analysis failed
  ace-llm-query not found or not configured
```

**Solution**:
```bash
# Verify ace-llm-query is installed
which ace-llm-query

# Test LLM connection
ace-llm-query --test

# Check configuration
cat ~/.ace/llm/config.yml
```

### Problem: No changes detected

**Symptom**:
```
No changes detected in the specified period.
```

**Solution**:
```bash
# Check git history
git log --since="2 weeks ago" --oneline

# Force time range
ace-docs analyze --needs-update --since "1 month ago"

# Verify documents have last-updated dates
ace-docs status --needs-update
```

### Problem: Very large diff

**Symptom**:
```
Warning: Diff size exceeds 100K lines
  LLM context limits may be exceeded
```

**Solution**:
```bash
# Exclude non-essential changes
ace-docs analyze --needs-update --exclude-renames --exclude-moves

# Reduce time range
ace-docs analyze --needs-update --since "1 week ago"

# Analyze documents separately
ace-docs analyze docs/architecture.md
ace-docs analyze docs/tools.md
```

## Best Practices

### 1. Regular Maintenance Schedule
- Run `ace-docs analyze --needs-update` weekly for documents with weekly frequency
- Run monthly for guides and reference docs
- Use stale/outdated freshness filters to prioritize urgent updates

### 2. Efficient Batch Processing
- Always use batch analysis for multiple documents (single LLM call)
- Review entire analysis report before starting updates
- Update all documents in sequence, then batch metadata update

### 3. Report Management
- Analysis reports are cached in `.cache/ace-docs/`
- Reports are timestamped for easy reference
- Old reports can be safely deleted (no workflow dependency)

### 4. Validation Workflow
- Install external linters for best results (markdownlint, yamllint)
- Use `ace-lint --fix` to automatically fix formatting issues
- Validate after content updates, before committing

### 5. Time Range Strategy
- Let ace-docs auto-detect time range from document staleness
- Override with `--since` only when needed (e.g., major refactors)
- Consider excluding renames/moves for cleaner analysis

## Benefits Over Previous Approach

### Before (Complex)
```bash
# Multiple commands
ace-docs status --needs-update
ace-docs diff --needs-update
# Manual analysis of raw diff
# Per-document metadata updates
ace-docs update file1.md --set last-updated=today
ace-docs update file2.md --set last-updated=today
```

### After (Simple)
```bash
# One command for analysis
ace-docs analyze --needs-update
# Read compact report
# Smooth iteration
# Batch metadata update
ace-docs update file1.md file2.md --set last-updated=today
```

**Improvements:**
- Single command replaces multiple operations
- LLM removes noise (no manual filtering)
- Batch processing more efficient
- Workflow-optimized report format
- Reusable validation (ace-lint)

## See Also

- `ace-docs status` - Check document freshness
- `ace-docs discover` - Find all managed documents
- `ace-lint` - Standalone validation and formatting
- Workflow: `ace-docs/handbook/workflow-instructions/update-docs.wf.md`
