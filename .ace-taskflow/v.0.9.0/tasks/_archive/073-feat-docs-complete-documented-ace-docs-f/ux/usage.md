# Subject Diff Filtering and Semantic Validation - Usage Guide

## Overview

This document describes two enhanced features for ace-docs:

1. **Subject Diff Filtering**: Filter git diffs to show only changes in relevant files/directories
2. **Semantic Validation**: LLM-powered validation of documentation accuracy and consistency

These features complete documented functionality from task 071 and align ace-docs with ace-review's subject/context architecture pattern.

## Frontmatter Structure: ace-docs Namespace

All ace-docs configuration now lives under the `ace-docs:` namespace to avoid conflicts with other tools and provide clear organization.

### Complete Structure

```yaml
---
doc-type: reference
purpose: Overview and quick start guide for ace-docs
ace-docs:
  frequency: weekly
  last-updated: '2025-10-14'
  subject:
    diff:
      filters:                   # Git diff path filters (what we're analyzing)
        - "ace-docs/"            # Include entire directory
        - "CHANGELOG.md"         # Include specific file
        - "dev-handbook/guides/" # Include another directory
    files: []                    # Optional: raw files to include (future feature)
  context:
    keywords:                    # LLM relevance hints (for future use)
      - implementation
      - architecture
    preset: "project"            # ace-context preset to use
  rules:
    max-lines: 200
    sections: ["overview", "scope"]
---
```

### Key Concepts

- **`ace-docs:`** - Namespace for all ace-docs configuration
- **`subject:`** - What we're analyzing (the diff filters, files)
- **`context:`** - Information for understanding (keywords, presets)
- **`rules:`** - Validation rules (max lines, required sections)

This structure aligns with ace-review's subject/context pattern, making the two tools consistent.

## Subject Diff Filtering

### What It Does

When you specify `ace-docs.subject.diff.filters` in a document's frontmatter, `ace-docs diff` will only show git changes in those specific files or directories. This dramatically reduces noise when tracking documentation updates.

### Usage Scenarios

#### Scenario 1: Track gem-specific changes for README

**Goal**: ace-docs/README.md should only track changes in ace-docs gem and CHANGELOG

**Setup**:
```yaml
---
doc-type: reference
purpose: Overview and quick start guide for ace-docs
ace-docs:
  last-updated: '2025-10-14'
  context:
    preset: project
  subject:
    diff:
      filters:
        - "ace-docs/**/*.rb"
        - "ace-docs/**/*.md"
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
ace-docs:
  frequency: weekly
  subject:
    diff:
      filters:
        - "ace-core/"
        - "ace-docs/"
        - "ace-taskflow/"
        - "docs/decisions/"
  context:
    preset: architecture
    keywords:
      - ATOM pattern
      - mono-repo
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
ace-docs:
  subject:
    diff:
      filters:
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
doc-type: guide
purpose: Documentation standards guide
ace-docs:
  subject:
    diff:
      filters:
        - "*.md"              # All markdown files in root
        - "docs/**/*.md"      # All markdown files in docs subdirectories
---
```

**Command**:
```bash
ace-docs diff docs/standards.md
```

**Result**: Git's native glob support expands wildcards, showing all matching markdown files.

#### Scenario 5: Backward compatibility (no subject.diff.filters)

**Goal**: Document without subject.diff.filters should still work

**Setup**:
```yaml
---
doc-type: guide
purpose: General development guide
ace-docs:
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
# Basic diff with subject filtering
ace-docs diff <document-path>

# Combine with time range
ace-docs diff <document-path> --since "1 week ago"

# Combine with rename exclusion
ace-docs diff <document-path> --exclude-renames

# Combine with move exclusion
ace-docs diff <document-path> --exclude-moves

# Analyze all documents (each uses its own subject.diff.filters)
ace-docs diff --all

# Analyze documents needing updates (with their subject.diff.filters)
ace-docs diff --needs-update
```

**Internal Implementation**: The command extracts `ace-docs.subject.diff.filters` from frontmatter and passes them to `git diff <since>..HEAD -- path1 path2 path3`. Git handles all the filtering natively.

### Tips and Best Practices

**Specify Directories with Trailing Slash**:
- ✅ `"ace-docs/"` - includes entire directory
- ❌ `"ace-docs"` - might match files named `ace-docs` exactly

**Relative Paths from Repository Root**:
- All paths are relative to git repository root
- Don't use `./` or `../` prefix

**Empty or Missing subject.diff.filters**:
- Empty array `filters: []` - treated as missing (full diff)
- Missing field entirely - full diff (backward compatible)

**Combining Multiple Filters**:
- Frontmatter `subject.diff.filters` + `--exclude-renames` - both apply
- Frontmatter `subject.diff.filters` + `--since` - both apply
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
subject:
  diff:
    filters:
      - "path with spaces/"
      - "file with spaces.md"
```

**Problem**: Want to see changes in multiple unrelated paths

**Solution**: That's what subject.diff.filters is for! Just list all paths:
```yaml
subject:
  diff:
    filters:
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
2. Uses context.keywords if present to inform LLM analysis
3. Calls `ace-llm-query` subprocess with validation prompt
4. Uses gflash model (fast, cost-effective) at temperature 0.3 (deterministic)
5. Parses response for VALID/INVALID and issue list
6. Returns results to user

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

**Old structure (confusing terminology)**:
```yaml
update:
  focus:
    keywords:
      - implementation
      - architecture
    paths:
      - "ace-docs/"
```

**Problems**:
- Generic `update:` key could conflict with other tools
- Unclear what "focus" means (subject or context?)
- Not aligned with ace-review's architecture

### After (>= v0.3.3)

**New structure (clear, namespaced)**:
```yaml
ace-docs:
  subject:
    diff:
      filters:
        - "ace-docs/"
  context:
    keywords:
      - implementation
      - architecture
```

**Benefits**:
- Namespaced to `ace-docs:` - no conflicts
- Clear semantics: subject = what we analyze, context = info for understanding
- Aligned with ace-review's subject/context pattern
- Backward compatible (old format still works via fallback)

### Automatic Fallback

No migration needed! Old `update.focus.paths` format continues to work:

```yaml
# Old format (deprecated but supported)
update:
  focus:
    paths:
      - "ace-docs/"
```

The Document model checks for the new format first, then falls back to the old format if not found. This ensures existing documents continue to work without changes.

## Alignment with ace-review

Both ace-docs and ace-review now use consistent subject/context terminology:

**ace-review** (code review):
```yaml
subject:
  files: ["lib/**/*.rb"]         # Files to review
  diffs: ["origin/main...HEAD"]  # Diff ranges to review
  commands: ["git log -5"]       # Commands to run

context:
  files: ["README.md"]            # Context files for understanding
  presets: ["project"]            # Context presets
```

**ace-docs** (documentation management):
```yaml
ace-docs:
  subject:
    diff:
      filters: ["ace-docs/"]     # Paths to filter in diff
    files: []                    # Raw files (future feature)

  context:
    keywords: ["architecture"]   # LLM relevance hints
    preset: "project"            # Context preset
```

**Common Pattern**:
- `subject:` = What we're analyzing/reviewing
- `context:` = Information to understand the subject

This consistency makes it easier to work with both tools and understand their configurations.

## Command Cheat Sheet

```bash
# Subject diff filtering
ace-docs diff <doc>                          # Uses subject.diff.filters from frontmatter
ace-docs diff <doc> --since "1 week ago"     # With time range
ace-docs diff --all                          # All docs (each with own filters)

# Semantic validation
ace-docs validate <doc> --semantic           # LLM validation only
ace-docs validate <doc> --all                # Syntax + semantic
ace-docs validate --syntax                   # Syntax only (fast)

# Update frontmatter with ace-docs namespace
ace-docs update <doc> --set "ace-docs.subject.diff.filters:['gem/', 'CHANGELOG.md']"
ace-docs update <doc> --set "ace-docs.context.preset:project"
```

## Troubleshooting

### General Issues

**Q: How do I know if subject.diff.filters is working?**

A: Check the session metadata:
```bash
cat .cache/ace-docs/diff-*/metadata.yml
# Look for:
# options:
#   :paths: ["ace-docs/", "CHANGELOG.md"]
```

**Q: Can I use subject.diff.filters with ace-docs analyze?**

A: Not yet. The analyze command generates full repository diffs for LLM analysis. Subject filters work with the `diff` command only.

**Q: What if git diff returns no changes for my paths?**

A: This is normal if there are truly no changes in those paths. Verify:
```bash
git log --since="1 week ago" --oneline -- your/path/here
```

**Q: Does the old update.focus.paths format still work?**

A: Yes! The Document model provides backward compatibility. However, we recommend migrating to the new `ace-docs.subject.diff.filters` structure for clarity and consistency.

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

## Examples

### Example 1: README with Subject Filters

File: `ace-docs/README.md`

```yaml
---
doc-type: reference
purpose: Overview and quick start guide for ace-docs
ace-docs:
  last-updated: '2025-10-14'
  context:
    preset: project
  subject:
    diff:
      filters:
        - "CHANGELOG.md"
        - "ace-docs/**/*.rb"
        - "ace-docs/**/*.md"
---
```

**Usage**:
```bash
ace-docs diff ace-docs/README.md
# Shows only changes in CHANGELOG.md and ace-docs/ directory
```

### Example 2: Architecture Doc with Keywords

File: `docs/architecture.md`

```yaml
---
doc-type: architecture
purpose: System architecture and ATOM pattern
ace-docs:
  frequency: weekly
  subject:
    diff:
      filters:
        - "ace-*/lib/**/*.rb"
        - "docs/decisions/"
  context:
    preset: architecture
    keywords:
      - ATOM pattern
      - mono-repo structure
      - configuration cascade
---
```

**Usage**:
```bash
# Diff with subject filtering
ace-docs diff docs/architecture.md

# Semantic validation using context keywords
ace-docs validate docs/architecture.md --semantic
```

### Example 3: Legacy Format (Backward Compatible)

File: `docs/legacy-doc.md`

```yaml
---
doc-type: guide
purpose: Development guide
update:
  frequency: monthly
  focus:
    paths:
      - "dev-handbook/"
---
```

**Usage**:
```bash
ace-docs diff docs/legacy-doc.md
# Still works! Falls back to update.focus.paths
```

## Summary

**Key Takeaways**:
1. All ace-docs config now under `ace-docs:` namespace
2. Use `subject.diff.filters` to filter diffs to relevant paths
3. Use `context.keywords` and `context.preset` for LLM context
4. Aligned with ace-review's subject/context pattern
5. Backward compatible with old `update.focus.paths` format
6. Semantic validation optional via `--semantic` flag
