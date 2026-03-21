---
doc-type: user
title: Configuration Guide
purpose: Documentation for ace-bundle/docs/configuration.md
ace-docs:
  last-updated: 2026-01-17
  last-checked: 2026-03-21
---

# Configuration Guide

This guide explains all configuration options available in ace-bundle YAML presets, including both simplified and section-based formats.

## Overview

ace-bundle supports two configuration approaches:

1. **Simplified Format** - Direct configuration without sections (ideal for simple use cases)
2. **Section-Based Format** - Organized configuration with logical sections (ideal for complex contexts)

Both formats are fully supported and can be used interchangeably.

## Simplified vs Section-Based Format

### Use Simplified Format When:
- You have simple, flat configurations
- You don't need complex organization or XML-style structured output
- You prefer a straightforward approach
- Your context requirements are basic

### Use Section-Based Format When:
- You need structured output for processing by other tools
- You want clear separation between different types of content
- You're creating specialized review contexts (code review, security review, etc.)
- You need precise control over content ordering
- You want to use preset-in-section functionality

## Complete Configuration Schema

### Top-Level Fields

```yaml
---
description: "Brief description of this preset"
bundle:
  # Configuration goes here
---
```

#### Required Fields
- `description`: Human-readable description of the preset

#### Optional Top-Level Fields
- `presets`: Array of preset names to inherit from (for preset composition)

### Context Configuration

```yaml
bundle:
  params:           # Output and processing parameters
  base:             # Path or protocol to a file for base content
  embed_document_source: bool  # Include the preset file itself in output
  files:            # List of files to include (simplified format)
  commands:         # List of commands to execute (simplified format)
  diffs:            # Git diff ranges (simplified format)
  include:          # Files to include via protocols
  sections:         # Section-based organization (alternative to simplified)
```

## Parameters Configuration

```yaml
bundle:
  params:
    output: cache|stdio|file           # Where to send output (default: stdio)
    format: markdown|markdown-xml|yaml|json  # Output format (default: markdown)
    max_size: 10485760                 # Maximum output size in bytes (default: 10485760)
    timeout: 30                        # Command timeout in seconds (default: 30)
```

### Output Options
- `cache`: Save to cache directory
- `stdio`: Print to standard output
- `file`: Save to specified file (use with `--output` CLI option)

### Format Options
- `markdown`: Standard markdown with code blocks
- `markdown-xml`: Markdown with XML-style tags (recommended for sections)
- `yaml`: YAML format
- `json`: JSON format

## Base Content Configuration

The `base` key allows you to specify a file or protocol reference that will be loaded as the primary content, appearing before any section-based output.

```yaml
bundle:
  base: docs/system-prompt.md  # Load from a file
  # or
  base: prompt://base/system   # Load via protocol

  # Base content appears first, followed by sections
  sections:
    guidelines:
      files:
        - docs/coding-standards.md
```

### Features

- **File Paths**: Load content from any file path relative to the project root
- **Protocol Support**: Use protocol references like `prompt://`, `wfi://`, `guide://` for dynamic content
- **Error Handling**: Gracefully handles missing files or invalid protocols with clear error messages
- **Output Position**: Base content always appears before sections in formatted output

### Example with Protocol

```yaml
---
description: "Code review context with base instructions"
bundle:
  params:
    format: markdown-xml

  base: prompt://base/system   # Load base review instructions

  sections:
    focus:
      title: "Review Focus"
      files:
        - prompt://focus/architecture/atom
        - prompt://focus/languages/ruby
```

## Simplified Format Examples

### Basic Configuration

```yaml
---
description: "Simple project context"
bundle:
  params:
    output: stdio
    format: markdown
    max_size: 5242880
    timeout: 15

  embed_document_source: true

  files:
    - README.md
    - lib/**/*.rb
    - src/**/*.js
    - "docs/**/*.md"

  commands:
    - pwd
    - git status --short
    - npm test

  diffs:
    - origin/main...HEAD
    - HEAD~5...HEAD
---
```

### File Exclusion Patterns

```yaml
---
description: "Source files without tests"
bundle:
  files:
    - src/**/*.rb
    - lib/**/*.rb
  exclude:
    - "**/*_test.rb"
    - "**/*_spec.rb"
    - "test/**/*"
    - "spec/**/*"
    - "vendor/**/*"
    - "node_modules/**/*"
---
```

### Protocol-based Content

```yaml
---
description: "Include workflow files"
bundle:
  include:
    - wfi://code-review-workflow
    - wfi://planning-session
    - guide://development-guide

  files:
    - README.md
    - CHANGELOG.md
---
```

## Section-Based Format Examples

### Basic Sections

```yaml
---
description: "Project context with sections"
bundle:
  params:
    output: cache
    format: markdown-xml
    max_size: 10485760
    timeout: 30

  embed_document_source: true

  sections:
    focus:
      title: "Source Files"
      description: "Main source code and documentation"
      files:
        - src/**/*.rb
        - lib/**/*.rb
        - README.md
      exclude:
        - "**/*_test.rb"
        - "test/**/*"

    commands:
      title: "System Information"
      description: "Current project status"
      commands:
        - pwd
        - git status --short
        - bundle exec rspec --format documentation

    changes:
      title: "Recent Changes"
      description: "Code changes to review"
      diff:
        ranges:
          - origin/main...HEAD
          - HEAD~5...HEAD

    intro:
      title: "Introduction"
      description: "Context for this review"
      content: |
        This code review focuses on the recent changes to the authentication system.
        Please pay special attention to security implications and performance.
---
```

### Preset-in-Section Functionality

```yaml
---
description: "Complete project context using presets"
bundle:
  params:
    output: stdio
    format: markdown-xml

  sections:
    project_context:
      title: "Complete Project Context"
      description: "Project context built from multiple presets"
      presets:
        - "base"
        - "development"
        - "testing"
      files:
        - "src/**/*.rb"
        - "docs/**/*.md"
      content: |
        This section combines base configuration with development and testing
        setups, plus project-specific files and documentation.

    security_review:
      title: "Security Analysis"
      description: "Security-focused review"
      presets:
        - "security-scanning"
        - "dependency-audit"
      commands:
        - "custom-security-script.sh"
      content: |
        Security analysis combining standard scanning tools with custom validation.
---
```

### Mixed Content Sections

```yaml
---
description: "Comprehensive review with mixed content"
bundle:
  sections:
    comprehensive:
      title: "Complete Review"
      description: "Files, commands, diffs, and analysis"
      files:
        - "src/**/*.js"
        - "package.json"
        - "README.md"
      commands:
        - "npm test"
        - "npm run lint"
        - "npm audit"
      diffs:
        - "origin/main...HEAD"
      content: |
        This comprehensive review includes:

        1. **Code Quality**: Style, patterns, maintainability
        2. **Security**: Vulnerabilities and dependencies
        3. **Testing**: Coverage and test results
        4. **Performance**: Potential bottlenecks

        Focus on security and performance aspects.
---
```

## Content Types and Fields

### Files Configuration

```yaml
files:
  - "src/**/*.rb"              # Glob patterns
  - "lib/main.rb"              # Specific files
  - "docs/**/*.md"            # Multiple patterns
  - "config/*.yml"            # YAML files

exclude:                       # Optional exclusion patterns
  - "**/*_test.rb"
  - "test/**/*"
  - "vendor/**/*"
```

### Commands Configuration

```yaml
commands:
  - "pwd"                     # System commands
  - "git status --short"      # Git commands
  - "npm test"               # Package managers
  - "bundle exec rspec"       # Ruby commands
  - "python -m pytest"       # Python commands
```

### Git Diffs Configuration

ace-bundle supports two formats for git diffs:

#### Simple Format (Legacy)

```yaml
diffs:                         # or ranges (both work)
  - "origin/main...HEAD"      # Branch comparison
  - "HEAD~5...HEAD"           # Recent commits
  - "main..feature"           # Feature branch
  - "abc123..def456"          # Commit ranges
```

This format provides a simple array of git range strings. Both `diffs` and `ranges` keys are supported for backward compatibility.

#### Complex Format (Recommended)

```yaml
diff:
  ranges:                      # Required: array of git ranges
    - "origin/main...HEAD"
    - "HEAD~5...HEAD"
  paths:                       # Optional: filter to specific paths (future)
    - "src/**/*.rb"
    - "lib/**/*.js"
  since:                       # Optional: alternative to ranges
    "origin/main"              # Expands to "origin/main...HEAD"
```

The `diff` format supports additional options:

- **`ranges`**: Array of git range strings (same as simple format)
- **`since`**: Single reference point (automatically expands to `since...HEAD`)
- **`paths`**: Path filtering (reserved for future ace-git integration)

**Use simple format when**: You only need basic git ranges
**Use complex format when**: You need path filtering or other advanced options (future)

#### Format Comparison

```yaml
# Simple format - direct array
bundle:
  diffs:
    - "origin/main...HEAD"

# Complex format - with options
bundle:
  diff:
    ranges:
      - "origin/main...HEAD"

# Complex format - using 'since'
bundle:
  diff:
    since: "origin/main"        # Expands to "origin/main...HEAD"
```

Both formats are normalized internally to the same `ranges` structure, ensuring consistent processing.

### Inline Content

```yaml
content: |
  This is markdown content that will be included directly.
  You can use **bold**, *italic*, and `code` formatting.

  ## Lists

  - Item 1
  - Item 2
  - Item 3

  ### Code Blocks

  ```ruby
  def example
    puts "Hello, World!"
  end
  ```
```

## Preset Composition

### Basic Preset Composition

```yaml
---
description: "Development environment"
presets:
  - "base-config"
  - "ruby-tools"
  - "testing-setup"

bundle:
  files:
    - "src/**/*.rb"
  commands:
    - "bundle exec rspec"
---
```

### Circular Dependency Handling

The system automatically detects and prevents circular dependencies:

```yaml
# preset-a.yaml
presets:
  - "preset-b"

# preset-b.yaml
presets:
  - "preset-a"  # ❌ This will cause circular dependency error
```

### Nesting Depth Limits

**Recommended Maximum Depth: 3-4 levels**

While ace-bundle supports deep preset nesting, excessive depth can impact performance and maintainability. Follow these guidelines:

#### ✅ Good: Shallow Hierarchy (2-3 levels)
```yaml
# base.md (level 0)
bundle:
  files:
    - "README.md"

# development.md (level 1)
presets:
  - "base"
bundle:
  files:
    - "src/**/*.rb"

# project-context.md (level 2)
presets:
  - "development"
  - "testing"
bundle:
  files:
    - "docs/**/*.md"
```

**Performance**: Fast loading, clear inheritance chain

#### ⚠️ Acceptable: Medium Depth (4 levels)
```yaml
# project-context.md (level 3)
presets:
  - "team-shared"    # references "base" (level 2)
  - "ruby-tools"     # references "development" (level 2)
```

**Performance**: Slight overhead, still manageable

#### ❌ Avoid: Deep Nesting (5+ levels)
```yaml
# feature-context.md (level 5+)
presets:
  - "specialized"   # references 4+ levels deep
```

**Problems**:
- Slow context loading
- Difficult to debug inheritance issues
- Complex dependency chains
- Circular dependency risk increases

#### Refactoring Deep Nesting

If you need deep nesting, consider **flattening with explicit content**:

```yaml
# ❌ Deep nesting
presets:
  - "level-1"  # which includes level-2, level-3, level-4...

# ✅ Explicit composition
presets:
  - "base"
  - "ruby-tools"
  - "testing"
  - "deployment"
files:
  - "specific/files/**/*"
```

This makes dependencies explicit and improves performance.

#### Performance Impact

| Depth Level | Load Time* | Maintainability |
|-------------|-----------|----------------|
| 1-2 levels  | Fast      | Excellent      |
| 3-4 levels  | Normal    | Good           |
| 5+ levels   | Slow      | Poor           |

*Approximate relative performance on typical configurations

## Configuration Validation

### Section Validation Rules

For section-based configurations:

- All section fields are optional (no required fields)
- Section names can be any valid YAML key
- `presets` must be an array of strings if present
- File patterns must be valid glob patterns or file paths
- Command strings are executed as-is

### Error Handling Examples

#### Missing Preset
```
Error: Failed to load preset 'missing-preset': Preset 'missing-preset' not found
```

#### Invalid Preset Reference
```
Warning: Section validation failed: Preset reference must be a string
```

#### Circular Dependency
```
Error: Circular dependency detected: preset-a -> preset-b -> preset-a
```

## Auto-Enhancement (Legacy Support)

When using simplified format, ace-bundle automatically organizes content into sections:

| Traditional Field | Auto-Section | Title |
|-------------------|--------------|-------|
| `files` | `files` | "Files" |
| `commands` | `commands` | "Commands" |
| `diffs`/`ranges` | `diffs` | "Diffs" |

This means simplified configurations still benefit from structured output when using `markdown-xml` format.

## Best Practices

### Configuration Design
1. **Start Simple**: Begin with simplified format, add sections only when needed
2. **Use Descriptive Names**: Make preset and section names clear and meaningful
3. **Group Related Content**: Keep similar files, commands, and content together
4. **Consider Audience**: Structure configurations based on who will use the output

### File Organization
1. **Use Specific Patterns**: Be precise with file patterns to avoid including unnecessary files
2. **Exclude Appropriately**: Use exclude patterns to filter out test files, dependencies, etc.
3. **Order Logically**: Arrange files and commands in the order you want them processed

### Preset Design
1. **Create Focused Presets**: Design presets for specific purposes (base, development, testing)
2. **Avoid Over-Composition**: Keep preset hierarchies reasonably simple. While powerful, aim for a balance between reusability and clarity. For simple contexts, defining content directly can be more straightforward than composing multiple very small presets.
3. **Document Dependencies**: Clearly document what each preset provides

### Performance Considerations
1. **Limit File Scope**: Use specific patterns rather than overly broad ones
2. **Set Appropriate Timeouts**: Configure timeouts based on command complexity
3. **Monitor Output Size**: Use `max_size` to prevent unexpectedly large outputs

## Example Configurations

### Simple Ruby Project
```yaml
---
description: "Basic Ruby project context"
bundle:
  params:
    output: stdio
    format: markdown

  files:
    - "lib/**/*.rb"
    - "test/**/*.rb"
    - "Gemfile"
    - "README.md"

  commands:
    - "ruby -v"
    - "bundle exec ruby -c lib/**/*.rb"
    - "bundle exec rspec --format documentation"
---
```

### Node.js Security Review
```yaml
---
description: "Security-focused Node.js review"
bundle:
  params:
    output: stdio
    format: markdown-xml
    timeout: 60

  sections:
    code:
      title: "Source Code"
      description: "Application source files"
      files:
        - "src/**/*.js"
        - "lib/**/*.js"
        - "package.json"
        - "package-lock.json"

    security:
      title: "Security Analysis"
      description: "Security scanning results"
      commands:
        - "npm audit --production"
        - "npx eslint --ext .js src/"
        - "npx semgrep --config=security"

    dependencies:
      title: "Dependencies"
      description: "Package dependencies and versions"
      commands:
        - "npm list --depth=0"
        - "npm outdated"

    changes:
      title: "Recent Changes"
      description: "Code changes to review"
      diff:
        since: "origin/main"    # Expands to origin/main...HEAD
---
```

This configuration guide covers all available options in ace-bundle presets. Choose the format and features that best match your use case, from simple file listings to complex multi-section contexts with preset composition.