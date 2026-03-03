---
id: 8p72uv
title: Splitting Oversized E2E Tests (MT-COWORKER-003, MT-COMMIT-004)
type: standard
tags: []
created_at: '2026-02-08 01:54:17'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8p72uv-split-oversized-e2e-tests.md"
---

# Reflection: Splitting Oversized E2E Tests (MT-COWORKER-003, MT-COMMIT-004)

**Date**: 2026-02-08
**Context**: Splitting two consistently-timing-out E2E tests into 8 smaller files following the block-budget model from retros `8p6xkk` and `8p6ylo`
**Author**: claude-opus-4.6
**Type**: Standard

## What Went Well

- **Plan-first approach paid off**: The detailed plan with per-file block estimates, TC groupings, and consolidation patterns made execution purely mechanical — no design decisions during implementation
- **Retro-driven sizing worked**: The `90s + (blocks/2.5) × 25s` formula from prior retros (`8p6xkk`, `8p6ylo`) gave reliable target block counts (8-12 per file)
- **Consolidation patterns were straightforward**: Merging "run command + verify result" into single blocks is a simple, repeatable transformation — no loss of test coverage
- **Self-contained files**: Each split file has its own environment setup, test data, and cleanup — no cross-file dependencies, enabling parallel execution
- **TC coverage preserved exactly**: 9 coworker TCs and 8 commit TCs match the originals with no gaps or duplication

## What Could Be Improved

- **Initial block counts slightly over target**: Two files (003c: 13, 004d: 14) exceeded the 12-block max on first pass, requiring a second consolidation round — should have been more aggressive about merging from the start
- **Consolidation requires re-reading files**: After writing all 8 files, had to re-read the over-budget ones to identify merge opportunities — could have tracked block count during writing instead of counting after
- **Test data duplication**: Each split file for MT-COMMIT-004 recreates the same base git repo structure (README, pkg-a, pkg-b with configs). A shared setup template could reduce this, but the self-contained property is more valuable for E2E reliability

## Key Learnings

### Block Count Is the Only Sizing Metric That Matters

For the third time across E2E splitting tasks (ace-lint, ace-coworker, ace-git-commit), the same lesson holds: **TC count is a poor proxy for timing; bash block count is the true constraint**. MT-COWORKER-003 had 9 TCs but 75 blocks — well over any reasonable budget.

### The Consolidation Pattern Library Is Stabilizing

These patterns work reliably across all E2E test domains:

| Pattern | Before | After |
|---------|--------|-------|
| Run + verify exit code | 2 blocks | 1 block |
| Create + verify exists | 2 blocks | 1 block |
| Run + verify output + verify file | 3 blocks | 1 block |
| Multiple greps on same file | N blocks | 1 block |

### Self-Contained > Shared Setup for E2E Tests

Each split file creates its own session/repo from scratch. While this means duplicated setup code, it provides: (1) no ordering dependencies between files, (2) parallel execution capability, (3) simpler debugging when a single file fails.

### TC Grouping Strategy: Dependency Chains vs Independence

For MT-COWORKER-003, TCs 001-005 shared a session (sequential dependency chain) while TCs 006-009 were independent. The split followed this natural boundary: dependent TCs stayed together (003a has TC-001+002; 003b has TC-003+004+005 which build on the same session state), while independent TCs got their own setup.

## Action Items

### Continue Doing

- Using the `90s + (blocks/2.5) × 25s` formula to estimate timing before writing
- Applying consolidation patterns (merge verify into execution blocks)
- Creating self-contained files with independent setup/cleanup
- Planning splits before implementing (the plan had exact file names, TC assignments, and block estimates)

### Start Doing

- Track block count _during_ file creation, not just as a post-hoc verification step
- When writing new E2E tests from scratch, apply the 8-12 block budget from the start (preventive rather than reactive splitting)

## Technical Details

### Files Changed

| Action | File | Blocks |
|--------|------|--------|
| DELETE | MT-COWORKER-003-hierarchical-jobs.mt.md | 75 |
| CREATE | MT-COWORKER-003a-error-handling.mt.md | 9 |
| CREATE | MT-COWORKER-003b-injection-renumbering.mt.md | 11 |
| CREATE | MT-COWORKER-003c-auto-completion.mt.md | 12 |
| CREATE | MT-COWORKER-003d-display-audit.mt.md | 11 |
| DELETE | MT-COMMIT-004-split-commit-workflow.mt.md | 57 |
| CREATE | MT-COMMIT-004a-auto-split-basics.mt.md | 10 |
| CREATE | MT-COMMIT-004b-path-rules-dryrun.mt.md | 9 |
| CREATE | MT-COMMIT-004c-scope-cascade.mt.md | 10 |
| CREATE | MT-COMMIT-004d-moves-globs.mt.md | 12 |

### Estimated Times (post-split)

All files: 180-210s (under 240s max, most under 200s target)

## Additional Context

- Prior retros: `8p6xkk` (E2E module sizing), `8p6ylo` (timing analysis round 2)
- PR: #194 (255.03: Add ace-test-suite-e2e command)
- Phase 2 candidates (not addressed): MT-COWORKER-001 (73 blocks), MT-COWORKER-002 (42 blocks)