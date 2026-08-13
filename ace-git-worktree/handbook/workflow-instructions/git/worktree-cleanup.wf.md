---
title: Worktree Cleanup
description: Safely inventory and apply cleanup plans for squash-merged worktrees and refs
category: Git
tags: [git, worktree, cleanup, safely, squash-merge]
version: 1.0.0
---

# Worktree Cleanup

The `ace-git-worktree cleanup` command safely removes stale worktrees, local branches, and remote-tracking branches that have been merged (including squash merges). It uses a two-phase report/apply model with strict ancestry and drift guards.

## Generate Cleanup Report

First, generate a deterministic, no-mutation inventory of everything that could be cleaned up relative to a target branch:

```bash
ace-git-worktree cleanup --target main --remote origin
```

This will:
1. Refresh remote evidence (unless `--offline` is passed).
2. Find all worktrees, local refs, and remote refs.
3. Classify each using GitHub PR evidence (exact merge, stable patch equivalence) or Git ancestry.
4. Output an ordered plan with a **Plan Digest**.

### Report Output Interpretation

- `✓` (Retain): Item is protected (e.g., primary checkout, dirty worktree) or its ancestry/merge status is unproven.
- `✗` (Remove): Item is safe to delete because it is fully merged into the target.

## Apply Cleanup Plan

To execute the deletions, you must provide the exact Plan Digest from your reviewed report. This ensures that no destructive operations occur if the repository state drifts (e.g., if a worktree becomes dirty or a ref advances).

```bash
ace-git-worktree cleanup --target main --apply --approved-digest <sha256-digest>
```

ACE will:
1. Re-scan the repository and rebuild the plan.
2. Abort if the new plan's digest does not match your `--approved-digest`.
3. Apply deletions in a fixed order (worktrees, local refs, remote refs).
4. Re-validate dirty state and expected SHAs immediately before each deletion.
5. Finish with a strict rescan and output the results.

### Strict Rescan

If you want to ensure that *only* the target branch remains after cleanup, you can use the `--require-only-target` flag:

```bash
ace-git-worktree cleanup --target main --apply --approved-digest <sha256-digest> --require-only-target
```

If any non-target worktrees or refs are retained (e.g., because they were unproven or dirty), the command will exit with an error.

## Advanced Usage

For automation or scripting, use the JSON format:

```bash
ace-git-worktree cleanup --target main --format json | jq .
```
