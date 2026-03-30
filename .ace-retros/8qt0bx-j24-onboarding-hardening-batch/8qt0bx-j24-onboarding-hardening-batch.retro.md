---
id: 8qt0bx
title: j24-onboarding-hardening-batch
type: standard
tags: []
created_at: "2026-03-30 00:13:16"
status: active
---

# j24-onboarding-hardening-batch

Batch retrospective for 6 tasks (8qs.t.j24.0–5) implementing new-project onboarding hardening across bootstrap, providers, docs, and workflow resolution.

## What Went Well

- **Sequential fork-run execution scaled to 6 tasks**: Each task subtree (onboard → plan → implement → review → test → release → retro) completed end-to-end with minimal driver intervention. Total batch: 48+ subtree steps across 6 tasks.
- **Per-task releases kept packages shippable**: Each task released its own packages immediately after verification, preventing a monolithic release step at the end.
- **Review cycles caught real issues**: 3 review cycles (valid/fit/shine) found and fixed correctness bugs (missing gems in quick-start, generic preset referencing ace-task, credential fallback gaps) plus quality improvements (unused helpers, edge case test coverage).
- **Commit reorganization**: 55 granular commits cleanly compressed to 11 scope-grouped commits via `ace-git-commit` auto-grouping.
- **Test suite stayed green throughout**: 7572 tests, 19870 assertions, 0 failures at the verify-test-suite gate. E2E scenarios all passed (transient failures resolved on rerun).

## What Could Be Improved

- **Provider unavailability in fork subtrees**: Subtree 010.02 failed at plan-task because the codex provider hung 3 times. Recovery required manual inline execution of the plan at driver level, then injection of a retry step and re-fork. The recovery worked but added ~15 minutes of manual driver intervention.
- **Fork exit code with recovered subtrees**: After recovery, fork-run 010.02 exited non-zero because the original failed step (010.02.03) remained marked as Failed even though all work completed via the recovery path. This is a status bookkeeping gap — the subtree is functionally complete but reports failure.
- **Working directory drift after fork**: Fork agents occasionally left the shell cwd inside a subdirectory (e.g., ace-handbook/). The first reorganize-commits attempt failed because of this. Adding a `cd` back to project root fixed it.
- **Orphaned skill projections**: Fork subtree 010.03 left uncommitted skill projection files. The pre-fork guard pattern caught it, but the fork agent should have committed these itself.
- **E2E fork timeout**: The verify-e2e fork timed out at 1800s, even though the agent completed all work. The step was marked Done before the timeout killed the process, so no data was lost, but the exit code was non-zero.

## Key Learnings

- **Plan retrieval guard matters**: The work-on-task step's built-in "Plan Retrieval Guard" (fall back to cached plan if `--content` stalls) proved valuable when the plan-task step failed. The generated plan was still available for the work step.
- **Driver-level inline execution for LLM-tool steps**: The recovery workflow's allowance for inline execution of LLM-tool steps (but not code steps) during provider unavailability is well-designed. It let the driver generate the plan using a different provider (Claude) while preserving fork isolation for code work.
- **Batch continuation without pause**: Treating the batch loop as a single execution unit (no user prompts between children) kept the 6-task batch moving efficiently.

## Review Cycle Analysis

- Review cycles progressed from correctness (valid) → quality (fit) → polish (shine), each catching qualitatively different issues.
- Valid cycle found missing gems and broken contracts; fit found unused code and test gaps; shine applied naming and doc improvements.
- Each cycle produced releases (v0.41.1→v0.41.8 for ace-assign, v0.23.1→v0.23.2 for ace-handbook, v0.31.1→v0.31.2 for ace-llm).

## Action Items

- **Continue**: Sequential fork-run for batch tasks with per-task release — keeps packages shippable and isolates failures.
- **Continue**: 3-cycle review (valid/fit/shine) — catches issues at appropriate abstraction levels.
- **Start**: Add automatic `cd` to project root in post-fork cleanup to prevent working directory drift.
- **Start**: Consider marking recovered subtree steps as "recovered" (not "failed") so fork-run exit codes reflect actual completion state.
- **Stop**: Nothing to stop — the workflow executed as designed with known recovery paths handling edge cases.

