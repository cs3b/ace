# Implementation plan: t.ig2

## Task Summary

Persist review history in ace-review independently of assignment execution receipts. Historical convergence survives head drift; acceptance requires current independent review and passing executed checks.

## Execution Context

Worktree: `.ace-wt/codex-t-ig2-review-campaigns`, branch `codex/t-ig2-review-campaigns`, source `28c62024b`. qjl is done. No ace-assign assignment was created by the direct as-task-work invocation. Automated plan generation failed with Codex CLI exit 1, unavailable Gemini CLI, and Claude CLI exit 1; this source-based plan is the documented fallback.

Use ATOM layers, explicit requires, config defaults, path-scoped ace-git-commit and bin/ace-test. ace-review owns campaign history; ace-assign remains the sole receipt/attempt authority. No new execution journal, forge adapter, loop runner, merge or publication.

## Technical Approach

Store digest-checked campaign records with append-only rounds/assessments, flock serialization and atomic fsynced replacement. Rebuild projections from records after restart. Freeze subject, requirements bytes and policy. Link successor contracts while carrying findings for disposition. Separate logical rounds from recording attempts and provider/report counters. Validate session completion, reports/checksums, scope/head/base identity and verified feedback. Snapshot findings so mutable feedback files cannot erase accepted history. Recheck current artifacts at status/finish; stale/missing evidence blocks acceptance but cannot reset history. Campaign result is a local artifact; an assignment accepts it only through its existing receipt verifier and coordinator.

## File Modifications

Create campaign contract/projection atoms, campaign store/evidence molecules, campaign manager organism, campaign registry and command classes under ace-review/lib. Add owning tests in test/fast and public subprocess cases. Modify ace-review CLI dispatch before array preprocessing; add configuration, packaged usage and workflow references. Add ace-assign consumer validation at its receipt boundary with a declared dependency and integration tests. Update changelogs and task reports.

## Plan Checklist

- [ ] step_01: Identity, frozen policy/contract, linked successors, durable store and counters. Anchor: task spec Expected Behavior and Readiness decisions. Depends: none. Verify: bin/ace-test ace-review atoms; bin/ace-test ace-review molecules.
- [ ] step_02: Source evidence, pinned partial rounds, append-only assessments, current-head/base validity and acceptance. Anchor: SC1-SC4, claim authority and findings. Depends: step_01. Verify: bin/ace-test ace-review organisms.
- [ ] step_03: Public CLI modes, existing review preservation, dry-run/replay/restart/concurrency cases. Anchor: SC6 and CLI input and operating modes. Depends: step_02. Verify: bin/ace-test ace-review all.
- [ ] step_04: Campaign result consumption by assignment receipt authority. Anchor: SC5 and evidence binding. Depends: step_03. Verify: bin/ace-test ace-assign all.
- [ ] step_05: Packaged usage, workflow adoption, criterion-mapped report and final verification/commits. Anchor: Verification Plan and acceptance mapping. Depends: step_04. Verify: bin/ace-test ace-review all; bin/ace-test ace-assign all; bin/ace-test-suite.

## Test Plan

See adjacent test-plan.md. Use real temporary files and repositories for persistence and receipt integration, pure fixtures for atoms, and fresh public CLI processes for restart and JSON behavior. No paid-provider readiness claim.

## Risk Assessment

Primary risk: accepting caller claims or stale artifacts as current evidence. Mitigate with source completion/digest validation, feedback provenance, immutable bindings, distinct producer/reviewer, executed-check artifacts and independent receipt validation. Validate negative controls alongside success. Rollback is path-scoped revert of these commits; no persistent external effect is performed.

## Freshness Summary

Inspected current task spec and ux/usage.md; qjl spec/report; shared source-evidence.md; review/pr workflow; review CLI/options/manager/evidence/feedback reader and validator; assign receipt/coordinator/store models; package manifests and existing tests. All inputs are from source revision 28c62024b. Baselines: review 949 tests (4 skips), assign 740 tests, no failures/errors.
