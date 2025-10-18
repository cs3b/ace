# Multi-Subject Configuration for ace-docs

## Overview

The multi-subject configuration feature allows you to categorize and filter different types of changes (code, config, documentation) separately when analyzing documents. This provides clearer, more focused analysis by preventing documentation changes from obscuring important code modifications.

## Configuration

### Basic Multi-Subject Setup

Configure multiple subjects in your document's frontmatter:

```yaml
---
ace-docs:
  context:
    files:
      - CHANGELOG.md
  subject:
    - code:
        diff:
          filters:
            - ace-docs/**/*.rb
    - config:
        diff:
          filters:
            - ace-docs/**/*.yml
            - ace-docs/**/*.yaml
    - docs:
        diff:
          filters:
            - ace-docs/**/*.md
            - ace-docs/.ace.example/*.md
---
```

### Backward Compatible (Single Subject)

The traditional single-subject configuration continues to work:

```yaml
---
ace-docs:
  subject:
    diff:
      filters:
        - ace-docs/**/*.rb
        - ace-docs/**/*.md
---
```

## Usage Examples

### Basic Analysis with Multiple Subjects

```bash
$ ace-docs analyze README.md

Analyzing document: README.md
Document type: reference
Purpose: Overview and quick start guide for ace-docs

Subjects configured:
  - code: ace-docs/**/*.rb
  - config: ace-docs/**/*.yml, ace-docs/**/*.yaml
  - docs: ace-docs/**/*.md, ace-docs/.ace.example/*.md

Time range: Changes since 2025-10-11 (7 days)

Generating diffs for 3 subjects...
  ✓ code: 245 lines changed across 8 files
  ✓ config: 34 lines changed across 2 files
  ✓ docs: 598 lines changed across 4 files

Creating analysis context...
Running LLM analysis...

Analysis complete!
Session: .cache/ace-docs/analyze-20251018-143022/

Files created:
  - code.diff (245 lines)
  - config.diff (34 lines)
  - docs.diff (598 lines)
  - context.md (with all diffs embedded)
  - analysis.md (dual-mode analysis results)
```

### Viewing Generated Files

```bash
# List all generated files
$ ls .cache/ace-docs/analyze-20251018-143022/
analysis.md    code.diff      config.diff    context.md
docs.diff      metadata.yml   prompt-system.md prompt-user.md

# View specific diff
$ head -20 .cache/ace-docs/analyze-20251018-143022/code.diff
diff --git a/ace-docs/lib/ace/docs/models/document.rb b/ace-docs/lib/ace/docs/models/document.rb
index abc123..def456 100644
--- a/ace-docs/lib/ace/docs/models/document.rb
+++ b/ace-docs/lib/ace/docs/models/document.rb
...

# View the analysis
$ cat .cache/ace-docs/analyze-20251018-143022/analysis.md
## 🧩 1. Code Change Analysis

### Summary
Refactored analyze command into modular pipeline and added multi-subject support to Document model...

## 📚 2. Documentation & Configuration Change Analysis

### Summary
Updated configuration examples and added comprehensive usage documentation...
```

## Common Patterns

### Separating Test Files

```yaml
subject:
  - code:
      diff:
        filters:
          - lib/**/*.rb
  - tests:
      diff:
        filters:
          - test/**/*.rb
          - spec/**/*.rb
  - docs:
      diff:
        filters:
          - "**/*.md"
```

### Frontend/Backend Separation

```yaml
subject:
  - backend:
      diff:
        filters:
          - app/controllers/**/*
          - app/models/**/*
          - lib/**/*
  - frontend:
      diff:
        filters:
          - app/javascript/**/*
          - app/views/**/*
          - app/assets/**/*
  - config:
      diff:
        filters:
          - config/**/*
          - "**/*.yml"
```

### Gem-Specific Analysis

```yaml
subject:
  - gem-core:
      diff:
        filters:
          - ace-docs/lib/**/*.rb
          - ace-docs/exe/*
  - gem-tests:
      diff:
        filters:
          - ace-docs/test/**/*
  - gem-docs:
      diff:
        filters:
          - ace-docs/**/*.md
          - ace-docs/.ace.example/**/*
```

## Edge Cases

### No Changes for a Subject

When a subject has no matching changes, it's skipped:

```bash
$ ace-docs analyze README.md

Subjects configured:
  - code: lib/**/*.rb
  - config: config/**/*.yml
  - docs: "**/*.md"

Generating diffs for 3 subjects...
  ✓ code: 125 lines changed across 3 files
  ⊘ config: No changes detected (skipped)
  ✓ docs: 45 lines changed across 2 files
```

### Empty Subject Configuration

If no filters are provided for a subject, it's treated as empty and skipped:

```yaml
subject:
  - code:
      diff:
        filters: []  # Empty filter list - will be skipped
  - docs:
      diff:
        filters:
          - "**/*.md"
```

## Tips and Best Practices

1. **Use Descriptive Subject Names**: Choose clear names that describe the content (e.g., `backend`, `frontend`, `database`, `api`)

2. **Order Matters for Display**: Subjects are processed and displayed in the order defined

3. **Glob Patterns**: Use standard git path specifications and glob patterns for maximum flexibility

4. **Combine Related Files**: Group related file types in a single subject for cohesive analysis

5. **Test Your Filters**: Use `git diff --name-only -- <pattern>` to test your filter patterns before configuring

## Migration Guide

### From Single to Multi-Subject

**Before:**
```yaml
ace-docs:
  subject:
    diff:
      filters:
        - "**/*.rb"
        - "**/*.md"
```

**After:**
```yaml
ace-docs:
  subject:
    - code:
        diff:
          filters:
            - "**/*.rb"
    - docs:
        diff:
          filters:
            - "**/*.md"
```

### From Legacy Format

**Before (legacy):**
```yaml
update:
  focus:
    paths:
      - lib/**/*
      - test/**/*
```

**After:**
```yaml
ace-docs:
  subject:
    - implementation:
        diff:
          filters:
            - lib/**/*
            - test/**/*
```

## Future Enhancements

The following features are planned for future releases:

- **Analysis Mode Selection**: `--mode code|docs|all` flag to focus analysis
- **Parallel Diff Generation**: Speed up multi-subject processing
- **Smart Subject Detection**: Automatically suggest subject configurations
- **Subject Templates**: Predefined subject configurations for common project types