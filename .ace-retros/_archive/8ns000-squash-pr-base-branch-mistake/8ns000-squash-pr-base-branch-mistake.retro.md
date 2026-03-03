---
id: 8ns000
title: 'Retro: Squash PR Used Wrong Base Branch'
type: conversation-analysis
tags: []
created_at: '2025-12-29 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8ns000-squash-pr-base-branch-mistake.md"
---

# Retro: Squash PR Used Wrong Base Branch

**Date**: 2025-12-29
**Context**: During squash-pr workflow for PR #102, used origin/main as base instead of the PR's actual target branch
**Author**: Claude Agent
**Type**: Conversation Analysis

## What Went Well

- User caught the discrepancy by comparing GitHub diff stats with local
- We had created a backup tag before squashing, enabling easy recovery
- Tree hash comparison verified no content was lost after correction

## What Could Be Improved

- Should have run `ace-git status` before starting squash to see target branch
- Skipped the "Prerequisites - PR Base Detection" section of squash-pr workflow
- Assumed `origin/main` was the correct base without verification

## Key Learnings

- PRs can target feature branches, not just main
- `ace-git status` shows "Target: branch-name" clearly in the PR section
- The squash-pr workflow has a Prerequisites section that MUST be followed
- GitHub shows different diff stats when comparing against wrong base

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Wrong Base Branch for Squash**: Used `origin/main` instead of `origin/157-...`
  - Occurrences: 1
  - Impact: Had to completely redo the squash (41 commits squashed incorrectly, then restored and re-squashed 36 commits correctly)
  - Root Cause: Skipped workflow prerequisites, assumed main was the target

### Improvement Proposals

#### Process Improvements

- **ALWAYS run `ace-git status` before squash-pr** - it shows the PR target branch
- Add `ace-git status` to squash-pr workflow prerequisites as the FIRST step
- Create a pre-squash checklist that must be verified

#### Tool Enhancements

- **squash-pr workflow**: Add `ace-git status` command to Prerequisites section
- Consider adding a safety check in the workflow that warns if base != PR target

## Action Items

### Stop Doing

- Assuming `origin/main` is always the squash base
- Skipping workflow prerequisite sections

### Continue Doing

- Creating backup tags before squashing
- Verifying tree hashes after squash
- Comparing GitHub diff stats with local diff

### Start Doing

- Run `ace-git status` FIRST before any squash operation
- Read and follow workflow prerequisites completely
- Check PR target branch explicitly with `ace-git status` or `gh pr view --json baseRefName`

## Technical Details

**What `ace-git status` shows:**
```
## Current PR

#102 [OPEN] 159: Extract ace-support-fs gem...
  Target: 157-extract-ace-config-gem-from-ace-support-core | Author: @cs3b
```

**The correct base should have been:**
- `origin/157-extract-ace-config-gem-from-ace-support-core` (tip: ac04639a)
- NOT `origin/main` (80e54c93)

**Impact of using wrong base:**
- Local diff: 106 files, +2,818 -3,773 (correct)
- GitHub showed: 130 files, +6,983 -2,533 (wrong because we included parent PR commits)

## Additional Context

- PR #102: https://github.com/cs3b/ace-meta/pull/102
- Parent PR #101: 157-extract-ace-config-gem (target of our PR)
- squash-pr workflow: `ace-nav wfi://squash-pr`