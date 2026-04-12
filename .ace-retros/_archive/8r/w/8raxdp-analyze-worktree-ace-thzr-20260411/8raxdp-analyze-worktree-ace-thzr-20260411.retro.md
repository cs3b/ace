---
id: 8raxdp
title: analyze-worktree-ace-t.hzr-20260411
type: standard
tags: [worktree-analysis, fleet-retro, spec-quality]
created_at: "2026-04-11 22:15:13"
status: active
---

# analyze-worktree-ace-t.hzr-20260411

## What Went Well
- The assignment `8r9itx` reached completion lockpoint cleanly, with closeout evidence in `155-mark-tasks-done.r.md` (`2026-04-10T14:11:47Z`) and `160-create-retro.r.md` (`2026-04-10T14:12:49Z`).
- Verification quality was high at lockpoint: modified-package profile checks passed (`011`) and full regression passed (`012`) with `7,673` tests and `20,180` assertions.
- Multi-cycle review process was effective: valid findings were fixed in earlier cycles and later cycle produced only invalid/no-op findings.

## What Could Be Improved
- Post-completion drift after lockpoint was large: `63` commits and `245` changed files between lockpoint commit `e551186e620d32c31888be9cb5b44abe2faf5c03` and current `HEAD` in `/home/mc/ace-t.hzr`.
- Most residual scope landed in operational metadata and broad migration follow-up (`.ace-tasks: 60`, `.ace-retros: 10`) plus renewed product-code churn (`ace-test-runner-e2e: 44`, `ace-b36ts: 36`, `ace-test-runner: 30`). This indicates lockpoint happened before follow-up scope was stabilized.
- Review provider reliability reduced cross-model signal quality in later cycles:
  - fit cycle: `role:review-gemini` failed with `MODEL_CAPACITY_EXHAUSTED` (429)
  - shine cycle: preset typo `review-geminie` caused immediate unknown-role failure

## Key Learnings
### Assignment Scope vs Outcome
- Planned scope from `010.01.03-plan-task.r.md` centered on deterministic `e2e` target support, scenario-root migration to `test-e2e/scenarios`, shared sandbox helper extraction, and docs/workflow alignment.
- Lockpoint pre-change set around completion was narrow and metadata-weighted (single file in lockpoint commit diff), while substantial implementation and migration continuation occurred after completion, confirming scope spillover into subsequent workstreams.

### Post-Completion Residual Work
- Residual work contains both medium and high risk categories:
  - High: package behavior/versioning/release artifacts (`ace-test-runner*`, `ace-b36ts`, `ace-assign`, `CHANGELOG.md`, `Gemfile.lock`)
  - Medium: extensive task and retro orchestration follow-up (`.ace-tasks`, `.ace-retros`)
- A new untracked retro exists inside analyzed worktree (`/home/mc/ace-t.hzr/.ace-retros/8rattr-analyze-worktree-ace-thzr-20260411/`), which suggests execution-context leakage risk when running analysis repeatedly.

### Review Cycle Telemetry
- Sessions analyzed: `3` (`review-8r9kfh`, `review-8r9kt1`, `review-8r9l0i`)
- Model runs: `6` total, `4` success, `2` failed, aggregate model duration `937.85s`
- Pattern: code-valid produced actionable fixes; later cycles were increasingly constrained by provider/config failures rather than code quality defects.

### Test Verification Telemetry
- `011 verify-test`: targeted package profile verification passed (no failures in reported packages).
- `012 verify-test-suite`: full suite passed across 32 packages.
- `013 verify-test`: explicitly skipped as duplicate; this was acceptable because no package code changed after the prior successful checks.

## Ranked Spec Recommendations
1. Add a lockpoint hardening gate before `mark-tasks-done`/`create-retro`: require a short post-lockpoint delta check (commit count + changed file families) and block completion if above threshold.
2. Add review preset preflight validation: fail fast if role names are undefined (e.g., `review-geminie`) before starting review cycle.
3. Add provider-failure policy codification in review workflows: if secondary reviewer fails for capacity reasons, record degraded confidence and schedule mandatory retry window or explicit waiver.
4. Add residual-scope classification section to assignment closeout report (`155`/`160`) so completion records include high/medium/low drift evidence by file family.
5. Add analysis-context guard for retro workflows: verify output branch/worktree target and prevent accidental artifact creation in analyzed worktree unless explicitly requested.

## Action Items
- Update assignment closeout workflow to include post-lockpoint drift thresholds and stop conditions.
- Patch review presets with role schema validation test coverage.
- Add deterministic telemetry summary generator for `.ace-local/review/sessions/*/metadata.yml` and `.ace-local/test/reports/*` to standardize retro evidence.
- Add a one-line worktree-target assertion at retro-create entry points to prevent cross-worktree artifact leakage.
