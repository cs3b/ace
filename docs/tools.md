# ACE Tools Reference

| Tool | Purpose | Key Commands |
|------|---------|--------------|
| **ace-context** | Load project context | `ace-context project`, `ace-context --list` |
| **ace-test** | Run tests | `ace-test test/file.rb`, `ace-test test/file.rb:42` |
| **ace-test-suite** | Run all tests | `ace-test-suite` |
| **ace-taskflow** | Task management | `ace-taskflow task`, `ace-taskflow tasks --preset current` |
| **ace-nav** | Resource navigation | `ace-nav wfi://workflow-name`, `ace-nav --sources` |
| **ace-llm-query** | Query LLM providers | `ace-llm-query "prompt" -m gpt-4` |
| **ace-git-commit** | Generate commits | `ace-git-commit`, `ace-git-commit --staged` |

## Quick Examples

```sh
# Task management
ace-taskflow task done 019              # Mark complete & move to done/
ace-taskflow idea reschedule "feat" --add-next  # Reschedule idea
ace-taskflow release reschedule v.0.9.0 --status active

# Git commits
ace-git-commit                          # Generate commit for all changes
ace-git-commit --staged                 # Commit only staged files

# Navigation and context
ace-context project --output stdio      # Load context to stdout
ace-nav 'wfi://*task*' --list          # Find workflow patterns
```

*Full documentation in each ace-*/docs/usage.md*
