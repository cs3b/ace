# Ace Core Configuration

The `ace-core` gem manages centralized configuration for all ace-* gems.

## Configuration File

Create `.ace/core/settings.yml`:

```yaml
# General settings for ace-core
verbose: false
global: false
```

## Available Commands

- `ace-core init [GEM]` - Initialize configuration for specific gem or all
- `ace-core diff` - Compare your configs with the examples

## Options

- `--force` - Overwrite existing configuration files
- `--dry-run` - Preview what would be done without making changes
- `--global` - Use ~/.ace instead of ./.ace for configuration
- `--verbose` - Show detailed output during operations

## First Time Setup

Run `ace-core init` to set up all ace-* gem configurations at once.