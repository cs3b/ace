---
name: rebase
allowed-tools: Bash, Read
description: Rebase feature branch using intelligent commit splitting or manual strategies
argument-hint: "[target-branch] [--strategy=reset-split|manual|interactive]"
doc-type: workflow
purpose: changelog-preserving rebase workflow with multiple strategies
update:
  frequency: on-change
  last-updated: '2026-01-26'
---

# Rebase Workflow

## Purpose

Rebase feature branches against target branch with automatic handling of CHANGELOG.md, version files, and commit organization. Supports multiple strategies from fully automatic to manual control.

## Strategies Overview

| Strategy | Best For | Complexity | CHANGELOG Handling |
|----------|----------|------------|-------------------|
| **reset-split** (DEFAULT) | Most rebases | Simple | Automatic via scope grouping |
| **manual** | Preserving exact history | Medium | Manual conflict resolution |
| **interactive** | Commit cleanup/squashing | Advanced | Manual during rebase |

## Variables

- `$target_branch`: Branch to rebase against (default: auto-detect or origin/main)
- `$strategy`: Rebase strategy (default: reset-split)

**Target Branch Auto-Detection:**

```bash
task_file=$(ls _current/*.s.md 2>/dev/null | head -1)
if [ -n "$task_file" ]; then
  target_branch=$(ruby -ryaml -e 'c=File.read(ARGV[0]); puts c.start_with?("---") ? (YAML.safe_load(c.split("---",3)[1]).dig("worktree","target_branch")||"origin/main") : "origin/main"' "$task_file" 2>/dev/null || echo "origin/main")
else
  target_branch="origin/main"
fi
```

---

## Strategy: Reset and Re-split (DEFAULT)

**Use when:** You want clean, well-organized commits without manual conflict resolution.

This strategy leverages `ace-git-commit` path-based splitting to:
- Automatically group files by scope (packages, config, docs, etc.)
- Generate distinct commit messages for each scope
- Order commits logically (implementation first, documentation last)
- Avoid CHANGELOG conflicts entirely by re-creating commits cleanly

### Instructions

#### 1. Pre-Rebase Check

```bash
# Verify current state
git status
git log $target_branch..HEAD --oneline

# Ensure working directory is clean
git stash push -m "pre-rebase" # if needed
```

#### 2. Fetch and Reset

```bash
# Fetch latest changes
git fetch origin

# Soft reset to target branch (keeps all changes staged)
git reset --soft $target_branch
```

#### 3. Re-commit with Path Splitting

```bash
# Let ace-git-commit handle grouping and commit creation
ace-git-commit -i "Rebase: <brief description of feature branch work>"
```

This automatically:
- Groups files by scope (ace-* packages, .ace/, .ace-taskflow/, etc.)
- Generates appropriate commit messages per scope
- Orders commits: feat → fix → refactor → chore → docs
- Creates clean, logical commit history

#### 4. Verify and Push

```bash
# Verify commits look correct
git log --oneline -10

# Run tests
ace-test

# Force push
git push --force-with-lease origin $(git branch --show-current)
```

### Example

Before (messy history with CHANGELOG conflicts):
```
* abc1234 fix: typo in docs
* def5678 feat: add feature X
* ghi9012 docs: update CHANGELOG  <- conflicts!
* jkl3456 chore: config changes
```

After reset-split:
```
* new1111 feat(ace-package): add feature X
* new2222 chore(config): update configuration
* new3333 docs(taskflow): update documentation
```

---

## Strategy: Manual Conflict Resolution

**Use when:** You need to preserve exact commit history or have complex interleaved changes.

### Instructions

#### 1. Pre-Rebase Backup

```bash
git fetch origin

# Backup critical files
cp CHANGELOG.md CHANGELOG.md.backup 2>/dev/null || true
find . -name "version.rb" -type f -exec cp {} {}.backup \;
```

#### 2. Start Rebase

```bash
git rebase $target_branch
```

#### 3. Handle CHANGELOG Conflicts

When CHANGELOG.md conflicts:

```bash
# Accept target branch version completely
git checkout --theirs CHANGELOG.md

# Edit to add YOUR entries at the TOP with NEW version number
# - Find highest version in target (e.g., [0.9.127])
# - Add your entries as [0.9.128]
# - DO NOT modify existing target entries

git add CHANGELOG.md
git rebase --continue
```

**CRITICAL:**
- Accept target branch history as-is
- Add your changes on top with incremented version
- Never modify past version entries

#### 4. Handle Other Conflicts

```bash
# Version files - usually keep yours
git checkout --ours lib/*/version.rb
git add lib/*/version.rb

# Code conflicts - resolve manually
# Edit files, remove markers (<<<<, ====, >>>>)
git add <resolved-files>
git rebase --continue
```

#### 5. Verify and Push

```bash
diff CHANGELOG.md CHANGELOG.md.backup
git log --oneline -10
ace-test
git push --force-with-lease
```

---

## Strategy: Interactive Rebase

**Use when:** You need to squash, reorder, or edit individual commits.

### Instructions

```bash
git fetch origin

# Interactive rebase
git rebase -i $target_branch

# In editor:
# - pick: keep commit as-is
# - squash/s: combine with previous
# - reword/r: change commit message
# - edit/e: stop to amend
# - drop/d: remove commit

# Handle conflicts as in Manual strategy
# Then continue:
git rebase --continue
```

**Tip:** Squash before rebasing to reduce CHANGELOG conflicts:
```bash
git rebase -i HEAD~5  # Squash feature commits first
git rebase $target_branch  # Then rebase (fewer conflicts)
```

---

## Recovery Procedures

### Abort Rebase

```bash
git rebase --abort
cp CHANGELOG.md.backup CHANGELOG.md 2>/dev/null || true
```

### Lost Commits

```bash
git reflog | head -20
git cherry-pick <commit-hash>
```

### Reset-Split Recovery

If reset-split produces unexpected results:
```bash
# Find original HEAD in reflog
git reflog | grep "reset.*soft"
# The line BEFORE that shows your original HEAD
git reset --hard <original-head>
```

---

## Strategy Selection Guide

```
Need to preserve exact commit history?
├── YES → Use "manual" strategy
└── NO
    ├── Need to squash/reorder commits?
    │   └── YES → Use "interactive" strategy
    └── NO → Use "reset-split" (DEFAULT)
```

**Default to reset-split** - it handles most cases with zero conflicts and produces clean history.

---

## Success Criteria

- ✓ Feature branch rebased on target
- ✓ CHANGELOG.md properly updated
- ✓ Commits logically ordered
- ✓ Tests pass
- ✓ Clean history

## Response Template

**Strategy Used:** reset-split | manual | interactive
**Target Branch:** [origin/main, etc.]
**Commits Created:** [Number and brief description]
**Tests Status:** Pass | Fail
**Status:** ✓ Complete | ⚠ Needs attention
