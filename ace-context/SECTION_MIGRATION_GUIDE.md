# Section-Based Content Organization Migration Guide

This guide explains how to migrate existing ace-context configurations to use the new section-based content organization system.

## Overview

The section-based system allows you to organize context content into logical sections (focus, style, diff, etc.) with XML-style tags, providing better structure and clarity for your context configurations.

## Benefits of Sections

- **Better Organization**: Content is grouped logically by semantic meaning
- **XML-style Tags**: Structured output with `<sectionname>` tags for processing
- **Priority Ordering**: Control the order of sections with priority values
- **Backward Compatibility**: Existing configurations continue to work unchanged
- **Auto-Migration**: Legacy configurations can be automatically migrated

## Migration from Legacy Format

### Before (Legacy Format)

```yaml
---
description: "Project context"
context:
  params:
    output: cache
    max_size: 10485760
    timeout: 30
  embed_document_source: true
  files:
    - docs/README.md
    - docs/CODING_STANDARDS.md
    - lib/**/*.rb
  commands:
    - git status
    - pwd
  diffs:
    - origin/main...HEAD
---
```

### After (Section-Based Format)

```yaml
---
description: "Project context with sections"
context:
  params:
    output: cache
    max_size: 10485760
    timeout: 30
  embed_document_source: true

  sections:
    focus:
      title: "Files Under Review"
      content_type: "files"
      priority: 1
      description: "Source files and documentation"
      files:
        - docs/README.md
        - docs/CODING_STANDARDS.md
        - lib/**/*.rb

    diff:
      title: "Recent Changes"
      content_type: "diffs"
      priority: 2
      description: "Recent changes in the codebase"
      ranges:
        - origin/main...HEAD

    context:
      title: "System Context"
      content_type: "commands"
      priority: 3
      description: "System and project status"
      commands:
        - git status
        - pwd
---
```

## Section Schema Reference

### Required Fields

- **title**: Human-readable title for the section
- **content_type**: Type of content (files, commands, diffs, content)

### Optional Fields

- **priority**: Numerical priority (lower numbers appear first, default: 999)
- **description**: Description of what the section contains
- **exclude**: File exclusion patterns for file sections

### Content Type Specific Fields

#### files sections
```yaml
focus:
  title: "Source Files"
  content_type: "files"
  priority: 1
  files:
    - "src/**/*.js"
    - "README.md"
  exclude:
    - "**/*.test.js"
    - "node_modules/**"
```

#### commands sections
```yaml
system:
  title: "System Information"
  content_type: "commands"
  priority: 2
  commands:
    - "pwd"
    - "git status --short"
    - "npm test"
```

#### diffs sections
```yaml
changes:
  title: "Code Changes"
  content_type: "diffs"
  priority: 1
  ranges:
    - "origin/main...HEAD"
    - "HEAD~5...HEAD"
```

#### content sections
```yaml
intro:
  title: "Introduction"
  content_type: "content"
  priority: 1
  content: |
    This is a code review of the recent changes.
    Please focus on performance and security aspects.
```

## Auto-Migration

ace-context will automatically migrate legacy configurations to sections when:

1. The configuration has `files`, `commands`, or `diffs` but no `sections`
2. The system detects it's a legacy format during loading

The auto-migration creates sections with these defaults:

| Legacy Field | Section Name | Title | Priority |
|--------------|--------------|-------|----------|
| `files` | `files` | "Files" | 100 |
| `commands` | `commands` | "Commands" | 200 |
| `diffs`/`ranges` | `diffs` | "Diffs" | 300 |

## Output Formats

### markdown-xml (Recommended)
```
## Files Under Review
<focus>
  <file path="src/main.js" language="javascript">
    // Code content here
  </file>
</focus>

## System Context
<context>
  <output command="git status --short">
    // Git status output
  </output>
</context>
```

### markdown
```
## Files Under Review
### src/main.js
```javascript
// Code content here
```

## System Context
### Command: `git status --short`
```
// Git status output
```
```

## Common Section Patterns

### Code Review Sections
```yaml
sections:
  focus:      # Files being reviewed
  style:      # Style guidelines and standards
  diff:       # Recent changes
  tests:      # Test results
  context:    # Project information
```

### Documentation Review Sections
```yaml
sections:
  content:    # Documentation content
  style:      # Style guidelines
  structure:  # Organization and navigation
  examples:   # Code examples
```

### Security Review Sections
```yaml
sections:
  vulnerability:  # Security scans
  secrets:        # Secrets detection
  dependencies:   # Dependency security
  sensitive:      # Sensitive files
  policies:       # Security policies
```

## Backward Compatibility

- **Existing Presets**: Continue to work unchanged
- **Mixed Configurations**: You can have both legacy keys and sections
- **Gradual Migration**: Migrate one preset at a time
- **Auto-Detection**: System automatically detects section vs. legacy formats

## CLI Usage

### Loading Section-Based Presets
```bash
# Load section-based preset
ace-context code-review

# Output organized by sections
ace-context code-review --organize-by-sections

# Specify output format
ace-context code-review --format markdown-xml
```

### File Organization
```bash
# Write sections to separate files
ace-context code-review --organize-by-sections --output context.md
```

This creates:
- `context.md` (index with complete context)
- `context-focus.md` (files section)
- `context-style.md` (style section)
- `context-diff.md` (diff section)
- etc.

## Troubleshooting

### Section Validation Errors
```
Warning: Section validation failed in preset.md: Section 'focus' missing required field: content_type
```

**Solution**: Ensure all sections have required fields (title, content_type).

### Auto-Migration Not Working
If auto-migration doesn't occur, check:
- Configuration doesn't already have `sections` key
- At least one of `files`, `commands`, or `diffs` is present
- No syntax errors in the YAML

### Mixed Legacy and Sections
You can temporarily use both:
```yaml
context:
  files:    # Legacy files (will go to attachments section)
  commands: # Legacy commands (will go to attachments section)
  sections:
    focus:   # New section-based organization
      title: "Files Under Review"
      content_type: "files"
      files: ["src/**/*.js"]
```

## Best Practices

1. **Use Semantic Section Names**: Choose meaningful names (focus, style, diff, context)
2. **Set Clear Priorities**: Lower numbers appear first (1-10 for main sections)
3. **Provide Descriptions**: Help users understand what each section contains
4. **Use markdown-xml Format**: Best for structured processing with XML tags
5. **Test Migrations**: Verify auto-migrated sections make sense for your use case
6. **Document Changes**: Update team documentation when migrating to sections

## Example Migrations

See the `.ace.example/context/presets/` directory for complete examples of section-based configurations covering different use cases:

- `code-review.md` - Comprehensive code review sections
- `documentation-review.md` - Documentation-focused sections
- `security-review.md` - Security-focused sections
- `section-example-simple.md` - Basic section structure