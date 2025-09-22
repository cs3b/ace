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
ace-context --preset project           # Load project context
ace-context --preset project --no-cache # Output to stdout (for piping)
```

### ace-test

```sh
ace-test test/foo_test.rb              # Test specific file
ace-test test/foo_test.rb:42           # Test at specific line
```

