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
| `--auto-fix` | `-f`, `--fix` | Deterministic auto-fix, then re-lint and report remaining issues |
| `--auto-fix-with-agent` | | Run `--auto-fix`, then launch agent for remaining issues |
| `--dry-run` | `-n` | Preview auto-fixes without modifying files (applies to auto-fix modes) |
| `--model=VALUE` | | Provider:model override for `--auto-fix-with-agent` |
| `--format` / `--no-format` | | Format markdown with guarded kramdown rewrite |
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

- `0` - success (including `--auto-fix --dry-run` and `--auto-fix-with-agent --dry-run`)
- `1` - lint/validation errors found
- `2` - fatal execution error

## Examples

```bash
# Auto-detect by extension
ace-lint README.md

# Deterministic auto-fix and re-lint (`--fix` is an alias)
ace-lint README.md lib/example.rb --auto-fix
ace-lint README.md lib/example.rb --fix

# Format markdown with configured line width (skips structural-risk rewrites)
ace-lint docs/getting-started.md --format --line-width 100

# Preview auto-fixes without writing files
ace-lint README.md --auto-fix --dry-run

# Deterministic auto-fix + agent escalation for remaining issues
ace-lint README.md --auto-fix-with-agent --model gemini:flash-latest

# Force YAML mode
ace-lint .ace/lint/config.yml --type yaml

# Ruby lint with explicit validators
ace-lint lib/**/*.rb --validators standardrb,rubocop

# Diagnose environment/config
ace-lint --doctor
ace-lint --doctor-verbose
```

`--format` is ignored (with warning) when `--auto-fix` or `--auto-fix-with-agent` is used.

## Example Output

**All files pass:**

```text
============================================================
Validated: 2 files
✓ All files passed

Reports: .ace-local/lint/8qmy35/
  ok.md        (2 files)
```

**Lint errors found:**

```text
============================================================
Validated: 1 file
✗ 1 failed
  1 error

Reports: .ace-local/lint/8qmy3i/
  pending.md   (1 issues)
```

**Doctor diagnostics:**

```text
Validators:
----------------------------------------

Configuration Files:
----------------------------------------

Pattern Groups:
----------------------------------------

Summary: Configuration looks healthy
         5 OK
```

## Runtime Help

```bash
ace-lint --help
```

## Test Commands

Use ACE test runners by layer:

- `ace-test ace-lint` for deterministic fast coverage (`test/fast`).
- `ace-test ace-lint feat` for deterministic feature coverage (`test/feat`) when that layer exists.
- `ace-test ace-lint all` for full deterministic package coverage.
- `ace-test-e2e ace-lint` for workflow-value E2E scenarios (`test/e2e`).
