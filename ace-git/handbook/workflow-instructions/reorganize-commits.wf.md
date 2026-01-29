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

| `ace-git-commit` handles grouping and messages automatically.

---

## Recovery

```bash
git reflog
git reset --hard HEAD@{n}
```

---

## Manual Override (rare)

Only if `ace-git-commit` groups incorrectly AND adjusting the intention doesn't help:

```bash
git reset --soft $base && git reset HEAD
ace-git-commit <paths> -i "group 1"
ace-git-commit <paths> -i "group 2"
```
