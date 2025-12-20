---
id: v.0.9.0+task.140
status: in-progress
priority: medium
estimate: 16-24h (total across subtasks)
dependencies: []
---

# Enhance ace-context with Dynamic Git Branch and PR Information

**Type:** Orchestrator

## Objective

Consolidate all Git/GitHub CLI operations into a unified **ace-git** package, eliminating ~40-50% code duplication across ace-* gems.

## Architecture Decision

Create **ace-git** as the main Git/GitHub package by:
1. Merging ace-git-diff functionality
2. Adding new context/PR/branch subcommands
3. Migrating duplicated code from other packages

### CLI Structure
```bash
ace-git context              # Repository context (branch, PR, task pattern)
ace-git diff [range]         # Git diff (from ace-git-diff)
ace-git pr [number]          # PR information
ace-git branch               # Branch info only
```

## Consolidation Summary

| Package | Duplicated Code → ace-git |
|---------|---------------------------|
| ace-git-diff | CommandExecutor, DiffOrchestrator |
| ace-review | git_branch_reader, task_auto_detector, pr_identifier_parser |
| ace-prompt | git_branch_reader |
| ace-context | git_extractor, gh_pr_executor, pr_identifier_parser |
| ace-git-worktree | git_command, task_id_extractor, pr_fetcher |
| ace-taskflow | git_executor |

## Subtasks

### 140.01: Create ace-git package
Merge ace-git-diff + new context features into unified ace-git

### 140.02: Update ace-taskflow
Add `ace-taskflow context` using ace-git, replace git_executor

### 140.03: Update ace-review
Replace git_branch_reader, task_auto_detector, pr_identifier_parser

### 140.04: Update ace-prompt
Replace git_branch_reader

### 140.05: Update ace-context
Replace git_extractor, gh_pr_executor, pr_identifier_parser

### 140.06: Update ace-git-worktree
Replace git_command, task_id_extractor, pr_fetcher

### 140.07: Deprecate ace-git-diff
Add deprecation notice, keep as thin wrapper

## Success Criteria

- [ ] ace-git package created with context/diff/pr/branch commands
- [ ] All dependent packages migrated to use ace-git
- [ ] ace-git-diff deprecated (backward compatible wrapper)
- [ ] ~40-50% reduction in duplicated Git/gh code

## References

- Plan: `.claude/plans/silly-zooming-lobster.md`
- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251202-231239-ace-context-enhance/`
