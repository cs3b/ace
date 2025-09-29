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
- `ace-framework diff` - Compare your configs with the examples
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

## Examples

```bash
# List available gems
ace-framework list

# Initialize all configurations
ace-framework init

# Initialize specific gem
ace-framework init ace-taskflow

# Preview what would be done
ace-framework init --dry-run

# Compare configurations
ace-framework diff --one-line
```