---
id: 8r7tq6
title: e2e-sandbox-and-scenario-contract-stabilization
type: standard
tags: [e2e, sandbox, llm, release, ace-test-runner-e2e, ace-assign]
created_at: "2026-04-08 19:49:05"
status: active
---

# e2e-sandbox-and-scenario-contract-stabilization

**Date**: 2026-04-08
**Context**: Branch retrospective for `fix/e2e` and PR `#285`, covering the E2E stabilization work across sandbox execution, LLM fallback behavior, scenario contracts, and incremental package releases.
**Author**: Codex
**Type**: Standard

## What Went Well

- Isolated the highest-impact infrastructure failure early: repo-root and sandbox-root semantics were mixed, and introducing `ACE_E2E_SOURCE_ROOT` gave the E2E harness a stable contract.
- Split runner, verifier, and reporter responsibilities cleanly enough to make failures diagnosable instead of blending provider, prompt, and scenario errors together.
- Fixed the `ace-llm` fallback path at the right layer by recomputing provider-specific execution options per fallback target instead of trying to patch symptoms in each scenario.
- Tightened E2E evidence quality over time. Stopping scenarios after setup failure and demanding direct before/after artifacts reduced false narratives from partial runs.
- Narrow scenario reruns were effective. The branch moved from broad suite instability to isolated contract mismatches in `ace-assign` and `ace-monorepo-e2e` without large product rewrites.

## What Could Be Improved

- Too many releases happened while the active failure set was still moving. Shipping incremental stabilization changes was sometimes useful, but it also increased bookkeeping and made the branch history harder to reason about.
- Several E2E scenarios had drifted far from the current CLI contracts. The biggest offenders were around `ace-assign finish`, `ace-task show`, and assumptions about `ace-config diff`.
- Some verifiers were asserting inferred behavior instead of captured behavior. The final `TS-ASSIGN-002` fix showed the runner was not even producing the descendant cascade event that the verifier claimed to validate.
- Docs and E2E coverage drifted independently until the quick-start path was explicitly realigned. That should have been caught earlier by stronger scenario ownership rules.

## Key Learnings

- “E2E is failing” was not one bug. This branch exposed a stack of unrelated failure classes:
  - sandbox/source-root contract bugs
  - provider fallback and role-resolution bugs
  - stale scenario command contracts
  - weak verifier/oracle design
- Path semantics need to stay explicit:
  - `PROJECT_ROOT_PATH` is the sandbox root for command execution
  - `ACE_E2E_SOURCE_ROOT` is the repo root for setup/bootstrap reads
- Presets are the right place for provider policy. The branch repeatedly reinforced that `ace-llm` should not accumulate hidden provider-specific abstraction knobs that duplicate preset behavior.
- Scenario evidence must prove the claimed behavior directly. If a runner does not create and capture the event, the verifier should not infer it from partial file listings or generic output.
- Incremental release discipline needs a clearer rule on stabilization branches. Releasing while still actively shrinking the failure set is acceptable only when the scope is explicit and the remaining failures are known to be out of scope.

## Action Items

### Stop Doing

- Releasing intermediate E2E-fix snapshots without checking whether the currently targeted failure batch is actually closed.
- Writing E2E verifiers that depend on indirect or ambiguous evidence when the runner could capture direct before/after artifacts.
- Using `PROJECT_ROOT_PATH` as a stand-in for repo-root setup reads.

### Continue Doing

- Fixing E2E failures in narrow scenario batches instead of jumping back to whole-suite reruns.
- Treating environment and harness bugs before assuming package behavior regressions.
- Using path-scoped commits and releases so unrelated background state does not get swept into stabilization work.

### Start Doing

- Add an E2E authoring checklist covering:
  - source-root vs sandbox-root usage
  - artifact naming discipline
  - required before/after evidence for behavioral claims
- Add a stabilization-branch release gate: do not cut another release until the currently targeted failing batch is green or explicitly declared out of scope.
- Convert the `ace-llm` sandbox-abstraction cleanup draft (`8r6.t.z6e`) into follow-up implementation work so presets remain the single policy surface.

## Workflow Proposals

### Workflow Enhancements

- **Existing Workflow**: `e2e/fix.wf.md`
  - Enhancement: Add an explicit decision step to classify each failure as environment, implementation, or scenario-oracle drift before any edits.
  - Rationale: This branch lost time when multiple failure classes were treated like one root cause.
  - Impact: Faster convergence and fewer mis-scoped fixes.

- **Existing Workflow**: `release/publish.wf.md`
  - Enhancement: Add guidance for active stabilization branches that are still shrinking a failure batch.
  - Rationale: The current workflow supports release mechanics, but not the decision of when repeated patch releases are justified during E2E stabilization.
  - Impact: Cleaner release timing and less branch churn.

## Tool Proposals

### Enhancement Requests

- **Existing Tool**: `ace-test-runner-e2e`
  - Enhancement: Add a small scenario-authoring guide or helper convention for direct artifact capture patterns, especially for before/after filesystem or step-state evidence.
  - Use case: Prevent verifier drift like the final `TS-ASSIGN-002` case, where the runner never produced the claimed cascade evidence.
  - Workaround: Hand-maintain runner/verifier discipline in each scenario.

## Additional Context

- PR: `#285` — `bugfix: stabilize e2e sandbox execution and scenario contracts`
- Branch: `fix/e2e`
- Related task draft: `8r6.t.z6e` — remove the `ace-llm` sandbox abstraction in favor of presets
