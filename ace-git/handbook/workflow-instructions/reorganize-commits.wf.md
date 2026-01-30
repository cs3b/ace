---
name: reorganize-commits
allowed-tools: Bash, Read
description: Reorganize commits into clean, logical groups using ace-git-commit
argument-hint: "[base-commit]"
doc-type: workflow
purpose: simplified commit reorganization workflow
update:
  frequency: on-change
  last-updated: '2026-01-29'
bundle:
  embed_document_source: true
  sections:
    current_repository_status:
      commands:
        - ace-git status
---

# Reorganize Commits Workflow

Reorganize multiple commits into clean, logical commits.

## Key Principle

**Reorganize = Reorder, NOT Squash**

The goal is to reorder commits into logical groups while preserving per-scope granularity.
`ace-git-commit` creates one commit per configuration scope by design - this is expected behavior, not a problem to fix.

| Term | Meaning |
|------|---------|
| Reorganize | Reorder commits into logical groups |
| Squash | Combine multiple commits into one (NOT the goal here) |

## Steps

### 1. Identify Base

Use information from current repository status to determine the base commit:

```bash
# For PR (merge-base with target branch)
base=$(git merge-base HEAD $origin/feature-branch)

# By commit count
base=HEAD~5

# By specific commit
base=abc1234
```

### 2. Identify Commit Intentions

Read all commit messages (only the messages) to understand what changes will be reorganized:

```bash
git log $base..HEAD --format="%s"
```

Based on the commit messages, define the logical intention(s) that will be used in step 4. This helps `ace-git-commit` group changes correctly.


### 3. Reset

```bash
git reset --soft $base
```

### 4. Create Logical Commits

```bash
ace-git-commit -i "brief intention"
```

**IMPORTANT:** Do NOT specify file paths. Let the tool group by scope automatically.

`ace-git-commit` handles grouping and messages automatically.

**Expected Output**: Multiple commits, one per scope:
```
[1/5] Committing ace-foo changes...
abc1234 feat(ace-foo): Implement feature X
[2/5] Committing ace-bar changes...
def5678 test(ace-bar): Update tests for feature X
...
```

This is correct behavior - do NOT try to combine these into fewer commits.

---

## Recovery

```bash
git reflog
git reset --hard HEAD@{n}
```

---

## Manual Override (almost never needed)

**Before using manual override, verify**:
- Did you try adjusting the intention? (usually fixes grouping issues)
- Are you trying to squash commits? (that's not the goal - stop)
- Is the auto-grouping actually wrong, or just different from expectation?

Only use if `ace-git-commit` groups files incorrectly AND adjusting the intention doesn't help:

```bash
git reset --soft $base && git reset HEAD
ace-git-commit <paths> -i "group 1"
ace-git-commit <paths> -i "group 2"
```
