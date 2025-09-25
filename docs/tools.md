# ACE Tools Reference

| Tool | Purpose | Key Commands |
|------|---------|--------------|
| **ace-context** | Load project context | `ace-context project`, `ace-context --list` |
| **ace-test** | Run tests | `ace-test test/file.rb`, `ace-test test/file.rb:42` |
| **ace-test-suite** | Run all tests | `ace-test-suite` |
| **ace-taskflow** | Task management | `ace-taskflow task`, `ace-taskflow tasks --preset current` |
| **ace-nav** | Resource navigation | `ace-nav wfi://workflow-name`, `ace-nav --sources` |
| **ace-llm-query** | Query LLM providers | `ace-llm-query "prompt" -m gpt-4` |

## Quick Examples

```sh
# Task management
ace-taskflow task                       # Show next task
ace-taskflow tasks --tree               # Dependency tree view
ace-taskflow idea create "Feature" -gc  # Capture and commit idea

# Navigation and context
ace-context project --output stdio      # Load context to stdout
ace-nav 'wfi://*task*' --list          # Find workflow patterns

# Testing
ace-test test/foo_test.rb:42           # Test at specific line
```

*Full documentation in each ace-*/docs/usage.md*
