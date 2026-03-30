---
doc-type: user
title: Ace Framework Configuration
purpose: Documentation for ace-support-core/docs/config.md
ace-docs:
  last-updated: 2026-01-17
  last-checked: 2026-03-21
---

# Ace Framework Configuration

The `ace-framework` command (from the `ace-core` gem) manages centralized configuration for all ace-* gems.

## Configuration File

Create `.ace/core/settings.yml`:

```yaml
# General settings for ace-core
verbose: false
global: false
```

## Available Commands

- `ace-framework init [GEM]` - Initialize configuration for specific gem or all
- `ace-framework diff [GEM]` - Compare configs with examples for specific gem or all
- `ace-framework list` - List available ace-* gems with example configs
- `ace-framework version` - Show version information

## Options

### For `init` command:
- `--force` - Overwrite existing configuration files
- `--dry-run` - Preview what would be done without making changes
- `--global` - Use ~/.ace instead of ./.ace for configuration
- `--verbose` - Show detailed output during operations

### For `diff` command:
- `--one-line` - One-line summary per file
- `--file PATH` - Compare specific file
- `--global` - Compare global configs
- `--local` - Compare local configs (default)

### For `list` command:
- `--verbose` - Show detailed information including paths and file counts

## First Time Setup

Run `ace-framework init` to set up all ace-* gem configurations at once.
For new projects, this generates starter bundle presets:

- `.ace/bundle/presets/project.md`
- `.ace/bundle/presets/project-base.md`

These files are intentionally generic scaffolding and should be customized for your project.

## Examples

```bash
# List available gems
ace-framework list

# Initialize all configurations
ace-framework init

# Initialize specific gem (both formats work)
ace-framework init ace-task
ace-framework init task

# Preview what would be done
ace-framework init --dry-run

# Compare all configurations
ace-framework diff --one-line

# Compare specific gem (both formats work)
ace-framework diff ace-bundle
ace-framework diff bundle --one-line

# Load generated project context
ace-bundle project
```
