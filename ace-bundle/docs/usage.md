# ace-bundle CLI Reference

Complete command reference for `ace-bundle`.

## Installation

```bash
gem install ace-bundle
```

## Synopsis

```
ace-bundle [INPUT] [OPTIONS]
```

INPUT can be a preset name, file path, or protocol URL:
- Preset: `project`, `base`, `code-review`
- File: `./config.yml`, `/path/to/context.md`
- Protocol: `wfi://task/plan`, `guide://workflow-context-embedding`

## Options

### Input Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--preset` | `-p` | Load from preset (repeatable for merging) |
| `--presets` | | Load multiple presets (comma-separated) |
| `--file` | `-f` | Load from file (repeatable) |

### Output Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--output` | `-o` | Output mode: stdio, cache, or file path |
| `--format` | | Output format: markdown, yaml, xml, markdown-xml, json |
| `--embed-source` | `-e` | Embed source document in output |

### Compression Options

| Option | Description |
|--------|-------------|
| `--compressor` | Enable/disable: on, off |
| `--compressor-mode` | Engine: exact, agent (default: exact) |
| `--compressor-source-scope` | Source handling: off, per-source, merged |

### Resource Limits

| Option | Description |
|--------|-------------|
| `--max-size` | Maximum file size in bytes |
| `--timeout` | Command timeout in seconds |

### Informational

| Option | Description |
|--------|-------------|
| `--list` | List available context presets |
| `--inspect-config` | Show merged configuration without loading |
| `--version` | Show version |

### Global Options

| Flag | Description |
|------|-------------|
| `-q`, `--quiet` | Suppress non-essential output |
| `-v`, `--verbose` | Show verbose output |
| `-d`, `--debug` | Show debug output |
| `--help` | Show help |

## Examples

```bash
# Load project context (default preset)
ace-bundle project

# Lightweight onboarding context
ace-bundle project-base

# List available presets
ace-bundle --list

# Load workflow instruction via protocol
ace-bundle wfi://task/plan

# Load guide via protocol
ace-bundle guide://workflow-context-embedding

# Merge multiple presets
ace-bundle -p base -p development

# Load from file
ace-bundle -f path/to/custom.yml

# Print to stdout instead of caching
ace-bundle project --output stdio

# Inspect resolved configuration without loading
ace-bundle project --inspect-config

# Enable compression
ace-bundle project --compressor on --compressor-mode exact
```

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-bundle project` | Load full project context |
| `ace-bundle project-base` | Load lightweight onboarding context |
| `ace-bundle --list` | List available presets |
| `ace-bundle wfi://task/plan` | Load workflow via protocol |
| `ace-bundle -p base -p custom` | Merge multiple presets |
| `ace-bundle --inspect-config` | Show resolved config |

## Runtime Help

```bash
ace-bundle --help
```
