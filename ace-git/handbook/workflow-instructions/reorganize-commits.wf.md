---
name: reorganize-commits
allowed-tools: Bash, Read
description: Reorganize commits into clean, logical groups using ace-git-commit
argument-hint: "[base-commit]"
doc-type: workflow
purpose: simplified commit reorganization workflow
update:
  frequency: on-change
  last-updated: '2026-01-26'
---

# Reorganize Commits Workflow

## Purpose

Reorganize multiple commits into clean, logical commits using `ace-git-commit` for intelligent grouping and message generation.

## Strategies

| Strategy | Use When | Command |
|----------|----------|---------|
| **auto** (default) | Most cases | `ace-git-commit -i "intention"` |
| **controlled** | Need specific grouping | `ace-git-commit <paths> -i "intention"` per group |

---

## Strategy: Auto (Default)

Let `ace-git-commit` handle grouping and messages automatically.

### Steps

```bash
# 1. Find base commit
git log --oneline -10
base=<commit-before-your-changes>

# 2. Soft reset (keeps all changes staged)
git reset --soft $base

# 3. Let ace-git-commit handle everything
ace-git-commit -i "brief description of all changes"
```

**That's it.** ace-git-commit will:
- Group files by scope (packages, config, docs, etc.)
- Generate distinct messages per group
- Order commits logically (feat → fix → chore → docs)

### Example

```bash
# Reorganize last 5 commits
git reset --soft HEAD~5
ace-git-commit -i "Implement user authentication feature"

# Result: 2-4 logical commits based on file scopes
```

---

## Strategy: Controlled

When you need precise control over what goes into each commit.

### Steps

```bash
# 1. Soft reset
git reset --soft $base

# 2. Unstage everything
git reset HEAD

# 3. Commit each logical group
ace-git-commit <path1>/ <path2>/ -i "description for this group"
ace-git-commit <path3>/ -i "description for next group"
# ... repeat for each group

# 4. Verify after each commit
git status
```

### Example

```bash
git reset --soft HEAD~10
git reset HEAD

# Commit 1: Core feature
ace-git-commit ace-auth/lib/ ace-auth/test/ -i "implement OAuth authentication"

# Commit 2: Integration
ace-git-commit ace-api/lib/ ace-api/test/ -i "integrate auth into API layer"

# Commit 3: Config and docs
ace-git-commit .ace/ CHANGELOG.md -i "add auth configuration and docs"
```

---

## Finding the Base Commit

### For PR reorganization

```bash
# Get PR's target branch
base_ref=$(gh pr view --json baseRefName -q '.baseRefName')
git fetch origin $base_ref
base=$(git merge-base HEAD origin/$base_ref)
```

### For local reorganization

```bash
# By commit count
base=HEAD~5

# By specific commit
base=abc1234

# By tag
base=$(git describe --tags --abbrev=0)
```

---

## Recovery

```bash
# Undo reorganization (find pre-reorganization state)
git reflog
git reset --hard HEAD@{n}
```

---

## Quick Reference

```bash
# Default (auto grouping)
git reset --soft $base && ace-git-commit -i "intention"

# Controlled (manual grouping)
git reset --soft $base && git reset HEAD
ace-git-commit <paths> -i "group 1"
ace-git-commit <paths> -i "group 2"
```
