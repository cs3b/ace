---
id: 8n2000
title: Squash-PR Wrong Base Commit
type: conversation-analysis
tags: []
created_at: "2025-12-03 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8n2000-squash-pr-wrong-base-commit-lesson.md
---
# Reflection: Squash-PR Wrong Base Commit

**Date**: 2025-12-03
**Context**: Critical mistake during PR squashing - used wrong base commit, squashed commits from multiple PRs
**Author**: Claude (AI Assistant)
**Type**: Conversation Analysis

## What Went Well

- Recovery was successful using git reflog
- Correctly identified the root cause after the mistake
- Properly re-squashed with correct base (637ccfd0)
- Updated PR description to correct scope

## What Could Be Improved

- Should have checked PR metadata BEFORE squashing
- Should have validated commit scope before destructive operation
- Workflow instruction was followed literally but lacked critical validation steps

## Key Learnings

1. **NEVER assume `origin/main` is the correct base for squashing**
   - PRs can be based on feature branches, not just main
   - Always check `gh pr view --json baseRefName` first

2. **PR dependencies matter**
   - "Depends on: #61" in PR body was a signal that another PR existed
   - Parent PR should be verified as merged before squashing child

3. **Validate before destructive operations**
   - Show commit list and get confirmation before squashing
   - Count commits to verify scope matches expectations

4. **Git reflog is your safety net**
   - Recovery was possible because reflog preserves history
   - Always know how to use `git reset --hard HEAD@{n}` to recover

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Cross-PR Squashing**: Combined commits from PR #61 (126.01) and PR #63 (126.02) into one commit
  - Occurrences: 1 (but this is a repeatable mistake)
  - Impact: Required full recovery - reset, re-squash, force push, update PR description
  - Root Cause: squash-pr.wf.md workflow didn't include PR base detection step

- **Assumed Base Branch**: Used `origin/main..HEAD` without verification
  - Occurrences: 1
  - Impact: Squashed 18 commits instead of 11
  - Root Cause: Standard git pattern assumes main branch, but PRs can have different bases

#### Medium Impact Issues

- **Ignored PR Metadata**: PR #63 had `baseRefName: 126-multi-model-review-enhancement-orchestrator`
  - Occurrences: 1
  - Impact: Would have prevented mistake if checked
  - Root Cause: Workflow didn't instruct to check this field

### Improvement Proposals

#### Process Improvements

- Add "PR Base Detection" prerequisite section to squash-pr.wf.md
- Require explicit confirmation of commit scope before squashing
- Add warning about non-main base branches

#### Tool Enhancements

- The `/ace:squash-pr` command should automatically fetch PR base via `gh pr view`
- Consider adding a `--pr <number>` flag to ace-git commands for context

#### Communication Protocols

- When executing destructive operations, show what will happen and ask for confirmation
- Display commit list before squashing so user can verify scope

## Action Items

### Stop Doing

- Assuming `origin/main` is always the correct squash base
- Squashing without first checking PR metadata
- Proceeding with destructive operations without scope verification

### Continue Doing

- Using git reflog for recovery when mistakes happen
- Documenting mistakes in retros for future learning
- Following workflow instructions (but now with added validation)

### Start Doing

- Always run `gh pr view $PR --json baseRefName` before squashing
- Show commit list and count before proceeding
- Check for "Depends on:" in PR body to identify parent PRs
- Update workflow instructions when gaps are found

## Technical Details

### Correct Squash Process for PRs

```bash
# 1. Get PR's actual base branch
PR_NUMBER=63
base_ref=$(gh pr view $PR_NUMBER --json baseRefName -q '.baseRefName')
# Result: 126-multi-model-review-enhancement-orchestrator (NOT main!)

# 2. Find merge-base with that branch
git fetch origin $base_ref
base_commit=$(git merge-base HEAD origin/$base_ref)
# Result: 637ccfd0 (the merge commit of PR #61)

# 3. Verify scope
git log --oneline $base_commit..HEAD
# Shows 11 commits (correct), not 18 (wrong)

# 4. Then squash
git reset --soft $base_commit
git commit -m "squash message"
```

### Recovery Process Used

```bash
# Find pre-squash state
git reflog | head -5
# HEAD@{2} was 272c196e (pre-squash)

# Reset to pre-squash
git reset --hard 272c196e

# Force push to restore remote
git push --force-with-lease origin 126.02-report-synthesis

# Re-squash with correct base
git reset --soft 637ccfd0
git commit -m "correct message"
git push --force-with-lease
```

## Additional Context

- PR #61: 126.01 Multi-Model Execution (already merged at 637ccfd0)
- PR #63: 126.02 Report Synthesis (should only contain commits after 637ccfd0)
- The mistake combined both PRs' work into one commit
- squash-pr.wf.md needs update to prevent this
