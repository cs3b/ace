---
doc-type: user
title: ace-lint CLI Reference
purpose: Documentation for ace-lint/docs/usage.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-lint CLI Reference

Complete command reference for `ace-lint`.

## Synopsis

```bash
ace-lint [FILES] [OPTIONS]
```

## File Type Auto-Detection

By default, file types are detected from extensions:

- `.md`, `.markdown` -> markdown
- `.yml`, `.yaml` -> yaml
- `.rb`, `.rake`, `.gemspec` -> ruby
- any text file with YAML frontmatter -> frontmatter validation

## Arguments

| Argument | Description |
|----------|-------------|
| `[FILES]` | One or more files to lint |

## Options

### Linting and Formatting

| Option | Alias | Description |
|--------|-------|-------------|
| `--fix` / `--no-fix` | `-f` | Auto-fix/format files |
| `--format` / `--no-format` | | Format files with kramdown |
| `--type=VALUE` | `-t` | Force file type (`markdown`, `yaml`, `ruby`, `frontmatter`) |
| `--line-width=VALUE` | | Line width for formatting (default: `120`) |
| `--validators=VALUE` | | Comma-separated validators (for example `standardrb,rubocop`) |
| `--no-report` / `--report` | | Disable/enable JSON report generation |

### Diagnostics and Output

| Option | Alias | Description |
|--------|-------|-------------|
| `--doctor` / `--no-doctor` | | Diagnose lint config and validator health |
| `--doctor-verbose` / `--no-doctor-verbose` | | Verbose diagnostics output |
| `--quiet` / `--no-quiet` | `-q` | Suppress non-essential output |
| `--verbose` / `--no-verbose` | `-v` | Show verbose output |
| `--debug` / `--no-debug` | `-d` | Show debug output |
| `--version` / `--no-version` | | Show version information |
| `--help` | `-h` | Show help |

## Exit Codes

- `0` - success
- `1` - lint/validation errors found
- `2` - fatal execution error

## Examples

```bash
# Auto-detect by extension
ace-lint README.md

# Auto-fix markdown or Ruby style
ace-lint README.md lib/example.rb --fix

# Format markdown with configured line width
ace-lint docs/getting-started.md --format --line-width 100

# Force YAML mode
ace-lint .ace/lint/config.yml --type yaml

# Ruby lint with explicit validators
ace-lint lib/**/*.rb --validators standardrb,rubocop

# Diagnose environment/config
ace-lint --doctor
ace-lint --doctor-verbose
```

## Runtime Help

```bash
ace-lint --help
```
