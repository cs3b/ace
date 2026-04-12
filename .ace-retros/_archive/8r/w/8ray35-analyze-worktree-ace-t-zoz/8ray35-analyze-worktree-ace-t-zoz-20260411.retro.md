---
id: 8ray35
title: analyze-worktree-ace-t-zoz-20260411
type: standard
tags: [worktree-analysis, fleet-retro, spec-quality]
created_at: "2026-04-11 22:43:31"
status: active
---

# analyze-worktree-ace-t-zoz-20260411

## What Went Well
- Completed-assignment discovery worked cleanly in single-worktree mode for `/home/mc/ace-t.zoz` (3 completed assignments found: `8qsw5q`, `8quzta`, `8quzsd`).
- Assignment `8qsw5q` preserved strong execution evidence: planned task work, multi-cycle review, package tests, suite tests, E2E reruns, task closure, and retro creation.
- Review pipeline produced actionable results early (valid/fit), with explicit triage notes and commit references for applied fixes.
- Verification coverage for the main rollout was strong: modified-package tests, full monorepo suite, and explicit reruns for failing E2E scenarios.

## What Could Be Improved
- Residual drift after lockpoint was high for `8qsw5q` (`282` changed files after lock commit `42c440bad16458193b359fff828fee5ffdaa5203`), which makes completion boundaries harder to audit.
- Two high-severity role-routing findings were deferred across multiple review cycles (valid/fit/shine), indicating design follow-up was not promoted into an explicit tracked assignment step.
- Review cycles showed diminishing returns: most shine-cycle items were non-blocking polish, while core findings repeated from earlier cycles.
- Completion status semantics for fixture assignment `8quzsd` (`completed 4/5`) remain ambiguous and should be normalized for analytics reliability.

## Assignment Scope vs Outcome
### `8qsw5q` (primary analyzed assignment)
- Planned scope evidence:
  - Task `8qr.t.zoz.0`: add role resolution pipeline in `ace-llm`.
  - Task `8qr.t.zoz.1`: migrate repo config surfaces to roles-first selectors.
- Outcome evidence:
  - Role resolution implemented (`RoleConfig`, `RoleResolver`, parser integration, registry checks).
  - Broad config/default migration completed across packages and docs.
  - Tasks marked done and archived in `155-mark-tasks-done.r.md`.
  - Lockpoint reached at `160-create-retro.r.md` (`2026-03-29T23:37:59Z`).
### `8quzta` and `8quzsd` (fixture/lifecycle completions)
- Both finished quickly with lightweight reports and limited telemetry depth.
- These contributed completion markers but low-value scope evidence compared with `8qsw5q`.

## Post-Completion Residual Work
- Lockpoint commit for `8qsw5q`: `42c440bad16458193b359fff828fee5ffdaa5203`.
- Residual delta `42c...HEAD`: `282` files changed (high drift), concentrated in later backlog work (docs, workflows, package updates, test assets, and additional retros/tasks).
- Lockpoint commit for fixture completions (`8quzta`/`8quzsd`): `66f59d4c3079562bca1f0cc78ca3957e6193ecbf`.
- Residual delta `66f...HEAD`: `46` files changed (medium drift), mostly subsequent maintenance and follow-up updates.

## Review Cycle Telemetry
- Cycle structure for `8qsw5q`: valid (`040`), fit (`070`), shine (`100`) with 3 reviewers each.
- Item volume by cycle:
  - valid: 8 items (2 fixed, 1 invalid, 5 skipped/deferred)
  - fit: 7 items (1 fixed, 2 invalid, 4 skipped/deferred)
  - shine: 9 items (all non-blocking; no code changes)
- Key pattern: correctness findings concentrated in valid/fit; shine primarily repeated or polish-only feedback.

## Test Verification Telemetry
- Task-level package verification passed after targeted expectation updates:
  - `8qr.t.zoz.0`: `ace-llm` profile run clean.
  - `8qr.t.zoz.1`: all modified packages green after two expectation fixes (`ace-prompt-prep`, `ace-task`).
- Full suite checkpoint (`012`): `7578` tests, `19865` assertions, `0` failures, `0` errors.
- E2E checkpoint (`015`): initial suite failures in 3 scenarios, all recovered via artifact-driven reruns with final PASS across each previously failing scenario.

## Ranked Spec Recommendations
1. Add a mandatory "deferred-high-finding disposition" step before release/retro lockpoint in assignment workflows.
   - Evidence: repeated deferred high findings across valid/fit/shine for role-resolution consumers.
2. Add residual-drift guardrails to completion.
   - Evidence: `282` post-lockpoint changed files after `8qsw5q` completion boundary.
3. Add review-cycle stop heuristics.
   - Evidence: shine cycle produced no code changes and mostly duplicated/deferred findings.
4. Normalize assignment completion semantics for analytics.
   - Evidence: fixture assignment `8quzsd` reported `completed` with `4/5` progress, creating ambiguity in fleet aggregation.

## Action Items
- Start: Inject a required workflow checkpoint to either fix or explicitly spawn follow-up tasks for all deferred high-severity review findings.
- Start: Define and enforce a residual-drift budget (file-count and risk-band thresholds) after lockpoint before marking assignment complete.
- Continue: Keep valid/fit first in review cycles; they produced the highest signal and directly drove code fixes.
- Stop: Running shine cycles by default when prior cycle outputs are duplicates/non-blocking and no new risk vectors are introduced.
