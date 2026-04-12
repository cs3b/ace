---
id: 8qqm3s
title: batch-t-2p4-2-assignment-8qqk4p
type: standard
tags: []
created_at: "2026-03-27 14:44:13"
status: active
---

# batch-t-2p4-2-assignment-8qqk4p

## What Went Well

- **Fork-based review cycles worked smoothly**: All three review cycles (valid, fit, shine) executed via fork-run without crashes or recovery needed. Each cycle completed in ~10-15 minutes with real code changes applied.
- **Shared creation path delivered clean**: The `TaskAssignmentCreator` organism successfully unified `ace-assign create --task` and `ace-overseer work-on`, and the review cycles confirmed the design held up under scrutiny (9 valid findings applied, all tests passing after each cycle).
- **Review cycles caught real issues**: Valid cycle found 4 bugs (preset guard on resolved refs, job filename collisions, subtask terminal fallback, nil return inconsistency). Fit cycle found 5 issues (path traversal in preset names, missing task-ref validation, sibling/child insertion semantics). These would have reached main without the multi-cycle review.
- **E2E tests passed without friction**: Both ace-assign (2 scenarios, 10 cases) and ace-overseer (1 scenario, 5 cases) passed on first run.
- **Pre-existing test failures identified cleanly**: The ace-docs failure was confirmed as pre-existing by running the same test on clean tree — no false blame.

## What Could Be Improved

- **E2E fork step was opaque**: The verify-e2e fork (step 015) ran for ~22 minutes via codex with no visible progress output. The driver had to poll repeatedly. A heartbeat or progress callback from fork-run would reduce driver anxiety.
- **Commit reorganization was a no-op**: Step 130 (reorganize-commits) added overhead evaluating 28 commits but concluded no changes needed. For branches where review cycles produce incremental fix commits, the step should detect "already organized by scope" patterns and fast-skip.
- **Task files outside worktree**: Task status updates (mark-tasks-done) couldn't be committed because `.ace-tasks/` lives outside the worktree repo root. This is a known worktree limitation but creates an asymmetry where the step appears to succeed but doesn't produce a commit.
- **Gemini provider unavailable during valid review**: The valid review cycle had gemini:pro-latest fail with 429 (capacity exhaustion). Only 2 of 3 models contributed findings. This didn't block progress but reduced review diversity.

## Key Learnings

### Review Cycle Analysis
- **Valid cycle**: 5 findings extracted, 4 valid (80% precision), 1 false positive (subtask suffix format was intentional). Both claude:opus and codex:gpt contributed unique findings.
- **Fit cycle**: 7 findings extracted, 5 valid (71% precision), 1 invalid, 1 skipped low-priority. Fit caught architectural issues (path traversal, missing validation) that valid missed.
- **Shine cycle**: 8 findings extracted, 3 resolved with code changes (38% conversion), 5 skipped (low-priority polish). Shine's lower conversion rate is expected — it catches diminishing-return improvements.
- **Cross-cycle pattern**: Valid catches bugs, fit catches design gaps, shine catches polish. The three-cycle progression works as designed.

## Action Items

- **Continue**: Fork-based review delegation — the pattern is reliable and produces real quality improvements
- **Continue**: Multi-model review composition — different models catch different issue classes
- **Start**: Add progress heartbeat to fork-run (emit periodic status to a file the driver can tail)
- **Start**: Fast-skip detection for reorganize-commits when commits are already scope-organized
- **Stop**: Polling fork status in sleep loops from the driver — use run_in_background and wait for notification instead

