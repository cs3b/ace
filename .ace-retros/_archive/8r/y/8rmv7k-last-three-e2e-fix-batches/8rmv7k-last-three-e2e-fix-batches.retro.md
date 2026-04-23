---
id: 8rmv7k
title: last-three-e2e-fix-batches
type: standard
tags: [e2e, retro, harness, testing]
created_at: "2026-04-23 20:48:25"
status: active
---

# last-three-e2e-fix-batches

Date: 2026-04-23
Context: Analysis of the three recent E2E recovery waves after the `ace-assign` `active` lifecycle rollout, focused on how much work fixed real bugs versus harness and retained test-contract issues.

## What Went Well

- The analysis-first E2E workflow kept the debugging grounded in evidence. Each rerun was used to classify failures as product bug, harness bug, or retained test drift before changing code.
- Central fixes in `ace-test-runner-e2e` cleared failures across multiple packages. Restoring verifier fallback, narrowing sandbox git excludes, and later repairing missing required artifacts all paid off beyond a single scenario.
- The later batches mostly aligned retained E2E contracts to real public behavior instead of weakening product behavior to satisfy stale tests. That was the correct direction for `ace-assign` and `ace-overseer`.
- Scoped releases kept the work readable even though the recovery waves crossed multiple packages and included both shared harness code and package-level retained scenarios.

## What Could Be Improved

- The `active` lifecycle rollout changed a public contract, but the downstream retained E2E sweep did not ship in the same unit. That created a cascade where each suite rerun exposed the next stale expectation.
- Too many retained scenarios depended on implied runner behavior or undeclared artifact files. When the runner said an artifact was produced but the file was not on disk, the suite looked flaky even when the real problem was a missing contract.
- The quick-start scenario required sandbox shaping that stayed outside the releasable package commits. Leaving non-releasable E2E changes dirty after release made it harder to tell what the suite was actually validating.
- Too much manual triage was needed to separate harness failures from stale verifier logic. The suite still makes that distinction later than it should.

## Key Learnings

- The last three batches were mostly not end-user package bug fixing. Rough split:
  - end-user product behavior bugs: less than 10%
  - shared harness bugs in `ace-test-runner-e2e`: about 30%
  - retained runner/verifier/spec drift: about 60%
- If harness work is counted as bug fixing, then about a third of the work fixed real bugs. If “bug” means user-facing package behavior, almost none of these batches were product regressions.
- The failures were not primarily random flake. Each rerun exposed the next latent issue after the previous shared defect or stale contract was removed.
- Retained E2E tests need two different styles and they should stay distinct:
  - public-surface goal tests should validate the user job from docs/help/CLI
  - retained regression tests should be deterministic, explicit, and artifact-complete
- Any verifier that depends on files must have those files declared as required artifacts. Runner claims are not enough.
- Public contract changes need a retained-E2E grep and downstream sweep in the same change set. The `in_progress -> active`, `current_step -> active_steps`, and `paused + next_step` transitions were correct, but they were costly because the retained suites lagged behind them.

### Batch Breakdown

- Batch 1:
  - real harness fix: restored verifier fallback and deterministic sandbox excludes in `ace-test-runner-e2e`
  - retained test work: tightened `ace-git-secrets` remediation-path expectations and shaped the quick-start sandbox for deterministic bundle execution
- Batch 2:
  - real harness fix: narrowed git excludes to setup-commit scenarios only
  - retained test work: corrected stale `ace-assign`, `ace-git-secrets`, `ace-git-worktree`, and `ace-support-models` scenarios plus the quick-start commit-fallback contract
- Batch 3:
  - real harness fix: added a required-artifact repair pass before verification
  - retained test work: updated `ace-assign` lifecycle/hierarchy scenarios and aligned `ace-overseer work-on` verification to the current prepared-assignment contract

## Action Items

### Stop Doing

- Stop releasing behavior-contract changes without the corresponding retained E2E oracle sweep.
- Stop allowing verifiers to depend on files that are not explicitly declared in the TC artifact contract.
- Stop treating newly exposed failures as likely flake before classifying them.

### Continue Doing

- Continue the analysis-first failure taxonomy and targeted `ace-test-e2e <pkg> <TS-ID>` reruns.
- Continue fixing shared `ace-test-runner-e2e` defects before patching package behavior.
- Continue preserving scoped releases even when the recovery spans harness and retained scenario files.

### Start Doing

- Start a behavior-change checklist for E2E-sensitive work:
  - grep retained `runner.md` and `verify.md` files for old status words, JSON keys, and CLI shapes
  - rerun directly impacted scenarios before release
  - update downstream consumers and retained verifiers in the same change set
- Start requiring exact `results/tc/...` paths for every verifier-dependent artifact.
- Start reporting batch outcomes using three explicit buckets: product bug, harness bug, retained test/spec drift.
- Start treating non-releasable scenario dirt as a release blocker when the suite depends on it.

## Automation Insights

### Identified Opportunities

- Add a lint or review check that every artifact path referenced by `verify.md` is declared in the scenario contract.
- Add a behavior-change helper that scans retained E2E files for renamed status words, JSON keys, and command shapes before release.
- Add suite reporting that summarizes failures by category so repeated sessions can measure whether harness drift or retained-spec drift is shrinking.

## Workflow Proposals

### Workflow Enhancements

- `wfi://e2e/fix`: include a mandatory final summary table with product bug vs harness bug vs retained test drift counts.
- `wfi://release/local`: fail closed when releasable package changes depend on dirty non-releasable E2E scenario files.

## Additional Context

- Primary commit anchors for these batches:
  - `fcd4121f7`, `8979a67f6`
  - `0d68d6945`, `ca815e967`, `0e71f0e62`, `0c0b25e9f`, `31659eff9`
  - `3550dc6a7`, `4e7a19722`, `edb080c5b`
- Related behavior-change context:
  - `3034fd8cd` `feat(ace-assign): introduce an explicit active-step lifecycle`
  - `0ea17eae5` `feat(ace-overseer): adapt work-on status handling to active-step summaries`
