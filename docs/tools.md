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
| **ace-search** | Search code/files | `ace-search "pattern"`, `ace-search "*.rb" --file` |
| **ace-review** | Code review | `ace-review --preset pr`, `ace-review --auto-execute` |

## Quick Examples

```sh
# Test execution
ace-test                                # Run all tests with progress
ace-test --fail-fast                    # Stop on first failure
ace-test atoms                          # Run only atom tests
ace-test test/file.rb:42                # Run test at specific line
ace-test --max-display 3                # Show only first 3 failures

# Task management
ace-taskflow task create "Add feature"              # Create task with positional title
ace-taskflow task create --title "Fix bug" --status draft --estimate 2h  # Create with metadata
ace-taskflow task 019                   # Find and show task by number
ace-taskflow task show 019              # Show task details
ace-taskflow task done 019              # Mark complete & move to done/
ace-taskflow tasks all                  # All tasks in current release

# Git commits
ace-git-commit                          # Generate commit for all changes
ace-git-commit --staged                 # Commit only staged files

# Search
ace-search "TODO"                       # Auto-detect: search content
ace-search "*.rb" --file                # Find Ruby files
ace-search "class.*Manager" --content   # Regex content search
ace-search "config" --staged            # Search only staged files

# Code review
ace-review --preset pr                  # Review PR changes
ace-review --preset security --auto-execute  # Security review with LLM
ace-review --subject 'diffs: ["HEAD~5..HEAD"]'  # Review specific range
ace-review --list-presets               # Show available presets

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
