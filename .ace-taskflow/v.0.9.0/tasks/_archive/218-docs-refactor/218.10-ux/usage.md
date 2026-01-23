# Typography Validation Usage Guide

## Overview

Typography validation in ace-lint detects problematic typography characters in markdown files:
- Em-dashes (U+2014) - should use spaced hyphen instead
- Smart/curly quotes - should use straight quotes instead

This enforces the [Markdown Style Guide](guide://markdown-style) for consistent terminal-friendly documentation.

## Command Types

### CLI Commands (Terminal)

```bash
# Basic typography check (included in standard markdown linting)
ace-lint docs/*.md

# Check all markdown files in docs/
ace-lint docs/

# Single file check
ace-lint docs/vision.md
```

### Claude Code Commands (Chat)

```
/ace:lint docs/*.md
```

## Configuration

Typography validation is configured in `.ace/lint/markdown.yml` (or uses defaults from `.ace-defaults/lint/markdown.yml`).

### Default Configuration

```yaml
# .ace-defaults/lint/markdown.yml
typography:
  em_dash: warn      # error | warn | off
  smart_quotes: warn # error | warn | off
```

### Configuration Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `typography.em_dash` | `error`, `warn`, `off` | `warn` | Severity for em-dash detection |
| `typography.smart_quotes` | `error`, `warn`, `off` | `warn` | Severity for smart quote detection |

### Project Override Example

Create `.ace/lint/markdown.yml` in your project root:

```yaml
# .ace/lint/markdown.yml
typography:
  em_dash: error      # Treat em-dashes as errors (fail lint)
  smart_quotes: warn  # Keep smart quotes as warnings only
```

## Usage Scenarios

### Scenario 1: Standard Documentation Check

**Goal:** Check all documentation files for typography issues.

```bash
ace-lint docs/
```

**Expected Output:**

```
docs/vision.md
  Line 42: Em-dash detected. Use ' - ' (spaced hyphen) instead. [typography/em_dash]
  Line 78: Smart quote detected. Use straight quotes instead. [typography/smart_quotes]

docs/architecture.md
  (no issues)

Summary: 2 warnings in 1/2 files
```

### Scenario 2: CI Pipeline Integration

**Goal:** Fail CI build on typography issues.

Configure `.ace/lint/markdown.yml`:

```yaml
typography:
  em_dash: error
  smart_quotes: error
```

Then in CI:

```bash
ace-lint docs/ && echo "Lint passed" || exit 1
```

### Scenario 3: Disable Typography Checks

**Goal:** Disable typography validation entirely for a project.

```yaml
# .ace/lint/markdown.yml
typography:
  em_dash: off
  smart_quotes: off
```

### Scenario 4: Check Single File Before Commit

**Goal:** Verify a specific file has no typography issues.

```bash
ace-lint docs/vision.md
```

**Expected Output (clean):**

```
docs/vision.md
  (no issues)

Summary: 0 warnings, 0 errors
```

## Detected Characters

### Em-Dashes

| Character | Unicode | Example |
|-----------|---------|---------|
| `—` | U+2014 | The toolkit—designed for AI agents—provides |

**Correction:** Replace with ` - ` (space-hyphen-space)

```
Before: The toolkit—designed for AI agents—provides
After:  The toolkit - designed for AI agents - provides
```

### Smart Quotes

| Character | Unicode | Name |
|-----------|---------|------|
| `"` | U+201C | Left double quote |
| `"` | U+201D | Right double quote |
| `'` | U+2018 | Left single quote |
| `'` | U+2019 | Right single quote |

**Correction:** Replace with straight quotes `"` (U+0022) and `'` (U+0027)

```
Before: "Smart quotes" cause issues
After:  "Straight quotes" work everywhere
```

## Tips and Best Practices

1. **Run before commits:** Include `ace-lint docs/` in your pre-commit workflow
2. **Configure severity appropriately:** Use `warn` for existing projects, `error` for new projects
3. **Check in CI:** Add typography checks to your CI pipeline for automated enforcement
4. **Editor settings:** Configure your editor to use straight quotes by default

## Troubleshooting

### Typography warnings on copy-pasted content

Many word processors and websites use smart quotes by default. When pasting content:
1. Use "Paste as Plain Text" option
2. Or run ace-lint to detect issues, then fix manually

### False positives in code blocks

Typography checks skip content inside fenced code blocks (triple backticks). If you see false positives, ensure your code blocks are properly fenced.

## Related Documentation

- [Markdown Style Guide](guide://markdown-style) - Typography standards
- [ace-lint README](../ace-lint/README.md) - Full linting documentation
