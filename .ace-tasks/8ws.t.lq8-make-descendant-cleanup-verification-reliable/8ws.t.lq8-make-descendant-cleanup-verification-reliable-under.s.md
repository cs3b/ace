---
id: 8ws.t.lq8
status: pending
priority: medium
created_at: "2026-09-29 14:29:09"
estimate: small
dependencies: []
tags: [ace-llm-providers-cli, test-isolation]
title: Make descendant cleanup verification reliable under load
needs_review: false
bundle:
  presets: [project]
  files: [ace-llm-providers-cli/test/fast/molecules/safe_capture_test.rb, ace-llm-providers-cli/lib/ace/llm/providers/cli/molecules/safe_capture.rb]
  commands: []
position: 6o0008
---

# Make descendant cleanup verification reliable under load

## Outcome and behavior
SafeCapture descendant-cleanup tests reliably distinguish a product leak from scheduler delay. The reported high-load-only failure and standalone success are observations, not proof of either a fixture defect or a production defect. Establish the cause before fixing it.

Owner: ace-llm-providers-cli test/fast/molecules/safe_capture_test.rb and only any cleanup behavior proven defective. Consumers retain the existing SafeCapture.call contract: bounded timeout, descendants terminated, correct status/output, no leaked process tree. This task is independent from long-session classification in lq1.0; coordinate edits if both touch SafeCapture.

## Success criteria and verification
- [ ] SC1: Record exact failing assertion/platform and reproduce via controlled child readiness/lifecycle evidence rather than an assumed load average threshold.
- [x] SC2: Deterministic synchronization removes accidental scheduler assumptions; assertions still detect a surviving descendant and an unreaped child where the platform owns reaping. Never pass merely by hiding the assertion, arbitrary sleeps, retries, killing an unrelated PID or increasing global timeout.
- [x] SC3: Test success and timeout cleanup; retain negative control demonstrating a real leaked child is caught. All fixtures clean up their own descendants on failure.
- [ ] SC4: Execute bin/ace-test ace-llm-providers-cli all and bin/ace-test-suite, with bounded controlled contention evidence and independent review. A standalone pass is not a fix receipt.

## Scope / verification intent
One small test reliability slice. No new public CLI/API/config; ux/usage.md not applicable. The captured first-wave docs flake (ibl) and managed-state fixture isolation (ibk) remain separate tasks. This is advisory to starting new feature work, but any red result must be accounted for in merge evidence. Implementation research resolves fixture versus product cause; no human behavior question remains.

## Delivery reconciliation — 2026-10-04

a656b47def429efcdee851907a2ce9d11dd4c0ea already replaced immediate PID absence assertions with a monotonic bounded observation and a deliberately live five-second negative control. R1's archived reports/test-failure-analysis.md records the original success/deadline failures, later absence, targeted 24/74, package and full-suite passes. Product cleanup was unchanged. Do not redo the delivered repair or increase product timeouts.

Keep the task open solely for SC1/SC4's missing controlled-contention lifecycle evidence and independently reviewed criterion mapping. Ordinary parallel-suite load and a green rerun do not establish the requested bounded controlled-contention scenario. Existing success/timeout assertions and live-child negative control supply SC2/SC3 code coverage, not a new installed runtime acceptance. This is local test-evidence debt, not a blocker of unrelated implementation lanes.
