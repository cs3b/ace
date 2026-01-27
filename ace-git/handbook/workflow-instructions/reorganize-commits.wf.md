---
name: reorganize-commits
allowed-tools: Bash, Read
description: Reorganize commits into clean, logical groups using ace-git-commit
argument-hint: "[base-commit]"
doc-type: workflow
purpose: simplified commit reorganization workflow
update:
  frequency: on-change
  last-updated: '2026-01-27'
---

# Reorganize Commits Workflow

Reorganize multiple commits into clean, logical commits.

## Steps

```bash
git reset --soft $base
ace-git-commit -i "brief intention"
```

Done. ace-git-commit handles grouping and messages automatically.

---

## Finding the Base Commit

```bash
# By commit count
base=HEAD~5

# By specific commit
base=abc1234

# For PR (merge-base with target branch)
base=$(git merge-base HEAD origin/main)
```

---

## Recovery

```bash
git reflog
git reset --hard HEAD@{n}
```

---

## Manual Override (rare)

Only if ace-git-commit groups incorrectly AND adjusting the intention doesn't help:

```bash
git reset --soft $base && git reset HEAD
ace-git-commit <paths> -i "group 1"
ace-git-commit <paths> -i "group 2"
```
