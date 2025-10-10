# ace-docs Usage Guide

## Overview

ace-docs is a universal documentation management tool that enables any markdown document to self-describe its purpose, update requirements, and validation rules through frontmatter. It provides intelligent change detection, automatic content generation, and rule-based validation.

## Key Features

- **Self-describing documents** via frontmatter configuration
- **Automatic discovery** of all managed documents
- **Intelligent change analysis** using LLM summarization
- **Metadata tracking** with freshness indicators
- **Rule validation** for content consistency
- **Auto-generation** of dynamic sections

## Command Structure

### Status Check (Default)
Show the status of all managed documents:
```bash
ace-docs
# or explicitly:
ace-docs status
```

### Filtered Status Views
```bash
ace-docs status --type context        # Show only context documents
ace-docs status --needs-update        # Show documents needing updates
ace-docs status --type guide --needs-update  # Combine filters
```

### Change Analysis
Generate intelligent diff analysis for documents:
```bash
ace-docs diff                          # All documents needing updates
ace-docs diff docs/architecture.md    # Specific document
ace-docs diff --preset project        # Documents in preset
ace-docs diff --since "7 days ago"    # Custom timeframe
```

### Update Metadata
Update frontmatter fields:
```bash
ace-docs update docs/tools.md --set last-updated=today
ace-docs update --preset project --set last-checked=today
ace-docs update docs/guide.md --set version=2.0.0
```

### Sync Content
Synchronize auto-generated sections:
```bash
ace-docs sync docs/tools.md           # Sync specific document
ace-docs sync --auto                  # Sync all auto-generate sections
ace-docs sync docs/decisions.md --with-llm  # Use LLM for enhancement
```

### Validate Documents
Check documents against their declared rules:
```bash
ace-docs validate                     # Validate all documents
ace-docs validate docs/*.md           # Validate pattern
ace-docs validate --type guide        # Validate by type
```

## Usage Scenarios

### Scenario 1: Daily Documentation Check
**Goal**: Check which documents need updating after recent development

```bash
# Check documentation status
$ ace-docs

Managed Documents (12 found)

Core Context (docs/):
  ✓ what-do-we-build.md    context    2025-10-08 (2d ago)
  ⚠ architecture.md         context    2025-09-20 (20d ago) - needs update
  ✗ decisions.md           context    Missing frontmatter

Guides (dev-handbook/guides/):
  ✓ testing-patterns.md     guide      2025-10-09 (1d ago)
  ✓ ace-gems.md            guide      2025-10-07 (3d ago)

# Generate change analysis for stale documents
$ ace-docs diff --needs-update

Analyzing changes for 2 documents...
Analysis saved to: .cache/ace-docs/diff-20251010-142530.md

# Review the analysis and update documents manually or via workflow
```

### Scenario 2: Update After New Feature
**Goal**: Update documentation after adding a new ace-* gem

```bash
# Check what's changed since last architecture update
$ ace-docs diff docs/architecture.md

Analyzing changes since 2025-09-20...
Relevant changes found:
- New gem: ace-docs added
- Modified: ATOM architecture patterns
- New ADR: ADR-016-documentation-management
Analysis saved to: .cache/ace-docs/diff-20251010-143012.md

# Update the architecture document manually based on analysis

# Update metadata after changes
$ ace-docs update docs/architecture.md --set last-updated=today

# Validate the updated document
$ ace-docs validate docs/architecture.md
✓ Valid frontmatter schema
✓ Max lines: 145/150
✓ Required sections present
✓ No duplicate content detected
```

### Scenario 3: Auto-Generate Tool Documentation
**Goal**: Keep tools.md updated with latest commands

```bash
# Sync auto-generated sections
$ ace-docs sync docs/tools.md

Syncing auto-generated sections for docs/tools.md:
- Regenerating tools table from gemspecs...
  Found 15 ace-* gems with executables
- Updating command examples...
✓ Document synchronized

# Validate after sync
$ ace-docs validate docs/tools.md
✓ All validation rules pass
```

### Scenario 4: Bulk Metadata Update
**Goal**: Mark all project documents as checked

```bash
# Update all context documents
$ ace-docs update --preset project --set last-checked=today

Updated frontmatter for 5 documents:
- docs/what-do-we-build.md
- docs/architecture.md
- docs/blueprint.md
- docs/tools.md
- docs/decisions.md
```

### Scenario 5: Add Frontmatter to New Document
**Goal**: Make a document managed by ace-docs

```bash
# Create frontmatter for a new guide
$ cat > docs/new-guide.md << 'EOF'
---
doc-type: guide
purpose: |
  Explain how to use ace-docs for documentation management
update:
  frequency: weekly
  last-updated: 2025-10-10
  sources:
    - files: "ace-docs/**"
    - changelog: ace-docs
rules:
  max-lines: 200
  sections:
    - overview
    - examples
    - reference
---

# New Guide Content
...
EOF

# Validate the new document
$ ace-docs validate docs/new-guide.md
✓ Document successfully registered
```

### Scenario 6: Workflow Integration
**Goal**: Use ace-docs in documentation update workflow

```bash
# In a workflow or Claude command:

# 1. Check status
ace-docs status --needs-update

# 2. Generate comprehensive diff
ace-docs diff --needs-update

# 3. Read analysis
cat .cache/ace-docs/diff-*.md

# 4. Update documents based on analysis
# (Manual or automated updates)

# 5. Sync auto-generated content
ace-docs sync --auto

# 6. Update metadata
ace-docs update --needs-update --set last-updated=today

# 7. Final validation
ace-docs validate --preset project
```

## Frontmatter Configuration

Example frontmatter for a managed document:

```yaml
---
# Required
doc-type: context           # context|guide|template|workflow|reference|api
purpose: |
  Technical architecture documentation for the ACE project

# Update configuration
update:
  frequency: weekly         # daily|weekly|monthly|on-change
  last-updated: 2025-10-10
  last-checked: 2025-10-10
  sources:                  # What to monitor for changes
    - git-commits: "feat:"  # Monitor commits with prefix
    - changelog: ALL        # Monitor changelogs
    - files: "ace-*/lib/**" # Monitor file patterns
    - adrs: active          # Monitor ADRs

# Context requirements
context:
  preset: project           # ace-context preset
  includes:                 # Additional files
    - "docs/decisions/*.md"

# Content rules
rules:
  max-lines: 150           # Maximum document length
  sections:                # Required sections
    - overview
    - components
    - decisions
  no-duplicate-from:       # Avoid duplication
    - "docs/what-do-we-build.md"
  auto-generate:           # Auto-generated sections
    - tools-table: from-gemspecs
---
```

## Integration with Other Tools

- **ace-context**: Loads project context for change analysis
- **ace-llm-query**: Provides intelligent summarization of changes
- **Workflows**: Deterministic operations for agent orchestration
- **Git**: Analyzes commit history and file changes

## Output Files

- **Status**: Display in terminal with color indicators
- **Diff analysis**: Saved to `.cache/ace-docs/diff-{timestamp}.md`
- **Validation**: Terminal output with specific violations
- **Updated documents**: Modified in-place with new frontmatter