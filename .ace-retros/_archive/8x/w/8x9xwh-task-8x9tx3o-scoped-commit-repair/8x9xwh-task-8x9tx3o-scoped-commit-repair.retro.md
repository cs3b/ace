---
id: 8x9xwh
title: Task 8x9.t.x3o scoped commit repair
type: self-review
tags: [git-worktree, regression]
created_at: "2026-10-10 22:36:05"
status: done
---

# Task 8x9.t.x3o scoped commit repair

## What I Did Well

- Added a regression at the orchestrator's external call path and observed the exact private-method error before changing production code.
- Moved `commit_scoped` with its docstring above `private` without changing the method body or signature.
- Confirmed green-after coverage, 549 package tests, and a successful task-aware CLI create with bookkeeping commit and worktree metadata.

## What I Could Improve

- The initial `ace-test` command with both a file and filter selected zero tests; the following run selected the organism suite and captured the required red result.
- `ace-git-worktree remove --task` resolved the assignment journal checkout instead of the temporary task worktree. I restored the checkout and cleaned the temporary worktree with direct Git commands.

## Key Learnings

- Test selection must be checked from runner reports; an exit code of zero with no selected tests is not verification.
- Task-aware `create` can still attempt a remote push even when invoked with `--no-push`; the remote rejected this proof's push.
- Assignment evidence can bind to the correct candidate head when scoped state is accessible from the repair worktree.

## Action Items

- Investigate the wrong-path `remove --task` lookup and the ignored `--no-push` behavior as separate work from this constrained visibility fix.
- Include the red/green report paths, end-to-end proof and approved manual-worktree deviation in the repair PR body.
