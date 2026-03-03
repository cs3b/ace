---
id: 8pnrrf
title: E2E Analyze-First, Timeout, and Rerun Policy
type: conversation-analysis
tags: []
created_at: '2026-02-24 18:30:27'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8pnrrf-e2e-analyze-first-timeout-and-rerun-policy.md"
---

# Reflection: E2E Analyze-First, Timeout, and Rerun Policy

**Date**: 2026-02-24
**Context**: Stabilizing E2E execution after big-bang E2E rewrite and repeated expensive reruns
**Author**: codex
**Type**: Conversation Analysis

## What Went Well

- We separated real tool bugs from scenario/spec defects using failure artifacts instead of guessing.
- We fixed one concrete product bug found by E2E (`ace-git-worktree` filtered listing stats mismatch).
- We improved E2E workflow semantics: `fix` now explicitly depends on `analyze-failures`.
- We updated scenario instructions to remove ambiguity and reduce false failures in assign/bundle/secrets/review.
- We confirmed CLI provider execution path is runner+verifier pipeline mode (not legacy skill mode wording/flow).

## What Could Be Improved

- Suite reruns were started before all actionable fixes were batched, causing avoidable cost.
- Provider timeouts at 420s and then 600s consumed full scenario budgets without producing verdict-quality output.
- Progress-mode ANSI output made investigation noisy and hid useful diagnostics.
- Some E2E failures were initially treated as implementation issues before analysis proved they were test-spec issues.

## Key Learnings

- E2E failures must be classified first: `code-issue`, `test-issue`, `runner-infrastructure-issue`.
- E2E should be operated with the same fast-loop philosophy as unit tests:
  - local/PR loop = targeted scope only (`scenario` or `--only-failures`)
  - full-suite loop = CI or explicit big-batch stabilization point
- Runner/verifier pipeline quality is strongly affected by timeout and provider availability; infrastructure failures must not be conflated with product regressions.

## Conversation Analysis (For conversation-based reflections)

### Challenge Patterns Identified

#### High Impact Issues

- **Premature Expensive Reruns**: Suite reruns were triggered while multiple known fixes were still pending.
  - Occurrences: Multiple in this thread
  - Impact: 10+ minute cycles with low incremental signal
  - Root Cause: Missing strict rerun gate tied to completed analysis/fix batch

- **Provider Timeout Saturation**: Several scenarios terminated at timeout boundary (420s, then 600s).
  - Occurrences: Repeated across suite attempts
  - Impact: Scenarios ended with infrastructure errors and 0 TC evidence
  - Root Cause: End-to-end agent execution cost + provider responsiveness + large scenario payload

#### Medium Impact Issues

- **Spec Ambiguity in E2E Cases**: Command forms and expectations allowed mis-execution.
  - Occurrences: Across assign/bundle/secrets/review scenarios
  - Impact: False negatives and rework

- **Output Noise**: Progress display generated very large ANSI streams.
  - Occurrences: Continuous in suite mode
  - Impact: Slower diagnosis, harder extraction of root-cause signals

#### Low Impact Issues

- **Terminology Drift**: Historical "skill mode" wording persisted in discussions.
  - Occurrences: Single thread confusion
  - Impact: Low, but led to extra verification steps

### Improvement Proposals

#### Process Improvements

- Enforce analyze-first gate before fix execution for E2E/test workflows (implemented).
- Adopt "fix-all-known, rerun-once" policy for local E2E iteration.
- Require rerun scope decision in analysis output:
  - scenario
  - package
  - suite (CI or big-batch only)

#### Tool Enhancements

- Add fail-fast infrastructure detection in suite run:
  - if timeout/provider errors dominate, stop remaining local suite workers and report infra-only state.
- Add compact progress mode with periodic snapshots instead of full redraw logs.
- Add E2E "smoke" subset command for <10 minute local health checks.

#### Communication Protocols

- At each E2E failure phase, explicitly answer:
  - Is this test issue or implementation issue?
  - What is the smallest rerun scope that can validate this fix?
  - Is this rerun worth the cost now?

### Token Limit & Truncation Issues

- **Large Output Instances**: Progress-mode output produced repeated screen redraws and truncated tool output.
- **Truncation Impact**: Harder to spot first concrete failure reason quickly.
- **Mitigation Applied**: Switched to artifact-first diagnosis (`summary.r.md`, `metadata.yml`, report dirs) and process inspection.
- **Prevention Strategy**: Prefer non-progress logging for diagnostics; use targeted report reads over raw stream polling.

## Action Items

### Stop Doing

- Running full E2E suite repeatedly during active fix iteration.
- Treating timeout-driven failures as code regressions without analysis evidence.

### Continue Doing

- Analyze first, then apply scoped fixes by category.
- Run deterministic local tests for touched codepaths before expensive E2E reruns.
- Use `--only-failures` when rerun is needed.

### Start Doing

- Run full E2E suite mainly in CI and at end of major change batches.
- Define a local "fast E2E" policy:
  - scenario rerun by default
  - package rerun only when shared fixtures/runner behavior changed
  - full suite only for release readiness / CI gate
- Track timeout budget by provider and adjust default timeouts + parallelism with measured data.

## Technical Details

- Product fix:
  - `ace-git-worktree`: filtered list stats now computed from filtered set.
- Test/spec fixes:
  - `ace-assign` scoped report handling + hierarchy scenario hardening.
  - `ace-bundle` API parity error-path instruction fix.
  - `ace-git-secrets` config path and whitelist instruction fixes.
  - `ace-review` preset-composition subject and verifier criteria hardening.
- Runner/workflow:
  - E2E timeout raised to 600s in project/default config.
  - `fix` workflows updated to require `analyze-failures` first.

## Additional Context

- Related task branch: `280-define-e2e-test-levels-grouping-and-goal-based-execution`
- Triggering concern: expensive reruns with low signal and infra timeouts