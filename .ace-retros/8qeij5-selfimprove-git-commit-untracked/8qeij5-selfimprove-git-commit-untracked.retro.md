---
id: 8qeij5
title: selfimprove-git-commit-untracked
type: self-improvement
tags: [process-fix]
created_at: "2026-03-15 12:21:16"
status: active
---

# selfimprove-git-commit-untracked

## What Went Well

- Terminal `ace-git-commit` CLI worked correctly for untracked files — the tool itself was fine
- User caught the issue quickly and escalated to a selfimprove

## What Could Be Improved

- `/as-git-commit` skill failed twice on 28 untracked task files — Haiku agent reported "working directory is clean"
- Root cause 1 (primary): Agent equated "no tracked modifications + collapsed untracked directory" with "nothing to commit"
- Root cause 2: `git status -sb` collapses untracked directories into a single `??` entry, hiding 28 files behind one line
- The workflow lacked explicit guidance that untracked files are committable changes

## Action Items

- [x] Change embedded status command from `git status -sb` to `git status -sb -uall` to show individual untracked files
- [x] Add explicit guidance: untracked files (`??`) ARE committable, only report "nothing to commit" if status is truly empty
- [x] Save feedback memory about always executing `ace-git-commit` when any changes exist

