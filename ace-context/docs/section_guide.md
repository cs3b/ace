# Section-Based Content Organization Guide

This guide explains how to use the section-based content organization system in ace-context, which allows you to organize context content into logical sections (focus, style, diff, etc.) with XML-style tags for better structure and clarity.

## Overview

ace-context supports both traditional configurations and section-based organization. Sections provide enhanced structure without requiring changes to existing configurations.

## Benefits of Using Sections

- **Better Organization**: Content is grouped logically by semantic meaning
- **XML-style Tags**: Structured output with `<sectionname>` tags for processing
- **Priority Ordering**: Control the order of sections with priority values
- **Full Compatibility**: Existing configurations continue to work unchanged
- **Mixed Usage**: Use sections alongside traditional configurations

## When to Use Sections

### Use Sections When:
- You need structured output for processing by other tools
- You want clear separation between different types of content
- You're creating specialized review contexts (code review, security review, etc.)
- You need precise control over content ordering
- You want section-specific file organization

### Use Traditional Format When:
- You have simple, flat configurations
- You don't need XML-style structured output
- You prefer the established format
- Your team is not ready to adopt sections yet

## Section Format vs. Traditional Format

### Traditional Format (Still Supported)

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

### Section-Based Format (Enhanced)

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
  description: "Main source files being reviewed"
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
  description: "System status and information"
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
  description: "Recent code changes to review"
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
  description: "Review introduction and context"
  content: |
    This is a code review of the recent changes.
    Please focus on performance and security aspects.
```

## Using Sections with Existing Configurations

ace-context automatically detects and enhances traditional configurations:

1. **Auto-Enhancement**: Traditional configurations get automatic section organization
2. **Mixed Usage**: You can combine traditional and section-based approaches
3. **Gradual Adoption**: Migrate configurations at your own pace

### Auto-Enhancement Results

When ace-context encounters a traditional configuration, it automatically creates sections:

| Traditional Field | Section Name | Title | Priority |
|-------------------|--------------|-------|----------|
| `files` | `files` | "Files" | 100 |
| `commands` | `commands` | "Commands" | 200 |
| `diffs`/`ranges` | `diffs` | "Diffs" | 300 |

### Mixed Configuration Example

You can use both approaches in the same configuration:

```yaml
context:
  files:        # Traditional files (go to attachments section)
    - README.md
  commands:     # Traditional commands (go to attachments section)
    - pwd
  sections:
    focus:       # Enhanced section-based organization
      title: "Source Code"
      content_type: "files"
      files: ["src/**/*.js"]
```

## Output Formats

### markdown-xml (Recommended for Sections)

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
    M src/main.js
    A README.md
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
M src/main.js
A README.md
```
```

### Section File Organization

Use `--organize-by-sections` to create separate files for each section:

```bash
ace-context code-review --organize-by-sections --output context.md
```

This creates:
- `context.md` (index with complete context)
- `context-focus.md` (files section)
- `context-style.md` (style section)
- `context-diff.md` (diff section)
- etc.

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

### Section File Organization
```bash
# Write sections to separate files
ace-context code-review --organize-by-sections --output context.md
```

## Troubleshooting

### Section Validation Errors
```
Warning: Section validation failed in preset.md: Section 'focus' missing required field: content_type
```

**Solution**: Ensure all sections have required fields (title, content_type).

### Auto-Enhancement Not Expected
If traditional configurations aren't being enhanced as expected, check:
- Configuration doesn't already have `sections` key
- At least one of `files`, `commands`, or `diffs` is present
- No syntax errors in the YAML

### Mixed Configuration Issues
You can use both approaches simultaneously:
```yaml
context:
  files:      # Traditional files (go to attachments section)
  commands:   # Traditional commands (go to attachments section)
  sections:
    focus:     # Enhanced section-based organization
      title: "Files Under Review"
      content_type: "files"
      files: ["src/**/*.js"]
```

## Best Practices

1. **Use Semantic Section Names**: Choose meaningful names (focus, style, diff, context)
2. **Set Clear Priorities**: Lower numbers appear first (1-10 for main sections)
3. **Provide Descriptions**: Help users understand what each section contains
4. **Use markdown-xml Format**: Best for structured processing with XML tags
5. **Test Configurations**: Verify section organization works for your use case
6. **Document Usage**: Update team documentation when adopting sections
7. **Consider Audience**: Use sections when the output will be processed by tools or needs clear structure

## Examples

See the `.ace.example/context/presets/` directory for complete examples of section-based configurations:

- `code-review.md` - Comprehensive code review sections
- `documentation-review.md` - Documentation-focused sections
- `security-review.md` - Security-focused sections
- `section-example-simple.md` - Basic section structure

Each example demonstrates different patterns and use cases for section-based organization.