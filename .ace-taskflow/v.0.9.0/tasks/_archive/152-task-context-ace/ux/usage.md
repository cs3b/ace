# ace-context Auto-Format Output Usage

## Overview

ace-context now intelligently determines output format based on content size. Short outputs display directly in the terminal for immediate use, while large outputs save to a file and return the path to avoid overwhelming the terminal.

## Auto-Format Behavior

When no explicit `--output` mode is specified:

| Content Size | Behavior |
|-------------|----------|
| < 500 lines | Displays content directly to stdout |
| >= 500 lines | Saves to cache file, displays file path |

## Command Examples

### Scenario 1: Small Context (Auto-Displays Content)

```bash
# Load a minimal preset (typically < 500 lines)
ace-context minimal

# Output: Context content displayed directly
# ---
# description: Minimal context
# context:
#   files:
#     - README.md
# ---
#
# # README.md content here...
```

### Scenario 2: Large Context (Auto-Saves to File)

```bash
# Load project preset (typically >= 500 lines)
ace-context project

# Output:
# Context saved (2102 lines, 79.72 KB), output file:
# /path/to/.cache/ace-context/project.md
```

### Scenario 3: Force Content Display

```bash
# Override auto-format to always display content
ace-context project --output stdio

# Output: Full content displayed (may be large)
```

### Scenario 4: Force File Output

```bash
# Override auto-format to always save to file
ace-context minimal --output cache

# Output:
# Context saved (45 lines, 1.2 KB), output file:
# /path/to/.cache/ace-context/minimal.md
```

### Scenario 5: Save to Specific File

```bash
# Save to a specific path (overrides auto-format)
ace-context project --output ./my-context.md

# Output:
# Context saved (2102 lines, 79.72 KB), output file:
# ./my-context.md
```

### Scenario 6: Protocol with Auto-Format

```bash
# Protocol URLs follow same auto-format logic
ace-context wfi://load-context

# If workflow is short: displays content
# If workflow is long: displays file path
```

## Command Reference

### Output Mode Options

| Option | Description |
|--------|-------------|
| (none) | Auto-format: content < 500 lines → display, >= 500 → file |
| `--output stdio` | Always display content to stdout |
| `--output cache` | Always save to `.cache/ace-context/` |
| `--output PATH` | Save to specific file path |

### Configuration

The auto-format threshold is configurable in `.ace/context/config.yml`:

```yaml
context:
  # Line threshold for auto-format (default: 500)
  auto_format_threshold: 500
```

## Transition Notes

### Previous Behavior

Before this change, ace-context used preset-defined defaults:
- Presets could specify `params.output: cache` or `params.output: stdio`
- If not specified, defaulted to `stdio` (always display)

### New Behavior

- No explicit output mode → auto-format based on line count
- Explicit `--output` flag → honors the specified mode
- Preset-defined `params.output` → honors preset default (considered explicit)

### Compatibility

Existing workflows using `--output` flags or preset-defined output modes continue to work unchanged. Only workflows that relied on the implicit `stdio` default will experience changed behavior (which is the desired improvement).

## Tips

1. **Quick inspection**: For large contexts, use auto-format to get the file path, then use your editor or `Read` tool to view it
2. **Pipeline usage**: If piping to another command, use `--output stdio` to ensure content is output
3. **Debugging**: Use `--debug` flag to see which output mode was selected

## Error Handling

| Error | Behavior |
|-------|----------|
| Invalid preset | Error message displayed, exit 1 |
| Format parsing error | Falls back to file output for safety |
| File write error | Error displayed to stderr, exit 1 |
