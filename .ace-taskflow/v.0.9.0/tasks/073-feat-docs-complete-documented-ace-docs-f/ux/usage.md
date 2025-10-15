# Focus Path Filtering and Semantic Validation - Usage Guide

## Overview

This document describes two enhanced features for ace-docs:

1. **Focus Path Filtering**: Filter git diffs to show only changes in relevant files/directories
2. **Semantic Validation**: LLM-powered validation of documentation accuracy and consistency

These features complete documented functionality from task 071 that was built but never connected.

## Focus Path Filtering

### What It Does

When you specify `focus.paths` in a document's frontmatter, `ace-docs diff` will only show git changes in those specific files or directories. This dramatically reduces noise when tracking documentation updates.

### Frontmatter Structure

```yaml
---
doc-type: reference
purpose: Overview and quick start guide for ace-docs
update:
  last-updated: '2025-10-14'
  focus:
    keywords:                    # LLM relevance hints (for future use)
      - implementation
      - architecture
    paths:                       # Git diff path filters (NEW feature)
      - "ace-docs/"              # Include entire directory
      - "CHANGELOG.md"           # Include specific file
      - "dev-handbook/guides/"   # Include another directory
---
```

**Note:** The `focus.keywords` field documents keywords for future LLM analysis but isn't currently used. Only `focus.paths` is functional.

### Usage Scenarios

#### Scenario 1: Track gem-specific changes for README

**Goal**: ace-docs/README.md should only track changes in ace-docs gem and CHANGELOG

**Setup**:
```yaml
---
doc-type: reference
purpose: Overview and quick start guide for ace-docs
update:
  last-updated: '2025-10-14'
  focus:
    paths:
      - "ace-docs/"
      - "CHANGELOG.md"
---
```

**Command**:
```bash
ace-docs diff ace-docs/README.md
```

**Result**: Shows only changes in `ace-docs/` directory and `CHANGELOG.md`, ignoring changes in other gems, test files, etc.

#### Scenario 2: Architecture document tracking multiple components

**Goal**: docs/architecture.md tracks changes across several key directories

**Setup**:
```yaml
---
doc-type: architecture
purpose: System architecture and design decisions
update:
  focus:
    paths:
      - "ace-core/"
      - "ace-docs/"
      - "ace-taskflow/"
      - "docs/decisions/"
---
```

**Command**:
```bash
ace-docs diff docs/architecture.md --since "1 month ago"
```

**Result**: Shows changes in all 4 specified paths over the last month, filtering out everything else.

#### Scenario 3: Workflow-specific documentation

**Goal**: Workflow instruction only cares about its own directory

**Setup**:
```yaml
---
doc-type: workflow
purpose: Document update workflow instructions
update:
  focus:
    paths:
      - "dev-handbook/workflow-instructions/"
---
```

**Command**:
```bash
ace-docs diff dev-handbook/workflow-instructions/update-docs.wf.md
```

**Result**: Only shows changes in workflow-instructions directory.

#### Scenario 4: Using wildcards for file patterns

**Goal**: Track all markdown file changes

**Setup**:
```yaml
---
update:
  focus:
    paths:
      - "*.md"              # All markdown files in root
      - "docs/**/*.md"      # All markdown files in docs subdirectories
---
```

**Command**:
```bash
ace-docs diff docs/README.md
```

**Result**: Git's native glob support expands wildcards, showing all matching markdown files.

#### Scenario 5: Backward compatibility (no focus.paths)

**Goal**: Document without focus.paths should still work

**Setup**:
```yaml
---
doc-type: guide
purpose: General development guide
update:
  last-updated: '2025-10-14'
---
```

**Command**:
```bash
ace-docs diff docs/guide.md
```

**Result**: Shows full repository diff (backward compatible behavior).

### Command Reference

```bash
# Basic diff with path filtering
ace-docs diff <document-path>

# Combine with time range
ace-docs diff <document-path> --since "1 week ago"

# Combine with rename exclusion
ace-docs diff <document-path> --exclude-renames

# Combine with move exclusion
ace-docs diff <document-path> --exclude-moves

# Analyze all documents (each uses its own focus.paths)
ace-docs diff --all

# Analyze documents needing updates (with their focus.paths)
ace-docs diff --needs-update
```

**Internal Implementation**: The command extracts `focus.paths` from frontmatter and passes them to `git diff <since>..HEAD -- path1 path2 path3`. Git handles all the filtering natively.

### Tips and Best Practices

**Specify Directories with Trailing Slash**:
- ✅ `"ace-docs/"` - includes entire directory
- ❌ `"ace-docs"` - might match files named `ace-docs` exactly

**Relative Paths from Repository Root**:
- All paths are relative to git repository root
- Don't use `./` or `../` prefix

**Empty or Missing focus.paths**:
- Empty array `paths: []` - treated as missing (full diff)
- Missing field entirely - full diff (backward compatible)

**Combining Multiple Filters**:
- Frontmatter `focus.paths` + `--exclude-renames` - both apply
- Frontmatter `focus.paths` + `--since` - both apply
- Path filtering is additive (includes all specified paths)

### Troubleshooting

**Problem**: Diff shows no changes but I know there are changes

**Solution**: Check that your paths are correct
```bash
# Verify paths exist
ls ace-docs/
ls CHANGELOG.md

# Check if changes are in those paths
git log --since="1 week ago" --oneline -- ace-docs/ CHANGELOG.md
```

**Problem**: Paths with spaces aren't working

**Solution**: Quote paths in YAML
```yaml
paths:
  - "path with spaces/"
  - "file with spaces.md"
```

**Problem**: Want to see changes in multiple unrelated paths

**Solution**: That's what focus.paths is for! Just list all paths:
```yaml
paths:
  - "ace-core/"
  - "ace-docs/"
  - "docs/"
  - "CHANGELOG.md"
```

## Semantic Validation

### What It Does

The `--semantic` flag enables LLM-powered validation of documentation content, checking for:
- Content matches stated document purpose
- Information accuracy and currency
- Contradictions or inconsistencies
- Appropriate depth for document type

### Usage

```bash
# Validate single document
ace-docs validate docs/architecture.md --semantic

# Validate with syntax checking too
ace-docs validate docs/guide.md --all
```

### Expected Output

**Success**:
```
✓ Semantic validation passed for docs/architecture.md
```

**Failure**:
```
✗ Semantic validation failed for docs/architecture.md:
  - Content contradicts stated purpose in section "Tools Overview"
  - Missing depth for architecture document type
  - Outdated information about ace-lint integration
```

**Error** (ace-llm-query not found):
```
Error: Semantic validation unavailable (ace-llm-query not found)
Install ace-llm gem to enable semantic validation
```

### How It Works

1. Reads document content, type, and purpose from frontmatter
2. Calls `ace-llm-query` subprocess with validation prompt
3. Uses gflash model (fast, cost-effective) at temperature 0.3 (deterministic)
4. Parses response for VALID/INVALID and issue list
5. Returns results to user

### Performance Considerations

- **Latency**: 5-30 seconds per document (LLM call overhead)
- **Cost**: Minimal (gflash is cost-effective)
- **Opt-in**: Only runs when `--semantic` flag is used
- **One-at-a-time**: Validates one document per command

### Tips

**When to Use Semantic Validation**:
- After major content updates
- Before publishing documentation
- When uncertain if content still accurate
- For high-stakes architecture or design docs

**When to Skip**:
- Minor wording changes
- Syntax-only fixes
- Batch validation of many files (too slow)
- CI/CD pipelines (use --syntax instead)

## Migration from Previous Versions

### Before (< v0.3.3)

```yaml
# Old structure (keywords as array directly)
update:
  focus:
    - implementation
    - architecture
```

**Problem**: `focus.paths` didn't work (documented but unimplemented)

### After (>= v0.3.3)

```yaml
# New structure (split into keywords and paths)
update:
  focus:
    keywords:
      - implementation
      - architecture
    paths:
      - "ace-docs/"
      - "CHANGELOG.md"
```

**Benefits**:
- `focus.paths` now functional (filters diffs)
- `focus.keywords` documented for future use
- Backward compatible (missing focus.paths = full diff)

## Command Cheat Sheet

```bash
# Focus path filtering
ace-docs diff <doc> # Uses focus.paths from frontmatter
ace-docs diff <doc> --since "1 week ago"  # With time range
ace-docs diff --all  # All docs (each with own paths)

# Semantic validation
ace-docs validate <doc> --semantic  # LLM validation only
ace-docs validate <doc> --all       # Syntax + semantic
ace-docs validate --syntax          # Syntax only (fast)

# Update frontmatter with focus paths
ace-docs update <doc> --set "focus.paths:['gem/', 'CHANGELOG.md']"
```

## Troubleshooting

### General Issues

**Q: How do I know if focus.paths is working?**

A: Check the session metadata:
```bash
cat .cache/ace-docs/diff-*/metadata.yml
# Look for:
# options:
#   :paths: ["ace-docs/", "CHANGELOG.md"]
```

**Q: Can I use focus.paths with ace-docs analyze?**

A: Not yet. The analyze command generates full repository diffs for LLM analysis. Focus paths work with the `diff` command only.

**Q: What if git diff returns no changes for my paths?**

A: This is normal if there are truly no changes in those paths. Verify:
```bash
git log --since="1 week ago" --oneline -- your/path/here
```

### Semantic Validation Issues

**Q: Semantic validation is slow**

A: This is expected (5-30s per document). The LLM needs to read and analyze your content. For faster validation, use `--syntax` instead.

**Q: ace-llm-query not found**

A: Install the ace-llm gem:
```bash
gem install ace-llm
# or in mono-repo:
bundle install
```

**Q: LLM validation returned unexpected results**

A: Semantic validation uses AI, so results may vary. Review the issues it identifies - they often highlight real problems. If consistently wrong, report the issue.
