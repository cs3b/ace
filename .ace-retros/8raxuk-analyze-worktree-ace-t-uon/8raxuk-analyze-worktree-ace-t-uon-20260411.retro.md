---
id: 8raxuk
title: analyze-worktree-ace-t-uon-20260411
type: standard
tags: [worktree-analysis, fleet-retro, spec-quality]
created_at: "2026-04-11 22:33:58"
status: active
---

# analyze-worktree-ace-t-uon-20260411

## Worktree
- Analysis source: `/home/mc/ace-t.uon`
- Assignment analyzed: `8qrzbz` (`work-on-task-t.uon-95901924-job.yml`)
- Assignment state: completed (`34/34 done`)
- Lockpoint report: `160-create-retro.r.md` at `2026-03-29T00:38:26Z`
- Lockpoint commit from report: `1b3e05d60`

## What Went Well
- Original scope for per-step fork provider override was explicit and test-driven in task spec `8qr.t.uon`.
- Feature implementation landed with broad package validation: `ace-assign` (523 tests), `ace-overseer` (144), and monorepo suite (7553) all passing.
- Review loop caught real defects before final lockpoint, including provider propagation gaps and scoped status provider visibility.
- E2E verification recovered from provider timeout by retrying with an alternate provider (`glite`) and produced passing results.

## What Could Be Improved
- Spec did not fully constrain fork-provider behavior for scoped status in child-step views; this gap surfaced in review rather than up-front design.
- Repeated medium/low findings across review cycles indicate incomplete closure heuristics (same patterns reappeared).
- Significant post-lockpoint churn occurred after completion, making lockpoint-to-head drift high and reducing confidence that final state matches assignment scope.

## Key Learnings
- Per-step provider resolution is easy to regress when context propagation has multiple materialization paths (catalog-backed vs explicit skill/workflow definitions).
- Status UX must report effective provider at scoped root, not only the active leaf step, or operators get misleading execution expectations.
- Review model mix was useful for signal diversity, but speed varied materially: `claude-opus-ro` fastest (avg 42.36s), `codex-gpt-ro` slowest (avg 141.06s).
- Recurrent low/medium findings (normalization duplication, dead symbol fallback, merge semantics ambiguity) are maintainability debt indicators, not one-off nits.

## Assignment Scope vs Outcome
- Planned objective: add `fork.provider` support and precedence chain `CLI > step > config > default`, including status JSON/display and docs.
- Delivered outcome: implementation, docs, and tests landed; task marked done (`155-mark-tasks-done.r.md`).
- Coverage status: primary scope achieved. Review cycles still flagged additional correctness and clarity issues that required follow-up refinements.

## Post-Completion Residual Work
- Residual boundary: commit `1b3e05d60` (retro lockpoint) -> `HEAD` in `/home/mc/ace-t.uon`.
- Observed drift: broad repository-level changes across many packages and release/version files after lockpoint.
- Risk classification:
  - High: release/version/changelog waves across many gems (`*/version.rb`, `*.gemspec`, `CHANGELOG.md`) can obscure feature-specific verification state.
  - Medium: workflow and skill guidance updates can change execution semantics after assignment completion.
  - Low: documentation and idea/task-spec updates not directly affecting runtime behavior.
- Additional local residual state: uncommitted modification present in analyzed worktree (`ace-assign/docs/demo/fork-provider.tape.yml`).

## Review Cycle Telemetry
- Review sessions parsed: 3 (`review-8qs03d`, `review-8qs0c8`, `review-8qs0jm`)
- Model runs: 8 total, all successful
- Findings synthesized: 16 total (`high: 2`, `medium: 6`, `low: 8`)
- Recurrent themes across sessions:
  - Dead symbol fallback in `Step#fork_provider`
  - Duplicate fork option normalization across parser/model
  - Ambiguous overwrite semantics in executor fork propagation paths
  - Scoped status provider inheritance visibility mismatch

## Test Verification Telemetry
- Unit/package verification (`012-verify-test-suite.r.md`):
  - `ace-assign`: 523 tests, 1682 assertions, 0 failures
  - `ace-overseer`: 144 tests, 540 assertions, 0 failures
  - `ace-test-suite`: 32 packages, 7553 tests, 19793 assertions, all passing
- E2E verification (`015-verify-e2e.r.md`):
  - Initial provider timed out (`claude:haiku@yolo`)
  - Retry with `glite` passed for both `ace-assign` and `ace-overseer`

## Ranked Spec Recommendations
1. Add scoped-provider status contract tests in spec and acceptance criteria.
   - Evidence: high-priority findings in `review-8qs0c8` and `review-8qs0jm` on scoped root provider visibility.
2. Require explicit propagation tests for all step materialization paths (catalog, explicit `skill`, explicit `workflow`).
   - Evidence: high-priority finding in `review-8qs03d` on context loss in explicit resolver branches.
3. Introduce a "recurring finding gate" after second review cycle.
   - Evidence: repeated medium/low findings across all synthesis outputs.
4. Define a lockpoint drift budget and auto-flag when post-completion commit/file deltas exceed threshold.
   - Evidence: extensive lockpoint-to-HEAD drift after assignment completion.
5. Add provider fallback resiliency guidance to E2E specs.
   - Evidence: first provider timeout recovered only via manual retry path in step `015`.

## Action Items
- Add/strengthen spec examples for scoped status provider inheritance and explicit workflow/skill context propagation.
- Add a checklist item in review/apply workflows to resolve recurring medium findings before marking final review cycle done.
- Pilot lockpoint drift metrics in future worktree-analysis retros (commit count, file-family risk bands, uncommitted state).
- Extend E2E guidance to document provider fallback retry policy as first-class behavior.
