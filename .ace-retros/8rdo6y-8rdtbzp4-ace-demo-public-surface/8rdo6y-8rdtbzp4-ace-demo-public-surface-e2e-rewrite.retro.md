---
id: 8rdo6y
title: 8rd.t.bzp.4 ace-demo public-surface e2e rewrite
type: standard
tags: [assignment, 8rd.t.bzp.4, ace-demo, e2e]
created_at: "2026-04-14 16:07:43"
status: active
---

# 8rd.t.bzp.4 ace-demo public-surface e2e rewrite

## What Went Well
- Added missing non-dry-run recording coverage (`TC-005`) and integrated it cleanly into existing TS-DEMO-001 runner/verifier manifests.
- Stabilized fragile verifier language for TC-003/TC-004 by anchoring checks to public CLI contract behavior instead of brittle exact wording.
- Verified both scenario-level and package-level quality gates:
  - `ace-test-e2e ace-demo TS-DEMO-001 --tags smoke` passed `5/5`.
  - `cd ace-demo && ace-test all --profile 6` passed all tests.
- Completed release closeout for `ace-demo` with coordinated version/changelog updates (`0.25.0`) and clean working tree state.

## What Could Be Improved
- Initial E2E rerun failed during sandbox setup because `scenario.yml` used `$PROJECT_ROOT_PATH/mise.toml` directly. Using the fallback form from other packages (`${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}`) should have been standardized earlier.
- Pre-commit review fallback (`ace-lint`) reported non-blocking markdown/style warnings; these can be preempted by linting touched E2E markdown immediately after edits.

## Action Items
- Add/maintain package-scenario setup parity checks so all E2E scenarios use the same resilient `mise.toml` bootstrap pattern.
- Keep verifier assertions phrased around docs/help contract anchors for public-surface tests, especially where output copy is likely to evolve.
