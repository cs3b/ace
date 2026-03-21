---
doc-type: workflow
title: Reorganize Commits Workflow
purpose: simplified commit reorganization workflow
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
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

## Scope Determination

**If user provides explicit scope** (commit list, range, or PR reference):
- Use the user-provided scope directly
- Trust the user's intent - they know what they want to reorganize
- Do NOT second-guess with embedded status

**If no explicit scope provided**:
- Use embedded repository status as the default
- "ahead N" means N unpushed commits (reasonable default)
- If user seems to expect more commits, ASK before proceeding

**Mismatch Warning**: If embedded status shows fewer commits than user seems to expect (e.g., user provides a commit list longer than "ahead N"), STOP and clarify:
- Did user want to reorganize all PR commits (use merge-base)?
- Or just the unpushed ones (use embedded status)?

---

## Steps

### 1. Identify Base

Determine base commit using **Scope Determination** above.

**Common patterns**:

```bash
# From user-provided commit range (user said "reorganize abc123..HEAD")
base=abc123

# From merge-base for full PR (user wants all PR commits)
base=$(git merge-base HEAD origin/main)

# From embedded status (default: unpushed commits only)
# If status shows "ahead 5", use HEAD~5
base=HEAD~5
```

> ⚠️ **When in doubt**: If user provides explicit commits or range, use that. Otherwise use embedded status but verify it matches user's expectations.

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

---

## Examples

### User Provides Explicit Scope

```
User: "Reorganize these commits: abc, def, ghi, jkl..."
→ Use merge-base to include all listed commits
→ Do NOT use "ahead 5" from embedded status
```

### No Explicit Scope (Use Default)

```
User: "Reorganize commits"
Embedded status: "ahead 5"
→ Use HEAD~5 (unpushed commits)
→ If user expected more, they would have specified
```

### Mismatch - ASK Before Proceeding

```
User: "Here are the 12 commits to reorganize: ..."
Embedded status: "ahead 5"
→ User provided 12, status shows 5
→ ASK: "Do you want all 12 commits (from main) or just the 5 unpushed?"
```