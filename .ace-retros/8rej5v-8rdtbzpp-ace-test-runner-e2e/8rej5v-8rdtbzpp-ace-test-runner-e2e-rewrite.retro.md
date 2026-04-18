---
id: 8rej5v
title: 8rd.t.bzp.p ace-test-runner e2e rewrite
type: standard
tags: [ace-test-runner, e2e, assignment]
created_at: "2026-04-15 12:46:32"
status: active
---

# 8rd.t.bzp.p ace-test-runner e2e rewrite

## What Went Well
- Consolidated duplicate TS-TEST-001 coverage without losing retained user-value journeys (`package+target` and `specific-file`).
- Removed workaround-heavy TS-TEST-002 monorepo-root/fallback command branching and replaced it with one canonical suite invocation path.
- Added explicit suite `--target` pass-through scenario coverage and aligned runner/verifier manifests in one implementation pass.
- Verification stayed stable: `ace-test ace-test-runner feat` and `ace-test all --profile 6` both passed cleanly.
- Release flow completed with version/changelog updates and clean git state.

## What Could Be Improved
- Task bundle referenced migration artifacts that were missing on disk (`.ace-local/e2e-migration/...`), forcing plan-time fallback to live scenario files.
- Pre-commit review had to fallback to `ace-lint` because `/review` slash command is unavailable in this environment.
- RubyGems propagation proof command documentation (`--test-id`) was stale versus current CLI contract, causing an initial failed invocation.

## Action Items
- Add assignment/task guardrails to validate referenced bundle files exist before `plan-task` starts, and emit explicit missing-input diagnostics.
- Update release workflow note to the current `ace-test-e2e PACKAGE TEST_ID` argument form (or keep both forms with version gating guidance).
- Keep documenting monorepo-proof result as `LAG_DETECTED` with mitigation `bundle install --full-index` until a full live TS-MONO-001 pass is captured in this environment.
