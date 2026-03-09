---
id: 8q8h17
title: nai-compressor-native-inputs
type: standard
tags: [assignment, fork-delegation, provider-issues]
created_at: "2026-03-09 11:21:21"
status: active
---

# Retro: ACE-Compressor Native Source Inputs (Assignment 8q82q0)

## Context

Assignment `8q82q0` implemented 3 tasks adding ACE-native source inputs to ace-compressor: preset/config resolution, protocol support with per-source scope, and error hardening. Used batch fork-delegation with 3 sequential subtrees, followed by test suite verification, PR creation, and 3 review cycles.

## What Went Well

- **Fork delegation for implementation worked smoothly**: Subtrees 010.01 and 010.02 completed autonomously via `ace-assign fork-run` with codex provider. Both produced clean implementations with passing tests and proper releases.
- **Batch container pattern**: Sequential fork execution for dependent tasks (each builds on prior) was the right scheduling choice. Work accumulated cleanly across subtrees.
- **Code review cycle (valid)**: Despite fork failure, the review output was captured and actionable — found a real temp directory leak that was fixed. The inline fallback for LLM-tool phases worked well.
- **Test suite health**: 7457 tests across 32 packages remained green throughout. No cross-package regressions from the ace-compressor changes.
- **Circuit breaker for review cycles**: Correctly applied after fit-cycle provider failure. Avoided wasting time retrying unavailable providers.

## What Could Be Improved

- **Draft status blocking forks (010.03)**: Fork agent was blocked by `as-task-work` skill policy requiring confirmation for draft tasks, even though the task was later set to `in-progress`. The fork agent couldn't write to assignment state to report the failure, creating a double-stuck situation. This wasted 3 fork attempts (~15 min each).
- **Task status not propagated to fork sandbox**: The driver updated task status to `in-progress` but the fork sandbox appeared to read a stale/committed version. The `ace-git-commit` that ran between status update and fork may have committed an older spec state.
- **Fork sandbox write permissions**: Codex sandbox couldn't write to `.ace-local/assign/` to update phase state. This meant forks couldn't even `ace-assign fail` to report their own failures — the driver had to detect failure from exit code and infer cause from agent messages.
- **Provider unavailability in review forks**: Both fit and shine review cycles failed because the codex provider couldn't successfully run `ace-review`. The `codex:max@ro` provider had broken pipe errors, and the synthesis model `glm` was unavailable.
- **Retry phase created at wrong scope**: `ace-assign retry 010.03.04` created a top-level phase 013 instead of a child within the 010.03 subtree, requiring extra cleanup.

## Key Learnings

- **Commit timing matters for fork state**: When using `ace-git-commit` that auto-stages all changes, task spec status changes can be reverted if the commit captures an older version. Solution: commit task status changes separately before committing code, or ensure task status updates happen after code commits.
- **Fork skill policies need assignment-awareness**: The `as-task-work` skill's draft confirmation gate doesn't account for assignment-driven execution where the driver has already validated the task. Forks should inherit driver authorization context.
- **LLM-tool phase inline fallback is practical**: When review forks fail on providers, reading the partial review output and applying findings inline from the driver works well. The fork boundary is less critical for review phases than for code phases.
- **Nesting depth limits constrain recovery**: `ace-assign add --child` at depth 2 hits the max nesting limit of 3, preventing recovery phase injection inside deep subtrees. Recovery phases must be siblings instead.

## Action Items

### Continue
- Sequential fork execution for dependent task batches
- Circuit breaker pattern for provider-failed review cycles
- Inline fallback for LLM-tool phases during provider unavailability
- Committing partial work before re-forking crashed subtrees

### Start
- Mark tasks as `in-progress` (or `pending`) BEFORE creating the assignment, not during fork execution
- Consider adding `--skip-draft-check` or assignment-context propagation to `as-task-work` skill
- Investigate fork sandbox write permissions for `.ace-local/assign/` — forks need to report their own failures
- Commit task status changes in a separate commit before code changes to prevent reversion

### Stop
- Running `ace-git-commit` with auto-staging when task spec status changes are pending — use explicit file lists instead
- Assuming `ace-assign retry` will create phases at the same scope level as the original

