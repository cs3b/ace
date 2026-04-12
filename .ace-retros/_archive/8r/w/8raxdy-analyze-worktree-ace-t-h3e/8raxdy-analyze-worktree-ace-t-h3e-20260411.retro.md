---
id: 8raxdy
title: analyze-worktree-ace-t-h3e-20260411
type: standard
tags: [worktree-analysis, fleet-retro, spec-quality]
created_at: "2026-04-11 22:15:30"
status: active
---

# analyze-worktree-ace-t-h3e-20260411

## What Went Well

- The target worktree `/home/mc/ace-t.h3e` contains a fully completed assignment (`8r4i7n`) with explicit completion lockpoint artifacts: `155-mark-tasks-done.r.md` and `160-create-retro.r.md`.
- Scope decomposition for the primary batch was explicit and traceable through task references (`8r4.t.h3e.0` through `8r4.t.h3e.4`) and per-child reports.
- Review telemetry was available and structured in `.ace-local/review/sessions/*/metadata.yml` and `feedback-synthesis.cleaned.json`, which enabled recurrence analysis across cycles.

## What Could Be Improved

- Completed assignment detection is uneven across historical assignments: `8r6jhh` is terminal (`all step statuses = done`) but does not include lockpoint markers (`155/160`), reducing comparability.
- Post-completion drift after the `8r4i7n` lockpoint is large and mixed-domain, indicating scope bleed after formal completion.
- Test telemetry under `.ace-local/test/reports` was not populated with machine-readable summaries, leaving verification trends under-instrumented for this worktree.

## Key Learnings

### Assignment Scope vs Outcome

- Worktree analyzed: `/home/mc/ace-t.h3e` (single-worktree mode).
- Assignments discovered: 17.
- Terminal assignments (all steps terminal): 2 (`8r4i7n`, `8r6jhh`).
- Assignments analyzed with canonical completion lockpoint evidence: 1 (`8r4i7n`).
- `8r4i7n` lockpoint evidence:
  - Lock step: `160-create-retro.st.md`
  - Lock timestamp: `2026-04-07T17:53:32Z`
  - Lock commit: `48f8db8f989b9f0f1cd68f51f1bf05aa7a55db3e`

Planned scope signals were strongest for `8r4i7n` through task-based batch structure and explicit child work units (`8r4.t.h3e.0..4`), with completed execution evidence present for each child branch.

### Post-Completion Residual Work

Residual diff window used: `48f8db8f989b9f0f1cd68f51f1bf05aa7a55db3e..HEAD` in `/home/mc/ace-t.h3e`.

Observed residual drift characteristics:
- High-volume post-lockpoint file churn across:
  - `.ace-retros/` (new retros and archives)
  - `.ace-tasks/` plus `_archive` migrations
  - multiple package directories (`ace-assign`, `ace-task`, `ace-review`, `ace-demo`, `ace-lint`, etc.)
- Risk classification:
  - High: lifecycle-critical file families changed after completion (`CHANGELOG.md`, release/workflow instruction surfaces, assignment runtime code paths)
  - Medium: docs/usage and skill metadata alignment updates
  - Low: comment/format/doc housekeeping

Interpretation: The completion lockpoint was not treated as a stable boundary for subsequent unrelated modifications.

### Review Cycle Telemetry

Sessions with synthesis artifacts in scope: 3
- `review-8r6luj`: 2/2 models succeeded, findings=4
- `review-8r6m54`: 2/2 models succeeded, findings=4
- `review-8r6mju`: 1/2 models succeeded, findings=3 (one provider failure due to role typo `review-geminie`)

Total findings captured in cleaned synthesis artifacts: 11
Recurring high-signal themes:
- Canonical skill metadata/header compliance gaps
- Step resolution and source-mapping correctness (source vs display-name/template lookups)
- Validator/schema drift vs migrated assign-step fields
- Project override preservation issues during catalog migration

### Test Verification Telemetry

- `.ace-local/test/reports` directory existed but contained no report files for machine aggregation.
- Result: pass/fail trend and regression window could not be quantified from telemetry artifacts alone.
- Coverage gap should be addressed to support deterministic retro analytics.

## Ranked Spec Recommendations

1. Enforce lockpoint completeness contract
- Require a canonical completion marker profile for any assignment considered analyzable (`mark-tasks-done` + `create-retro` or equivalent explicit lockpoint metadata).
- Reject terminal-but-unmarked assignments from summary metrics unless downgraded with an explicit confidence tag.

2. Add post-lockpoint drift budget and gate
- After lockpoint commit, require either: zero functional-file drift, or a mandatory follow-up assignment link for each high-risk changed path family.
- Surface drift-budget breaches in assignment status and retro generation.

3. Normalize review role identifiers before execution
- Validate configured review role slugs prior to run (`review-geminie`-style typo prevention).
- Fail-fast with remediation hint instead of partial review execution.

4. Tighten skill/catalog source-of-truth checks
- Add invariant checks that migrated assign-step fields and internal skill headers remain schema-valid across `.codex`, `.claude`, `.gemini`, `.pi`, and package handbook mirrors.
- Include explicit checks that resolution logic uses canonical source identifiers, not display names.

5. Standardize test telemetry export contract
- Require each verification step to emit a normalized summary artifact under `.ace-local/test/reports` (or explicitly record absence and reason).
- Retro analytics should treat missing telemetry as a first-class signal with severity.

## Action Items

- Add a validator rule that flags assignments with terminal steps but no lockpoint marker set.
- Add a drift-check command for `lock_commit..HEAD` and integrate it into completion/post-completion workflows.
- Add review role slug preflight validation in review orchestration.
- Add a test telemetry writer contract to verification workflows and fail when required artifacts are missing.
