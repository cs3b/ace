# Simple sessions and release preparation (2026-11-10)

The Captain replaced the 2026-11-04 operating-system isolation contract with a worktree, ordinary process and explicit project/role environment. This document records implementation progress, not VM acceptance.

Baseline: `8db86b703a49b8a73a90ebafe8c0cd755b1bc749`, preserved as `codex/utm-before-simple-sessions-20261110`. Continue on `codex/utm-lab-e2e`; do not rewrite the preceding history. PR #398 was already merged; a new PR will describe this branch's final delta.

## Flat implementation checklist

- [x] Preserve baseline and replace the current task's superseded contract.
- [x] Ordinary native Herdr launch with explicit private environment, installed runtime and role-scoped credentials; remove OS-session service paths.
- [x] Connect work-on/handoff to actual workers and persist identities on existing coworker commissions.
- [x] Accept reports before retirement and continuation; retain restart/duplicate and exact-HEAD merge gates.
- [ ] Local deterministic suites and installed artifact rehearsal; update TS-MONO-003/004 without running VM/model tests.
- [ ] Independent full-delta review, coordinated versions/changelogs, reproducible artifacts and PR/publication queue.

## Acceptance accounting

Local tests and native subprocess probes validate implementation mechanics only. They do not prove model autonomy, five minutes without additional turns, or two clean UTM cycles. Those acceptance criteria remain open. No UTM operation or paid model invocation is authorized for this stage. Publication is prepared, not executed.

The environment file is JSON, private (`0600`) and contains only selected role values plus runtime variables. The native process reads it without shell evaluation and clears ambient environment. Model credentials are copied into a private session directory. Static repository-scoped tokens are not revoked when one session ends; temporary grants use existing provider/LeaseStore cleanup. Same-UID sessions are trusted peers, not a hostile-code sandbox.

## Evidence

- Forgejo normalized issue body/labels: 197 tests / 1005 assertions, 0 failures, report `f930b0b2-8ce9-4d89-9680-5384a25be372`.
- Local ace-lab simplification: 784 tests / 3708 assertions, 0 failures, 4 existing capability skips, report `bdfc8140-4db9-47e6-abdf-43305a9d26e7`.
- Harness configuration checks: 114 tests / 448 assertions, 0 failures, report `b692fabe-c668-4745-bbbd-a835c9d27b1e` (before subsequent integration corrections; not VM execution).

## Release version decision

Keep the already unpublished `ace-assign 0.73.2`, `ace-herdr 0.10.0` and `ace-support-config 0.18.4`. Prepare minor feature releases for coworker 0.9.0, git 0.33.0, git-forgejo 0.9.0, lab 0.15.0, overseer 0.29.0 and wake 0.3.0. Prepare patch fixes for git-worktree 0.27.4, handbook-integration-pi 0.8.1, hitl 0.25.1, llm-providers-cli 0.36.3, review 0.62.3, runtime 0.4.2, support-items 0.15.17, task 0.41.1, test-runner 0.28.2 and test-runner-e2e 0.43.1. These 19 packages have shipping changes against main; monorepo-e2e is repository test infrastructure, not a gem. Registry versions were checked before selecting these new versions. No existing published version's artifact will be overwritten.

## Final local verification before packaging

- Default deterministic monorepo suite: **53 packages passed, 13,398 tests passed, 42 skipped, zero failures/errors; 47,331 assertions**, 143.87 seconds. Core final reports: overseer `a0b3977a-70ee-42c2-90be-38a540cbc391`, coworker `5a1cfef2-1c01-40a6-b00e-f4e58d963f76`, lab `ceed2a5a-9525-48c3-b5ea-74c5aff96173`, herdr `354aee48-6732-4031-bbbf-2ed1e0504135`, harness `ddd967fd-7bb7-4bbd-88dd-ca40fb049d3d`.
- Modified packages fast+feat: 20/21 package results passed; Pi SDK acceptance required correcting scripted clock advancement to match observation cadence. Its final targeted result is recorded separately; no model API is invoked by this scripted SDK test.
- Real child launcher bridge: 10 tests /57 assertions (`f3b26a43`); child receives explicit environment in the actual worktree, reports its session, is reused once, then retired with auth removed and transcript retained.
- Wake JavaScript wrapper: 2 tests /7 assertions (`99aab31d-1003-40e6-95f5-b8ff06e0f55d`); suite's default zero-test wake entry is not counted as extension validation.
- Native: 3,732 passing local tests plus source-builder/changed-path checks; Linux ARM64 output cross-built and verified. See independent native/harness review record.
- History secret scan: one match is the **public Forgejo signing-key fingerprint** in `lab-vm/forgejo/profile.yml`, not a credential. No detected secret in the reviewed match. Release artifacts receive a separate scan after construction.

Platform/provider-dependent skipped tests and VM/model behavior are not treated as passed. No UTM command or paid provider request was run in this stage.
