# ACE Tools Reference

## Available Tools

| Tool | Purpose |
|------|---------|
| **`ace-context`** | Load project context |
| **`ace-test`** | Run single package tests |
| **`ace-test-suite`** | Run all packages' tests at once |

## Usage Examples

| *Each ace-* gem has its own detailed documentation in ace-*/docs/usage.md

### ace-context

```sh
ace-context project                    # Load project preset
ace-context project --output stdio     # Output to stdout (for piping)
ace-context project --output cache     # Save to cache directory
ace-context project --output file.md   # Save to specific file
ace-context --list                     # List available presets
```

### ace-test

```sh
ace-test test/foo_test.rb              # Test specific file
ace-test test/foo_test.rb:42           # Test at specific line
```

