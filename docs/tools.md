---
update:
  update_frequency: weekly
  max_lines: 150
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2025-12-24'
---

# ACE Tools Reference

| Tool | Purpose | Key Commands |
|------|---------|--------------|
| **ace-context** | Load project context | `ace-context project`, `ace-context --list`, `ace-context --embed-source` |
| **ace-docs** | Documentation management | `ace-docs status`, `ace-docs update file.md` |
| **ace-git** | Repository context, PR activity, diff | `ace-git status`, `ace-git status --no-pr`, `ace-git diff` |
| **ace-git-commit** | Generate commits | `ace-git-commit`, `ace-git-commit --staged`, `ace-git-commit --path "src/**"` |
| **ace-git-secrets** | Detect and remove tokens | `ace-git-secrets scan`, `ace-git-secrets revoke`, `ace-git-secrets rewrite-history` |
| **ace-lint** | Code quality linting | `ace-lint file.md`, `ace-lint file.md --fix` |
| **ace-llm-query** | Query LLM providers | `ace-llm-query "prompt" -m gpt-4` |
| **ace-nav** | Resource navigation | `ace-nav wfi://workflow-name`, `ace-nav --sources` |
| **ace-review** | Code review | `ace-review --preset pr`, `ace-review --task 121`, `ace-review --auto-execute` |
| **ace-search** | Search code/files | `ace-search "pattern"`, `ace-search "*.rb" --file` |
| **ace-taskflow** | Task management | `ace-taskflow task 018`, `ace-taskflow tasks all` |
| **ace-git-worktree** | Worktree management | `ace-git-worktree create --task 081`, `ace-git-worktree create --pr 26`, `ace-git-worktree list`, `ace-git-worktree switch 081` |
| **ace-prompt** | Prompt workspace | `ace-prompt`, `ace-prompt --enhance`, `ace-prompt --task 121` |
| **ace-test** | Run tests | `ace-test`, `ace-test atoms`, `ace-test ace-context`, `ace-test ace-nav atoms` |

## Quick Examples

```sh
# Task management
ace-taskflow task create "Add feature"              # Create task with positional title
ace-taskflow task create --title "Fix bug" --status draft --estimate 2h  # Create with metadata
ace-taskflow task 019                   # Find and show task by number/reference
ace-taskflow task done 019              # Mark complete & move to done/
ace-taskflow tasks all                  # All tasks in current release
ace-taskflow task move 139 --child-of self    # Convert task to orchestrator
ace-taskflow task move 156 --child-of 139     # Demote task to subtask

# Taskflow status
ace-taskflow status                     # Show taskflow status with activity awareness
ace-taskflow status --json              # Output as JSON
# Shows: Release (name, count, codename), Current task, Task Activity (Recently Done, In Progress, Up Next)

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
ace-git-commit --path "src/**"          # Commit only matching paths

# Repository context
ace-git status                          # Full context (branch, status, PR, activity)
ace-git status --no-pr                  # Skip PR lookups (faster)
ace-git status --commits 5              # Show 5 recent commits (default: 3)
ace-git status --commits 0              # Disable recent commits
ace-git status --json                   # JSON output
ace-git branch                          # Branch name with tracking status
ace-git diff HEAD~5..HEAD               # Generate diff between refs
ace-git diff --since "7d"               # Diff from time reference

# Security scanning
ace-git-secrets scan                    # Scan git history for tokens
ace-git-secrets scan --since "1 week ago"  # Scan recent commits only
ace-git-secrets revoke                  # Revoke detected tokens via API
ace-git-secrets revoke --scan-file scan.json  # Revoke from saved scan
ace-git-secrets rewrite-history --dry-run  # Preview history rewrite
ace-git-secrets check-release --strict  # Pre-release security gate

# Search
ace-search "TODO"                       # Auto-detect: search content
ace-search "*.rb" --file                # Find Ruby files
ace-search "class.*Manager" --content   # Regex content search
ace-search "config" --staged            # Search only staged files

# Code review
ace-review --preset pr                  # Review PR changes
ace-review --preset pr --task 121       # Save review to task directory
ace-review --preset security --auto-execute  # Security review with LLM
ace-review --subject 'diff: {ranges: ["origin/main...HEAD"]}'  # Review vs main branch

# Navigation and context
ace-context project --output stdio      # Load context to stdout
ace-context project --embed-source      # Include source document inline
ace-nav 'wfi://*task*' --list          # Find workflow patterns

# Test execution
ace-test                                # Run all tests with progress
ace-test --fail-fast                    # Stop on first failure
ace-test atoms                          # Run only atom tests
ace-test ace-context                    # Run all tests in ace-context package
ace-test ace-nav atoms                  # Run atom tests in ace-nav package
ace-test ace-lint --profile 10          # Profile slowest tests in ace-lint

ace-test test/atoms/foo_test.rb         # Single file (from inside package)
ace-test ace-search/test/atoms/foo_test.rb  # Single file (from outside with package prefix)
ace-test ace-nav/test/foo_test.rb:42    # Single test at line number

# Prompt management
ace-prompt                              # Process and archive current prompt
ace-prompt --enhance                    # Enhance prompt via LLM before output
ace-prompt --task 121                   # Use task-specific prompts
ace-prompt setup --task 117             # Initialize prompt in task directory
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
