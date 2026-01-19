---
update:
  update_frequency: weekly
  max_lines: 200
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2026-01-19'
---

# ACE Command Reference

This document provides a comprehensive reference for all ACE commands, clearly distinguishing between the two command types.

## Command Types Overview

ACE provides two distinct types of commands:

| Type | Environment | Prefix | Purpose |
|------|-------------|--------|---------|
| **Claude Commands** | Claude Code chat | `/ace:` | AI-assisted workflows with full agent context |
| **CLI Tools** | Terminal (bash/fish) | `ace-` | Deterministic operations for direct execution |

### When to Use Each

- **Claude Commands**: When you want AI assistance, context-aware suggestions, or multi-step workflows
- **CLI Tools**: When you need deterministic, scriptable operations or quick lookups

---

## Claude Commands (Slash Commands)

Run these by typing directly in Claude Code conversation.

### Task Management

| Command | Purpose |
|---------|---------|
| `/ace:work-on-task [id]` | Work on a task with full agent context and guidance |
| `/ace:work-on-tasks` | Work on multiple tasks sequentially |
| `/ace:work-on-subtasks` | Work on subtasks of an orchestrator task |
| `/ace:draft-task` | Draft a new task specification |
| `/ace:draft-tasks` | Draft multiple tasks from ideas |
| `/ace:plan-task [id]` | Create implementation plan for a task |
| `/ace:plan-tasks` | Plan multiple draft tasks |
| `/ace:review-task [id]` | Review a completed task |
| `/ace:review-tasks` | Review multiple tasks |
| `/ace:create-task` | Create complete task from plan |
| `/ace:replan-cascade-task` | Replan a cascade/orchestrator task |

### Code Review

| Command | Purpose |
|---------|---------|
| `/ace:review` | Review code changes |
| `/ace:review-pr [pr-number]` | Review a pull request with AI analysis |
| `/ace:synthesize-reviews` | Synthesize multiple review findings |

### Git Operations

| Command | Purpose |
|---------|---------|
| `/ace:commit` | Generate intelligent commit with LLM assistance |
| `/ace:create-pr` | Create a pull request |
| `/ace:rebase` | Rebase with CHANGELOG preservation |
| `/ace:squash-pr` | Squash commits by version |

### Release Management

| Command | Purpose |
|---------|---------|
| `/ace:draft-release` | Draft a release with changelog |
| `/ace:publish-release` | Publish a release |
| `/ace:update-roadmap` | Update project roadmap |

### Documentation

| Command | Purpose |
|---------|---------|
| `/ace:update-docs` | Update documentation with ace-docs workflow |
| `/ace:update-usage` | Update usage documentation |
| `/ace:create-adr` | Create Architecture Decision Record |
| `/ace:maintain-adrs` | Maintain ADR lifecycle |

### Ideas and Retrospectives

| Command | Purpose |
|---------|---------|
| `/ace:capture-idea` | Capture a new idea |
| `/ace:prioritize-ideas` | Prioritize and align ideas |
| `/ace:capture-features` | Capture application features |
| `/ace:create-retro` | Create a retrospective |
| `/ace:synthesize-retros` | Synthesize retrospective findings |

### Testing and Quality

| Command | Purpose |
|---------|---------|
| `/ace:fix-tests` | Fix failing automated tests systematically |
| `/ace:create-test-cases` | Generate structured test cases |
| `/ace:improve-code-coverage` | Analyze and improve test coverage |
| `/ace:analyze-bug` | Analyze bugs for root cause |
| `/ace:fix-bug` | Execute bug fix plan |
| `/ace:run-e2e-test [package] [test-id]` | Execute E2E test scenarios |

### Context and Navigation

| Command | Purpose |
|---------|---------|
| `/ace:bundle [preset]` | Load bundle with AI assistance |
| `/ace:prompt` | Run ace-prompt and follow instructions |
| `/ace:review-questions` | Review open questions |
| `/ace:document-unplanned` | Document unplanned work |

---

## CLI Tools (Terminal Commands)

Run these from your terminal (bash/fish shell).

### Core Tools

```bash
# Context loading
ace-bundle project              # Load project context
ace-bundle --list               # List available presets
ace-bundle wfi://bundle   # Load via protocol

# Navigation
ace-bundle wfi://work-on-task       # Load workflow content
ace-nav --sources                # List available sources
```

### Task Management

```bash
# View tasks
ace-taskflow task 148            # Show task details
ace-taskflow tasks --current     # List current tasks
ace-taskflow tasks all           # All tasks in release
ace-taskflow status              # Taskflow status overview

# Create/modify tasks
ace-taskflow task create "Title" # Create new task
ace-taskflow task done 148       # Mark task complete
ace-taskflow task move 156 --child-of 139  # Move task
```

### Git Operations

```bash
# Repository context
ace-git status                   # Full context with PR info
ace-git status --no-pr           # Skip PR lookups
ace-git branch                   # Branch info
ace-git diff HEAD~5..HEAD        # Diff between refs

# Commits
ace-git-commit                   # Generate commit
ace-git-commit --staged          # Staged files only
ace-git-commit --path "src/**"   # Specific paths

# Worktrees
ace-git-worktree create --task 81    # Create for task
ace-git-worktree list                # List worktrees
ace-git-worktree switch 81           # Switch to task

# Security
ace-git-secrets scan             # Scan for tokens
ace-git-secrets revoke           # Revoke detected tokens
```

### Code Review

```bash
ace-review --preset pr           # Review PR changes
ace-review --task 121            # Save to task directory
ace-review --auto-execute        # With LLM execution
```

### Documentation

```bash
ace-docs status                  # Documentation status
ace-docs status --needs-update   # Files needing update
ace-docs update file.md          # Update document
ace-docs validate file.md        # Validate structure
```

### Code Quality

```bash
ace-lint file.md                 # Lint markdown
ace-lint file.md --fix           # Auto-fix issues
ace-lint "**/*.md" --type markdown
ace-lint lib/**/*.rb --validators rubocop              # Run specific validator
ace-lint lib/**/*.rb --validators standardrb,rubocop   # Run multiple validators
ace-lint doctor                                         # Check configuration health
```

### Search

```bash
ace-search "pattern"             # Content search
ace-search "*.rb" --file         # File search
ace-search "TODO" --staged       # Staged files only
```

### Testing

```bash
ace-test                         # All tests in package
ace-test atoms                   # Layer-specific tests
ace-test ace-bundle             # Package tests
ace-test --fail-fast             # Stop on failure
ace-test-suite                   # Full monorepo suite
```

### Prompts

```bash
ace-prompt                       # Process prompt
ace-prompt --enhance             # Enhance via LLM
ace-prompt --task 121            # Task-specific
```

---

## Quick Reference Card

### Claude Commands (Chat)

```
/ace:work-on-task 148    # Work on task
/ace:commit              # Smart commit
/ace:review-pr 90        # Review PR
/ace:draft-task          # New task
```

### CLI Tools (Terminal)

```bash
ace-taskflow task 148    # View task
ace-git-commit           # Generate commit
ace-review --preset pr   # Code review
ace-test atoms           # Run tests
```

---

*See also: [tools.md](tools.md) for detailed CLI tool reference*
