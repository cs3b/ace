# ACE Tools Reference

## Available Tools

| Tool | Purpose |
|------|---------|
| **`ace-context`** | Load project context |
| **`ace-test`** | Run single package tests |
| **`ace-test-suite`** | Run all packages' tests at once |
| **`ace-taskflow`** | Comprehensive task and release management |
| **`ace-nav`** | Resource discovery and navigation |

## Usage Examples

*Each ace-* gem has its own detailed documentation in ace-*/docs/usage.md

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

### ace-taskflow

```sh
ace-taskflow task                              # Show next task
ace-taskflow task show 123                     # Show specific task details
ace-taskflow tasks --status pending            # List pending tasks
ace-taskflow tasks --stats                     # Show task statistics
ace-taskflow release                           # Show active release
ace-taskflow releases --stats                  # Show release statistics
ace-taskflow idea 'Add dark mode'              # Capture an idea
```

### ace-nav

```sh
ace-nav wfi://capture-idea                     # Find workflow by name
ace-nav 'wfi://*task*' --list                  # List matching workflows
ace-nav wfi://setup --content                  # Show workflow content
ace-nav --sources                              # Show available sources
```
