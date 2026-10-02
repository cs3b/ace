---
id: 8x11ke
title: work-on-task-8wr-t-qjx-assignment
type: standard
tags: [assignment, service-receipts, fork-recovery]
created_at: "2026-10-02 01:02:41"
status: active
---

# work-on-task-8wr-t-qjx-assignment

Retrospective for assignment `8x0z1i` (work-on-task 8wr.t.qjx, PR #358): full cycle -- onboard → forked implementation → verify → release prep → docs → PR → reorganize → push.

## What Went Well

- **Fork recovery flow worked end-to-end.** The first fork of subtree 010.01 died on the codex 1800s deadline mid-implementation. The driver-side recovery (reconcile dead attempt → path-scoped partial commit → partial report → recovery-onboard + continue-work injected inside the subtree → re-fork with 3600s timeout) resumed cleanly and the subtree finished 11/11. Injecting recovery children with verbatim original instructions preserved execution rules without context leakage.
- **Receipt-verified coordination held up in practice.** The coordinator rejected a "succeeded" receipt carrying a non-passing check and rejected taskless external-effect receipts -- exactly the fail-closed behavior the task's own design demands. Attempt reconciliation (`running` → `uncertain`) handled the dead-process case without replaying anything.
- **Pre-existing failure disposition had a sound method this time:** run the failing packages on a pristine base worktree (5bdc5c1f8) and compare in-isolation vs suite-mode. Every suite failure was either reproduced on base or proven harness/load-only. No "probably pre-existing" hand-waving.
- **Scope-grouped reorganize produced a clean 5-commit history** suitable for review, and the accidental sweep of unrelated `.ace-tasks` churn was caught and split back out before push.

## What Could Be Improved

- **Large tasks exceed the default fork deadline.** 1800s was consumed by a single `work-on-task` child on a "large" task; the re-fork needed 3600s (and used ~25 of 60 minutes). Deadlines should scale with task size instead of being discovered by crash.
- **`ace-assign add --child` appends after the last existing child.** Recovery steps injected with `--after <failed> --child` would have run after verify/release children (wrong order). The sibling-insert path (`--after <failed>` without `--child`) infers the parent and renumbers downstream, which is what recovery actually needs.
- **Depth limit blocks recovery children under a depth-2 failed step** (max nesting 2), so the documented "inject children of the failed step" recovery pattern is impossible in batch trees; sibling-in-subtree is the only valid injection point.
- **`ace-git diff` defaults to working-tree diff**, so an uncommitted `.ace-tasks` churn can masquerade as "File Changes" for a PR; always pass an explicit range (`origin/main..HEAD`) when building PR evidence.
- **Suite bookkeeping is hard to reconstruct from reports**: stale report dirs (e.g. an old `ace` correctness probe) sit next to fresh ones, and per-package summary keys differ (`failures` vs `failed` vs top-level arrays). It cost several parsing passes to account for 6 failed packages.

## Key Learnings

- Deadline exhaustion ≠ provider unavailability: the codex CLI hit its 1800s deadline doing real work. Classification matters -- recovery re-forks with a longer timeout; provider outages would instead need inline LLM-tool fallback or waiting.
- Attempt lifecycle is strict by design: a taskless attempt cannot record `merge/publish/deploy/release` operations (fail-closed), so verification-only steps must honestly use `verify` as the operation. Receipts need ≥1 artifact with an in-project path (`/tmp` paths are rejected as escaping the project root).
- `recovery-onboard` must enumerate explicit report file paths; the re-forked agent starts with zero context and cannot infer directory structure. This worked as documented.
- The `ace` meta-package's `review_regression_test.rb` probe lives untracked under `.ace-local/` and fails 6/6 identically on base and HEAD -- it predates current runtime APIs and is not part of the committed suite; don't mistake it for a regression.

## Action Items

- **Start**: pass `--timeout` explicitly on fork-run for tasks sized "large" or bigger (3600s baseline), or add size-aware defaults to fork-run.
- **Start**: document the sibling-insertion recovery pattern (and the depth-2 child limitation) in `wfi://assign/recover-fork` so drivers don't rediscover it.
- **Continue**: base-worktree comparison for any suite failure claimed pre-existing; record dispositions in the step report.
- **Stop**: treating a green per-package run as sufficient when the preset also demands `ace-test-suite --target all` -- run both up front, in parallel, to surface suite-mode-only failures earlier.

## Review Cycle Analysis

PR #358 review campaign `8x11ly` (preset code-valid, delivery policy: 3 rounds / 2 consecutive clean):

- **22 collected rounds, 44 confirmed findings, all fixed and pushed.** Severity arc: r1 critical (receipt fabrication) -> r4 2 critical (authorization reuse, evidence TOCTOU) -> r6-r14 highs (claim races, provenance, settlement semantics) -> r15-r22 highs shrunk to symmetry follow-ups of my own fixes; zero Critical after r4.
- **Recurrence pattern:** each fix re-opened an adjacent angle at the journal boundary (settlement semantics alone generated 9 findings across r9-r14). A brand-new privileged surface under one strict correctness reviewer keeps producing real findings; "2 consecutive clean rounds" took >15 rounds and had not converged when the loop stopped.
- **False-positive rate:** 0 invalid findings across 44 items -- every finding verified as a genuine defect. Severity calibration was conservative (mediums were true minors).
- **Stop condition:** the binding Review Model Budget Policy (10 sessions/PR) was exceeded (22 codex sessions). Step 170 was marked failed with evidence rather than running further; the Captain decides between more rounds or accepting with a follow-up task.
- **Process bugs found by the loop itself:** fork 1800s deadline too small for large tasks; campaign pin heads are immutable so any commit between collection and recording burns the round (5 rounds burned this way before the collect-record-immediately discipline emerged); the extraction-inventory writer/reader used different completion predicates (fixed in ace-review 0.57.1+).

