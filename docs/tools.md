# ACE Tools Reference

| Tool | Purpose | Key Commands |
|------|---------|--------------|
| **ace-context** | Load project context | `ace-context project`, `ace-context --list` |
| **ace-test** | Run tests | `ace-test`, `ace-test --fail-fast`, `ace-test atoms` |
| **ace-test-suite** | Run all tests | `ace-test-suite` |
| **ace-taskflow** | Task management | `ace-taskflow task show 018`, `ace-taskflow tasks all` |
| **ace-nav** | Resource navigation | `ace-nav wfi://workflow-name`, `ace-nav --sources` |
| **ace-llm-query** | Query LLM providers | `ace-llm-query "prompt" -m gpt-4` |
| **ace-git-commit** | Generate commits | `ace-git-commit`, `ace-git-commit --staged` |

## Quick Examples

```sh
# Test execution
ace-test                                # Run all tests with progress
ace-test --fail-fast                    # Stop on first failure
ace-test atoms                          # Run only atom tests
ace-test test/file.rb:42                # Run test at specific line
ace-test --max-display 3                # Show only first 3 failures

# Task management
ace-taskflow task 019                   # Find and show task by number
ace-taskflow task v.0.9.0+047           # Find by full task ID
ace-taskflow task show 019              # Show task details
ace-taskflow task done 019              # Mark complete & move to done/
ace-taskflow tasks all                  # All tasks in current release
ace-taskflow tasks all-releases         # All tasks across all releases

# Git commits
ace-git-commit                          # Generate commit for all changes
ace-git-commit --staged                 # Commit only staged files

# Navigation and context
ace-context project --output stdio      # Load context to stdout
ace-nav 'wfi://*task*' --list          # Find workflow patterns
```

## Task Lookup

To find tasks, use the `ace-taskflow task` command:

```sh
ace-taskflow task 047                   # Find task by number
ace-taskflow task v.0.9.0+047           # Find by full task ID
```

**Note**: The `task://` protocol was prototyped in ace-nav but was never implemented. Use `ace-taskflow task` commands instead.

---

*Full documentation in each ace-*/docs/usage.md*
