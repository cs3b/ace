# Command-Line Usage Guide

This guide explains how to use the ace-bundle command-line interface to load, process, and output project contexts.

## Basic Usage

```bash
ace-bundle load <input> [options]
```

The simplest usage loads a preset by name:

```bash
# Load the 'project-base' preset
ace-bundle load project-base

# Load the 'code-review' preset
ace-bundle load code-review
```

## Discovering Presets

### Finding Available Presets

Presets are stored in `~/.ace/bundle/presets/` (or `ACE_BUNDLE_DIR/presets/`). You can list available presets:

```bash
# List all available presets
ls ~/.ace/bundle/presets/

# Show preset details
cat ~/.ace/bundle/presets/project-base.md

# Check if a preset exists
test -f ~/.ace/bundle/presets/security-review.md && echo "Preset exists" || echo "Preset not found"
```

### Understanding Preset Errors

When you reference a non-existent preset, ace-bundle provides helpful error messages:

```bash
ace-bundle load unknown-preset
# Error: Preset 'unknown-preset' not found. Available presets: project-base, code-review, security-review, development
```

The error message includes:
- The preset name that couldn't be found
- A list of all available presets to help you choose the correct one

### Custom Preset Locations

You can override the default preset location using environment variables:

```bash
# Use custom bundle directory
export ACE_BUNDLE_DIR="/path/to/my/contexts"
ace-bundle load my-custom-preset

# Check current preset directory
echo "Presets directory: ${ACE_BUNDLE_DIR:-$HOME/.ace/bundle/presets}"
```

## Command-Line Options

### Output Options

#### `--output`, `-o`
Specify output file location.

```bash
# Save to specific file
ace-bundle load project-base --output context.md

# Save to cache directory (default behavior)
ace-bundle load project-base --output cache

# Short form
ace-bundle load project-base -o context.md
```

#### `--format`, `-F`
Specify output format.

```bash
# Markdown with XML-style tags (recommended for sections)
ace-bundle load project-base --format markdown-xml

# Standard markdown
ace-bundle load project-base --format markdown

# YAML format
ace-bundle load project-base --format yaml

# JSON format
ace-bundle load project-base --format json

# Short form
ace-bundle load project-base -F markdown-xml
```

### Input Options

#### `--preset`, `-p`
Load specific preset(s). Can be used multiple times.

```bash
# Load single preset
ace-bundle load --preset project-base

# Load multiple presets (composed together)
ace-bundle load --preset base --preset development --preset testing

# Short form
ace-bundle load -p base -p development
```

#### `--file`, `-f`
Load configuration from YAML or markdown file with frontmatter.

```bash
# Load from YAML file
ace-bundle load --file config/project.yml

# Load from markdown file with frontmatter
ace-bundle load --file docs/project-config.md

# Load multiple files
ace-bundle load --file base.yml --file overrides.md

# Short form
ace-bundle load -f config.yml
```

#### Positional Arguments
You can also specify presets as positional arguments:

```bash
# These are equivalent:
ace-bundle load project-base
ace-bundle load --preset project-base
```

### Display Options

#### `--organize-by-sections`
Create separate files for each section when using section-based presets.

```bash
# Create separate section files
ace-bundle load code-review --organize-by-sections --output context.md

# Results in:
# - context.md (main file with all sections)
# - context-focus.md (files section)
# - context-style.md (style section)
# - context-diff.md (diff section)
# - etc.
```

#### `--inspect-config`
Show the resolved configuration without processing content.

```bash
# Show what will be loaded
ace-bundle load project-base --inspect-config
```

#### `--embed-source`, `-e`
Embed the source document content in the output. This flag overrides the `embed_document_source` frontmatter setting.

```bash
# Embed source document in output
ace-bundle load prompt.md --embed-source

# Short form
ace-bundle load prompt.md -e

# Combine with other options
ace-bundle load prompt.md --embed-source --output stdio
```

**Use Cases:**
- **ace-prompt integration**: Enables ace-prompt to delegate all context aggregation to ace-bundle
- **Single-file output**: Get both context and source document in one output
- **CLI override**: Override frontmatter `embed_document_source: false` setting

**Behavior:**
- When enabled, includes the source document content in the output
- Overrides the `embed_document_source` frontmatter setting
- Works with all output formats (markdown, markdown-xml, yaml, json)
- Maintains backward compatibility (default: false)

**Example with ace-prompt:**
```bash
# ace-prompt can delegate to ace-bundle for context aggregation
# Create prompt file with frontmatter and context configuration
cat > prompt.md <<'EOF'
---
bundle:
  presets: [base]
---
My prompt content
EOF

# Load with embedded source
ace-bundle load prompt.md --embed-source --output stdio
```

### Processing Options

#### `--max-size`
Maximum output size in bytes.

```bash
# Limit output to 5MB
ace-bundle load project-base --max-size 5242880
```

#### `--timeout`
Command execution timeout in seconds.

```bash
# Set 60-second timeout
ace-bundle load project-base --timeout 60
```

## Advanced Usage

### Multiple Input Types

You can combine different input types:

```bash
# Combine preset with file configuration
ace-bundle load --preset base --file project-overrides.yml

# Mix preset with inline YAML
ace-bundle load project-base --context '{"files": ["extra-file.md"]}'
```

### Protocol-based Loading

Load contexts using protocols (requires ace-nav integration):

```bash
# Load workflow file
ace-bundle load wfi://code-review-workflow

# Load guide file
ace-bundle load guide://development-guide

# Load task file
ace-bundle load task://planning-session
```

### Auto-Detection

ace-bundle automatically detects input types:

```bash
# Preset name
ace-bundle load project-base

# File path (if file exists)
ace-bundle load config/project.yml

# Protocol URL
ace-bundle load wfi://my-workflow

# Inline YAML (if contains YAML syntax)
ace-bundle load '{"files": ["README.md"]}'
```

## Common Workflows

### Code Review Workflow

```bash
# Basic code review
ace-bundle load code-review

# Code review with security focus
ace-bundle load security-review

# Custom code review to specific file
ace-bundle load --preset base --context '{"files": ["src/auth/**/*.rb"]}' --format markdown-xml

# Save code review to file
ace-bundle load code-review --output review.md --format markdown-xml
```

### Pull Request Review Workflow

```bash
# Load PR diff for review (single PR)
ace-bundle load --context '{"pr": [123]}'

# Load multiple PRs at once
ace-bundle load --context '{"pr": [123, 456, 789]}'

# Load PR with qualified reference (cross-repo)
ace-bundle load --context '{"pr": ["owner/repo#123"]}'

# Combine PR with file patterns
ace-bundle load --context '{"pr": [123], "files": ["docs/**/*.md"]}'

# PR diff from GitHub URL
ace-bundle load --context '{"pr": ["https://github.com/owner/repo/pull/123"]}'
```

**Note:** The `pr` configuration accepts:
- Simple PR numbers: `123`
- Qualified references: `owner/repo#456`
- GitHub URLs: `https://github.com/owner/repo/pull/789`

Arrays are supported for reviewing multiple PRs in a single context.

### Project Setup Workflow

```bash
# Complete project context
ace-bundle load project-base

# Development setup
ace-bundle load development

# Testing setup
ace-bundle load testing

# Project overview in YAML format
ace-bundle load project-base --format yaml
```

### Documentation Workflow

```bash
# Documentation review
ace-bundle load documentation-review

# Generate project documentation context
ace-bundle load --preset docs --format markdown-xml --output docs-context.md

# Include workflow files
ace-bundle load wfi://documentation-workflow --format markdown
```

### Troubleshooting Workflow

```bash
# Check configuration without processing
ace-bundle load project-base --inspect-config

# Quick system check
ace-bundle load --preset system-check --format json

# Verbose output with larger timeout
ace-bundle load project-base --timeout 120 --max-size 20971520
```

## Output Formats

### Markdown Format (Default)

```bash
ace-bundle load project-base
```

Produces standard markdown with code blocks:

```markdown
## Files

### README.md
```markdown
# Project Title
...
```

### Commands

### pwd
```
/Users/username/project
```
```

### Markdown-XML Format

```bash
ace-bundle load project-base --format markdown-xml
```

Produces markdown with XML-style tags:

```markdown
## Files

<files>
  <file path="README.md" language="markdown">
# Project Title
...
  </file>
</files>

## Commands

<commands>
  <output command="pwd">
/Users/username/project
  </output>
</commands>
```

### YAML Format

```bash
ace-bundle load project-base --format yaml
```

Produces structured YAML output:

```yaml
preset_name: project-base
files:
  - path: README.md
    content: |
      # Project Title
      ...
metadata:
    generated_at: 2025-11-06T15:30:00Z
    total_files: 5
```

### JSON Format

```bash
ace-bundle load project-base --format json
```

Produces JSON output:

```json
{
  "preset_name": "project-base",
  "files": [
    {
      "path": "README.md",
      "content": "# Project Title\n..."
    }
  ],
  "metadata": {
    "generated_at": "2025-11-06T15:30:00Z",
    "total_files": 5
  }
}
```

## File Organization

### Section-Based Organization

When using section-based presets with `--organize-by-sections`:

```bash
ace-bundle load code-review --organize-by-sections --output review.md
```

Creates multiple files:
- `review.md` - Main file with all sections
- `review-focus.md` - Files under review
- `review-style.md` - Style guidelines
- `review-diff.md` - Recent changes
- `review-context.md` - System context

### Cache Organization

```bash
# Output to cache (default)
ace-bundle load project-base

# Cache files are organized by preset name:
# ~/.ace/cache/contexts/project-base-20251106-153000.md
```

## Environment Variables

### `ACE_BUNDLE_DIR`
Override default bundle directory.

```bash
export ACE_BUNDLE_DIR="/path/to/my/contexts"
ace-bundle load my-preset
```

### `ACE_CACHE_DIR`
Override default cache directory.

```bash
export ACE_CACHE_DIR="/path/to/my/cache"
ace-bundle load project-base --output cache
```

### `ACE_DEBUG`
Enable debug output.

```bash
export ACE_DEBUG=1
ace-bundle load project-base
```

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Configuration error
- `3` - File not found
- `4` - Permission denied
- `5` - Timeout exceeded
- `6` - Size limit exceeded

## Troubleshooting

### Common Issues

#### Preset Not Found
```bash
ace-bundle load unknown-preset
# Error: Preset 'unknown-preset' not found
```

**Solution**: Check available presets with `ace-bundle --help` or verify preset name.

#### File Not Found
```bash
ace-bundle load --file missing-config.yml
# Error: File not found: missing-config.yml
```

**Solution**: Verify file path and permissions.

#### Timeout Exceeded
```bash
ace-bundle load slow-preset
# Error: Command execution timeout exceeded
```

**Solution**: Increase timeout with `--timeout` option.

#### Size Limit Exceeded
```bash
ace-bundle load large-preset
# Error: Output size limit exceeded
```

**Solution**: Increase limit with `--max-size` or refine file patterns.

### Debug Mode

Enable debug output for troubleshooting:

```bash
export ACE_DEBUG=1
ace-bundle load project-base
```

Debug output includes:
- Configuration resolution steps
- File discovery and processing
- Command execution details
- Error stack traces

### Configuration Inspection

Use `--inspect-config` to understand what will be loaded:

```bash
ace-bundle load project-base --inspect-config
```

Shows:
- Resolved preset configuration
- File patterns that will be used
- Commands that will be executed
- Output format settings

## Integration Examples

### Git Hooks

```bash
#!/bin/sh
# pre-commit hook
echo "Generating pre-commit context..."
ace-bundle load code-review --format markdown-xml --output .git/context.md
```

### CI/CD Pipeline

```bash
#!/bin/bash
# CI pipeline step
echo "Generating build context..."
ace-bundle load ci-build --format json --output build-context.json

echo "Running security scan..."
ace-bundle load security-review --format markdown --output security-report.md
```

### Development Scripts

```bash
#!/bin/bash
# dev-setup.sh
echo "Setting up development environment..."

# Generate project context
ace-bundle load development --output dev-context.md

# Show system info
ace-bundle load system-check --format yaml
```

## Performance Tips

1. **Use Specific Patterns**: Avoid overly broad file patterns
2. **Set Appropriate Timeouts**: Configure based on command complexity
3. **Limit Output Size**: Use `--max-size` for large projects
4. **Cache Appropriately**: Use cache for frequently used contexts
5. **Choose Right Format**: Use `markdown` for speed, `markdown-xml` for structure

This usage guide covers all aspects of the ace-bundle command-line interface. Use these patterns and options to effectively integrate ace-bundle into your development workflow.
