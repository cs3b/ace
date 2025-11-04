---
update:
  update_frequency: weekly
  max_lines: 150
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2025-10-14'
---

# ACE Tools Reference

| Tool | Purpose | Key Commands |
|------|---------|--------------|
| **ace-context** | Load project context | `ace-context project`, `ace-context --list` |
| **ace-docs** | Documentation management | `ace-docs status`, `ace-docs update file.md` |
| **ace-git-commit** | Generate commits | `ace-git-commit`, `ace-git-commit --staged` |
| **ace-lint** | Code quality linting | `ace-lint file.md`, `ace-lint file.md --fix` |
| **ace-llm-query** | Query LLM providers | `ace-llm-query "prompt" -m gpt-4` |
| **ace-nav** | Resource navigation | `ace-nav wfi://workflow-name`, `ace-nav --sources` |
| **ace-review** | Code review | `ace-review --preset pr`, `ace-review --auto-execute` |
| **ace-search** | Search code/files | `ace-search "pattern"`, `ace-search "*.rb" --file` |
| **ace-taskflow** | Task management | `ace-taskflow task 018`, `ace-taskflow tasks all` |
| **ace-git-worktree** | Worktree management | `ace-git-worktree create --task 081`, `ace-git-worktree list`, `ace-git-worktree switch 081` |
| **ace-test** | Run tests | `ace-test`, `ace-test --fail-fast`, `ace-test atoms` |

## Quick Examples

```sh
# Task management
ace-taskflow task create "Add feature"              # Create task with positional title
ace-taskflow task create --title "Fix bug" --status draft --estimate 2h  # Create with metadata
ace-taskflow task 019                   # Find and show task by number/reference
ace-taskflow task show 019              # Show task details
ace-taskflow task done 019              # Mark complete & move to done/
ace-taskflow tasks all                  # All tasks in current release

# Documentation management
ace-docs status --needs-update          # Check documents needing updates
ace-docs update file.md --set last-updated=today  # Update document metadata
ace-docs diff --needs-update            # Analyze changes for stale docs
ace-docs validate file.md               # Validate document structure

# Code quality
ace-lint file.md                        # Lint markdown file
ace-lint file.md --fix                  # Auto-fix markdown issues
ace-lint "**/*.md" --type markdown      # Lint all markdown files

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
ace-review --subject 'diff: {ranges: ["origin/main...HEAD"]}'  # Review vs main branch

# Navigation and context
ace-context project --output stdio      # Load context to stdout
ace-nav 'wfi://*task*' --list          # Find workflow patterns

# Test execution
ace-test                                # Run all tests with progress
ace-test --fail-fast                    # Stop on first failure
ace-test atoms                          # Run only atom tests
```

## Task Lookup

**Always use `ace-taskflow task` for finding tasks** - it handles all reference formats:

```sh
ace-taskflow task 047                   # Find by number
ace-taskflow task task.047              # Find with task prefix
ace-taskflow task v.0.9.0+047           # Find by full task ID
```

The command automatically locates tasks across releases and supports partial matching.

---

*Full documentation in each ace-*/docs/usage.md*
