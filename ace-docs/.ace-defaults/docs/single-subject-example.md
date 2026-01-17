---
doc-type: guide
purpose: Example document demonstrating single-subject configuration (backward compatible)
ace-docs:
  # Context configuration
  bundle:
    files:
      - README.md
    keywords:
      - architecture
      - design patterns

  # Single-subject configuration - all changes in one diff
  # This is the traditional format, still fully supported
  subject:
    diff:
      filters:
        - "lib/**/*.rb"        # Ruby library files
        - "app/**/*.rb"        # Ruby application files
        - "**/*.md"            # All markdown files
        - "config/**/*.yml"    # Configuration files

  # Validation rules
  rules:
    max-lines: 500
    sections:
      - overview
      - usage
      - examples

# Update tracking
update:
  frequency: monthly
  last-updated: 2025-10-20
---

# Single-Subject Configuration Example

This example demonstrates the **traditional single-subject configuration** which remains fully supported for backward compatibility.

## Overview

The single-subject configuration generates one consolidated diff file (`repo-diff.diff`) containing all changes that match any of the specified filters. This is the original ace-docs behavior and continues to work without any modifications needed.

## Usage

When you run `ace-docs analyze` on this document:

```bash
ace-docs analyze single-subject-example.md
```

The system will:
1. Generate a single `repo-diff.diff` file containing all changes matching the filters
2. Include changes from Ruby files, markdown files, and YAML configs in one diff
3. Provide unified analysis of all changes together

## Configuration Format

The single-subject format uses a direct `diff` object under `subject`:

```yaml
ace-docs:
  subject:
    diff:
      filters:
        - "**/*.rb"
        - "**/*.md"
        - "**/*.yml"
```

## When to Use Single-Subject

Single-subject configuration is ideal when:

1. **Small Projects**: Your project has a limited number of files
2. **Unified Analysis**: You want all changes analyzed together
3. **Simple Requirements**: You don't need to separate different types of changes
4. **Legacy Compatibility**: You have existing documents that already use this format

## Examples

### Minimal Configuration

```yaml
ace-docs:
  subject:
    diff:
      filters:
        - "src/**/*"  # Everything under src/
```

### Specific File Types

```yaml
ace-docs:
  subject:
    diff:
      filters:
        - "**/*.rb"
        - "**/*.erb"
        - "**/*.rake"
```

### Exclude Patterns

While ace-docs doesn't directly support exclude patterns, you can achieve similar results by being specific with your include patterns:

```yaml
ace-docs:
  subject:
    diff:
      filters:
        - "app/**/*.rb"     # Only app Ruby files
        - "lib/**/*.rb"     # Only lib Ruby files
        # Implicitly excludes test/**/*.rb
```

## Migration to Multi-Subject

If you later want to migrate to multi-subject configuration, you can split your filters into categories:

**Before (Single-Subject):**
```yaml
subject:
  diff:
    filters:
      - "**/*.rb"
      - "**/*.md"
      - "**/*.yml"
```

**After (Multi-Subject):**
```yaml
subject:
  - code:
      diff:
        filters:
          - "**/*.rb"
  - docs:
      diff:
        filters:
          - "**/*.md"
  - config:
      diff:
        filters:
          - "**/*.yml"
```

Both configurations are valid and you can choose based on your needs.