---
id: 8os0p5
title: "Retro: Cherry-Pick Rebase Recovery"
type: standard
tags: []
created_at: "2026-01-29 00:27:55"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8os0p5-cherry-pick-rebase-recovery.md
---
# Retro: Cherry-Pick Rebase Recovery

**Date**: 2026-01-29
**Context**: Recovering from a failed reset-split rebase that introduced unwanted files and lost CHANGELOG entries
**Author**: Claude Code
**Type**: Standard

## What Went Well

- Cherry-pick approach proved cleaner than rebase --onto for this use case
- Selective commit migration avoided bringing in ace-coworker feature files
- Conflict resolution was straightforward (only one file: ace-coworker/exe/ace-coworker)
- Branch replacement strategy (delete and rename) worked cleanly
- Tests passed immediately after cherry-pick completion

## What Could Be Improved

- Initial rebase --onto with reset-split caused significant problems:
  - Added ace-coworker gem files that didn't belong to branch 229
  - Overwrote important files like `.claude/skills/ace_work-on-task/SKILL.md` with older versions
  - Deleted CHANGELOG.md entries from 0.9.337-0.9.342
- Required manual identification of which commits to cherry-pick vs skip
- Time lost recovering from failed approach

## Key Learnings

- **Rebase vs Cherry-Pick**: For maintaining branch purity when target has diverged significantly, cherry-pick offers better control than rebase --onto
- **Commit Selection Critical**: When using reset-split approach, must be extremely careful about which commits are selected - reset-split includes ALL commits from the split point forward
- **CLI Migration Pattern**: The CLI exception handling migration has a consistent pattern (add base class, then migrate each gem), making cherry-pick selection straightforward
- **Version Bumps**: Gemfile.lock changes are expected and should be committed as part of the migration

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Reset-Split Rebase Failure**: Used `git rebase -i --onto target branch~20` which brought in unwanted commits
  - Occurrences: 1 (but significant impact)
  - Impact: Added ~50+ ace-coworker files, overwrote SKILL.md files, lost CHANGELOG entries
  - Root Cause: reset-split selects all commits from the split point, including feature commits that shouldn't be in this branch

#### Medium Impact Issues

- **Manual Commit Identification Required**: Had to manually identify which 14 commits to cherry-pick from a 20-commit history
  - Occurrences: 1
  - Impact: Time spent reading commit messages to determine relevance
  - Root Cause: Branch had mixed commits (CLI migration + chore + task 237 work)

#### Low Impact Issues

- **Single Conflict Resolution**: One merge conflict in ace-coworker/exe/ace-coworker
  - Occurrences: 1
  - Impact: Minor, easily resolved
  - Root Cause: Target branch had older CLI pattern, cherry-pick had new pattern (expected)

### Improvement Proposals

#### Process Improvements

- **Pre-Rebase Validation**: Before using reset-split rebase, verify that commits between split point and HEAD are ALL relevant to the target branch
- **Commit Hygiene**: Keep feature branches focused - branch 229 had CLI migration commits mixed with task 237 work, making clean rebase difficult
- **Cherry-Pick First**: For branches with mixed commit types, consider cherry-pick approach as primary strategy when target has diverged

#### Tool Enhancements

- **Interactive Cherry-Pick Helper**: Tool to help select commits by pattern matching (e.g., "select all CLI-related commits")
- **Rebase Simulator**: Preview what files a rebase would modify before executing
- **Branch Diff Tool**: Quick way to see "what files would change if I rebase X onto Y"

## Action Items

### Stop Doing

- Using reset-split rebase when branch has mixed commit types and target has diverged significantly
- Assuming all commits between branch point and HEAD are relevant

### Continue Doing

- Verifying branch state after rebase operations (check for unwanted files)
- Running tests after branch operations to catch issues early

### Start Doing

- Using cherry-pick for selective commit migration when branch purity matters
- Checking `git diff --stat target..HEAD` before force-pushing to verify only intended files changed
- Documenting rebase strategies in team knowledge base for future reference

## Technical Details

**Recovery Steps:**
1. Created new branch from target: `git checkout origin/237-ace-coworker-mvp-with-work-queue-model -b 229-new`
2. Cherry-picked 14 CLI migration commits in reverse chronological order
3. Resolved conflict in ace-coworker/exe/ace-coworker (chose exception-based version)
4. Deleted old branch: `git branch -D 229-migrate-...`
5. Renamed new branch: `git branch -m 229-migrate-...`
6. Force pushed: `git push --force-with-lease`

**Commits Cherry-Picked (oldest to newest):**
- `4ab47dcdc` - refactor(support-packages): Centralize CLI error handling
- `b22539323` - feat(ace-bundle): Implement exception-based exit codes
- `deebb1f2c` - feat(ace-git): Integrate exception-based error handling
- `712843e54` - feat(ace-git-commit): Transition to exception-based CLI error reporting
- `f1798420b` - feat(ace-git-secrets): Implement exception-based CLI exit codes
- `318882b35` - feat(ace-git-worktree): Adopt exception-based exit codes
- `31ff2188a` - feat(ace-lint): Implement exception-based exit codes
- `b80f67952` - feat(ace-llm): Integrate exception-based exit codes
- `1c38a4d2a` - feat(ace-prompt-prep): Adopt exception-based exit codes
- `a40865eba` - feat(ace-review): Implement exception-based exit codes
- `26b36ce45` - feat(ace-search): Integrate exception-based exit codes
- `f5ab042a1` - feat(ace-taskflow): Adopt exception-based exit codes
- `f5043ae7a` - feat(ace-test-runner): Implement exception-based exit codes
- `f7d65997c` - feat(ace-coworker): Adopt exception-based exit codes

**Result:**
- 92 files changed, 598 insertions(+), 701 deletions(-)
- Only CLI-related files modified
- All tests passing
- No unwanted ace-coworker feature files included

## Additional Context

- Task: 229 (Migrate ace CLI gems to exception-based exit code pattern)
- Target branch: 237-ace-coworker-mvp-with-work-queue-model
- Related ADR: ADR-023 (Exception-based CLI error handling)
