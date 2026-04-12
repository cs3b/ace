---
id: 8rb033
title: synthesis-analyze-worktree-fleet-feedback-20260411
type: standard
tags: [synthesis, worktree-analysis, fleet-retro, spec-quality]
created_at: "2026-04-12 00:03:27"
status: active
---

# synthesis-analyze-worktree-fleet-feedback-20260411

## What Went Well

- The 9 analyzed worktrees all yielded enough assignment evidence to support meaningful retrospective analysis. The strongest repeated enablers were explicit closeout artifacts (`155-mark-tasks-done`, `160-create-retro`), preserved review-session synthesis, and readable verification reports.
- Multi-cycle review was generally valuable. Across the fleet, valid/fit cycles surfaced real implementation defects, integration gaps, and spec ambiguity before final closeout.
- Verification depth was often strong at lockpoint. Several worktrees preserved package-level, suite-level, and E2E evidence that made quality assessment possible instead of speculative.
- `8raxz1` (`x2b`) is the clean counterexample the fleet should emulate: clear lockpoint commit, strong verification, convergent reviews, and zero post-lockpoint drift.

## What Could Be Improved

- Completion lockpoints are not being treated as stable delivery boundaries. Residual drift after `160-create-retro` was the most common systemic issue, often crossing runtime, release, and workflow surfaces.
- Review orchestration still leaks avoidable operational failures into the signal stream. Role typos, provider capacity failures, and missing preflight checks reduced confidence and wasted later review cycles.
- Review cycles are too willing to continue after signal drops. Multiple retros described repeated findings, stale feedback, or shine/polish cycles that produced little new value.
- Telemetry and closeout contracts remain uneven. Some worktrees had excellent review/test evidence; others were harder to analyze because telemetry exports, lockpoint metadata, or retained planning artifacts were incomplete.
- Cross-worktree execution semantics were not explicit enough. Artifact destination, read/write scope, and post-completion artifact hygiene all surfaced as recurring process weaknesses.

## Key Learnings

### 1. Lockpoint hardening is the dominant fleet issue

Seen in 8/9 retros: `h3e`, `hzr`, `j82`, `orn`, `r6b`, `uon`, `zoz`, and by positive contrast `x2b`.

- The fleet needs a hard completion gate that evaluates `LOCKPOINT_COMMIT..HEAD`, classifies changed file families, and blocks or reopens when high-risk residual work exists.
- Terminal status alone is not reliable enough for analytics. Lockpoint completeness, residual classification, and status/report consistency need to be first-class closeout data.
- `x2b` demonstrates the desired end state: clean lockpoint evidence plus zero post-completion drift.

### 2. Review and E2E preflight validation is under-specified

Seen in 6/9 retros: `h3e`, `hzr`, `ilo`, `j82`, `uon`, `x2b`.

- Unknown role names such as `review-geminie`, inactive providers, and capacity failures repeatedly degraded review or E2E signal.
- These failures should be treated as workflow-quality incidents, not left to later retro interpretation.
- The fleet needs preflight validation for role identifiers, required providers, and known fallback policy before model fan-out or E2E execution begins.

### 3. Review-cycle closure and dedupe need an explicit gate

Seen in 6/9 retros: `ilo`, `orn`, `r6b`, `uon`, `x2b`, `zoz`.

- Repeated high/medium findings across cycles indicate that review/apply workflows do not enforce enough closure discipline before launching another cycle.
- Later review passes should require a reason to exist: unresolved medium+ findings, a changed objective, or a newly introduced risk vector.
- Recurrent findings need tracked disposition state (`applied`, `deferred`, `invalid`, `already-fixed`) so the same issue does not keep re-entering the pipeline as fresh work.

### 4. Telemetry contracts are necessary for trustworthy retros

Seen in 5/9 retros: `h3e`, `hzr`, `j82`, `r6b`, `x2b`.

- Review metadata, synthesized findings, test summaries, and lockpoint reports need normalized export contracts if fleet retros are going to be comparable.
- Missing telemetry should be explicit and severity-bearing, not implicit silence.
- Batch child audit artifacts also need longer retention through parent closeout so later analysis can reconstruct planned scope with confidence.

### 5. Cross-worktree workflow semantics must be explicit

Seen in 4/9 retros: `hzr`, `ilo`, `orn`, `x2b`, with related operational evidence in the fleet batch itself.

- Analysis workflows must distinguish input worktree from output destination and prevent accidental artifact creation in disposable analyzed worktrees.
- Cross-worktree operations need explicit read/write scope contracts, ambiguity behavior, and post-completion artifact hygiene rules.
- This is both a workflow correctness issue and an analytics-quality issue because leaked artifacts distort later retrospective reads.

### 6. Secondary but durable themes should be preserved

- `j82` highlighted migration-phase dual-path support and removal gates for E2E/discovery contracts.
- `orn` highlighted mutation-safety, uniqueness, and parallel-safety requirements for cross-worktree features.
- `uon` highlighted scoped provider/status propagation and materialization-path coverage.
- `zoz` highlighted deferred-high-finding disposition and completion-semantics normalization.

## Action Items

1. Add lockpoint residual-drift hardening to assignment closeout. Appeared in 8/9 retros.
- Require a residual diff check before or at `160-create-retro`.
- Classify changed files by risk band and block completion unless high-risk residuals are fixed, explicitly accepted, or split into a follow-up assignment.
- Emit residual classification directly in closeout reports.

2. Add review and E2E preflight validation for roles/providers. Appeared in 6/9 retros.
- Fail fast on unknown role slugs, inactive providers, and missing execution prerequisites.
- Define fallback behavior for provider-capacity failures instead of leaving retries ad hoc.

3. Add a recurring-finding and review-dedupe gate. Appeared in 6/9 retros.
- Require explicit disposition tracking for each finding.
- Block new review cycles or release/retro closeout when recurring high-priority findings remain unresolved without rationale.
- Add stop heuristics so shine/polish cycles do not run by default when earlier cycles are repeating themselves.

4. Standardize telemetry and closeout artifact contracts. Appeared in 5/9 retros.
- Normalize review/session summaries, test-summary artifacts, lockpoint metadata, and batch-child plan retention.
- Treat missing telemetry as first-class evidence in retros rather than an invisible gap.

5. Harden cross-worktree workflow contracts. Appeared in 4/9 retros plus the fleet execution incident.
- Assert output location at retro-create entry points.
- Specify read/write scope parity, ambiguous-ref mutation behavior, and post-completion artifact handling for analyzed worktrees.

6. Preserve targeted subsystem contracts where the fleet surfaced them.
- Keep explicit coverage for scoped provider propagation, migration-phase dual-path behavior, uniqueness guarantees, and assignment completion semantics when those subsystems are touched again.
