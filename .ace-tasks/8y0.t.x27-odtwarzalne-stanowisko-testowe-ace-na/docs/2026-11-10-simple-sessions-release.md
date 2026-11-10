# Simple sessions and release preparation (2026-11-10)

The Captain replaced the 2026-11-04 operating-system isolation contract with a worktree, ordinary process and explicit project/role environment. This document records implementation progress, not VM acceptance.

Baseline: `8db86b703a49b8a73a90ebafe8c0cd755b1bc749`, preserved as `codex/utm-before-simple-sessions-20261110`. Continue on `codex/utm-lab-e2e`; do not rewrite the preceding history. PR #398 was already merged; a new PR will describe this branch's final delta.

## Flat implementation checklist

- [x] Preserve baseline and replace the current task's superseded contract.
- [x] Ordinary native Herdr launch with explicit private environment, installed runtime and role-scoped credentials; remove OS-session service paths.
- [x] Connect work-on/handoff to actual workers and persist identities on existing coworker commissions.
- [x] Accept reports before retirement and continuation; retain restart/duplicate and exact-HEAD merge gates.
- [x] Local deterministic suites and installed artifact rehearsal; update TS-MONO-003/004 without running VM/model tests.
- [x] Independent source-delta review, coordinated versions/changelogs, reproducible artifacts and publication queue. Final PR-head reconciliation is recorded with the PR.

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
- Modified packages fast+feat: 20/21 package results passed; Pi SDK acceptance required correcting scripted clock advancement to match observation cadence. Final targeted rerun passes all 13 SDK cases, wrapper 1 test/6 assertions (`c0202546-1c90-4b10-99e6-66f8c2df7799`); no model API was invoked.
- Real child launcher bridge: 10 tests /57 assertions (`f3b26a43`); child receives explicit environment in the actual worktree, reports its session, is reused once, then retired with auth removed and transcript retained.
- Wake JavaScript wrapper: 2 tests /7 assertions (`2ecb73eb-5bb6-4f7b-bd77-431a77c950f2`); suite's default zero-test wake entry is not counted as extension validation.
- Native: 3,732 passing local tests plus source-builder/changed-path checks; Linux ARM64 output cross-built and verified. See independent native/harness review record.
- History secret scan: one match is the **public Forgejo signing-key fingerprint** in `lab-vm/forgejo/profile.yml`, not a credential. No detected secret in the reviewed match. Release artifacts receive a separate scan after construction.

Platform/provider-dependent skipped tests and VM/model behavior are not treated as passed. No UTM command or paid provider request was run in this stage.

## Immutable release candidate and installed rehearsal

Product/source commit: `ae3dac03195d95ff986074f025edd6774a24afec`. Subsequent release evidence and fixture-manifest commits do not change shipping package sources. The adjacent `2026-11-10-release-artifacts.json` records all 19 versions and SHA-256 hashes. Each gem was built twice from that immutable archive using Ruby 3.4.8/RubyGems 3.6.9 and reproduced identical bytes. The final Linux ARM64 native Herdr artifact and provenance were verified separately; this is a cross-build, not execution on Linux.

The complete 55-gem guest dependency graph validates, and all 60 pinned public/local fixture artifacts are cached and verified. Eighteen changed gems belong to the guest graph; the nineteenth, ace-test-runner-e2e, is a host runner artifact. Installed all 55 gems plus that host runner into a fresh isolated GEM_HOME, outside the checkout bundle. From a fresh temporary working directory, six installed CLI help entry points passed. Every one of the 19 new gem specifications resolves inside this installation.

An installed-package probe launched a real ordinary Ruby child in the fixture worktree with the selected role environment, preserved installed mode, excluded ambient unrelated credentials and Bundler variables, refused a missing runtime executable, removed model auth while retaining transcript evidence, persisted/reloaded the existing commission execution binding, and found the packaged Overseer/Coworker/Wake instructions. No checkout library was loaded. This is deterministic component evidence, not autonomous-model acceptance.

Scanning the extracted shipping contents of all 19 gems with gitleaks found no secrets (7.45 MB inspected). Existing publisher `--prepare` accepted the exact verified bytes: **19 artifacts, 9 dependency waves, zero publication operations**. The local queue is `.ace-local/rubygems-publish/pending-queue.yml`; files at its package paths match the recorded hashes. Before publication recheck those hashes and unchanged source versions, then use the existing OTP publication procedure. Do not substitute historical `.pre.utm*` gems.

## Independent review reconciliation

At source commit `ae3dac03195d95ff986074f025edd6774a24afec`, review_simplification approved the retained supporting-package and Overseer/Coworker Ruby-flow scope; review_harness approved the independently reviewed lab/runtime/environment/observation/start/report paths and final Wake recovery correction. All 52 source gem specifications satisfy their internal runtime requirements. Authors do not approve their own changes: parent/sibling reviews cover those changes, including the native implementation and complete harness retained delta documented in the three adjacent review records. No confirmed source blocker remains in those reviews. Final metadata-only HEAD reconciliation is recorded in the PR verdict, avoiding a self-referential commit hash.

## Explicitly unexecuted

UTM/VM startup, live Forgejo model execution, five-minute idle behavior, failure injection on the guest, two complete reset cycles, Omarchy/Incus/Hermes integration. No autonomy or VM-acceptance claim is made. Task `8y0.t.x27` stays `in-progress`. Merge and publication are separate next actions; neither was performed during release preparation.

Final fixture-manifest verification: `bin/ace-test ace-monorepo-e2e` passed 119 tests /471 assertions after replacing every prerelease pin; report `81b495e3-bfed-407f-a811-a29634258375`. Independent review_native approved the full retained harness scope and verified guest/native artifact hashes against the final manifest (SHA-256 `9b14d90f3ae1dd8d11a48339f3872a383bb96638b481926aa755b9118aba0eda`).
