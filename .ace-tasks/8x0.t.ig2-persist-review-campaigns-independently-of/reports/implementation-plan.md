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

- [x] step_01: Identity, frozen policy/contract, linked successors, durable store and counters. Anchor: task spec Expected Behavior and Readiness decisions. Depends: none. Verify: bin/ace-test ace-review atoms; bin/ace-test ace-review molecules.
- [x] step_02: Source evidence, pinned partial rounds, append-only assessments, current-head/base validity and acceptance. Anchor: SC1-SC4, claim authority and findings. Depends: step_01. Verify: bin/ace-test ace-review organisms.
- [x] step_03: Public CLI modes, existing review preservation, dry-run/replay/restart/concurrency cases. Anchor: SC6 and CLI input and operating modes. Depends: step_02. Verify: bin/ace-test ace-review all.
- [x] step_04: Campaign result consumption by assignment receipt authority. Anchor: SC5 and evidence binding. Depends: step_03. Verify: bin/ace-test ace-assign all.
- [ ] step_05: Packaged usage, workflow adoption, criterion-mapped report and final verification/commits. Anchor: Verification Plan and acceptance mapping. Depends: step_04. Verify: bin/ace-test ace-review all; bin/ace-test ace-assign all; bin/ace-test-suite.

## Test Plan

See adjacent test-plan.md. Use real temporary files and repositories for persistence and receipt integration, pure fixtures for atoms, and fresh public CLI processes for restart and JSON behavior. No paid-provider readiness claim.

## Review-driven owner-layer correction

Independent review at 2092c08ce confirmed three High findings: historical report loss was not checked, preset-only scope binding allowed an unrelated subject, and local check JSON had no acceptance authority. Re-plan: pin scope subject selectors alongside presets and verify the collected subject configuration; validate every retained counted artifact; expose read-only accepted check evidence through ace-assign's existing coordinator and journal owner, consumed by ace-review rather than adding an execution journal or accepting caller-authored check claims. Journal reads must inspect immutable Git objects without creating audit checkouts. Round 2 found that retained partial-attempt artifacts and earlier approvals also need validation; validate every recorded attempt, while only current approval checks are rechecked for live-head authority. Round 3 additionally confirmed missing extraction provenance and fabricated local base commits; persist the existing extractor inventory in campaign session metadata, require matching report/finding inventories, and validate local commit objects. Source inspection also found PR delta narrowing; pin its reference in scope identity. Round 4 confirmed local full-scope file subsets, later partial resolved High invalidating earlier approval, and absent optional campaign fields altering ordinary digests. Enforce reserved local full-diff scope, block current acceptance on later confirmed High until a completed review, and omit absent optional receipt data without a fallback/migration. Round 5 confirmed filtered full PR manifests, superseded-contract acceptance and duplicate canonical assessments; reuse collector manifests at collection/recording, persist supersession, reject duplicate assessments. Source-based recovery analysis additionally confirmed that normal pending-to-done source updates invalidate retained feedback checksums and cannot be submitted alongside current clean reports. Re-plan at campaign-store/evidence ownership: immutable feedback snapshots and explicit verified terminal assessments of earlier findings, distinct from current scope coverage. Round 6 confirmed that editable metadata alone could certify review execution, unrelated accepted operations could claim test checks, and explicit false/null policy inputs used defaults. Re-plan at the existing ace-assign evidence authority: accepted review-collect receipts bind metadata/report/prompt artifacts; check proof binds the required name to its executed operation. No second journal or runner. Also replace the accidental immutable local-base restriction with latest explicit committed base pins, preserving history and invalidating old evidence. Scope of the task remains R1; no execution runner, forge adapter or R3 policy engine is added.

## Risk Assessment

Primary risk: accepting caller claims or stale artifacts as current evidence. Mitigate with source completion/digest validation, feedback provenance, immutable bindings, distinct producer/reviewer, executed-check artifacts and independent receipt validation. Validate negative controls alongside success. Rollback is path-scoped revert of these commits; no persistent external effect is performed.

## Freshness Summary

Inspected current task spec and ux/usage.md; qjl spec/report; shared source-evidence.md; review/pr workflow; review CLI/options/manager/evidence/feedback reader and validator; assign receipt/coordinator/store models; package manifests and existing tests. All inputs are from source revision 28c62024b. Baselines: review 949 tests (4 skips), assign 740 tests, no failures/errors.
