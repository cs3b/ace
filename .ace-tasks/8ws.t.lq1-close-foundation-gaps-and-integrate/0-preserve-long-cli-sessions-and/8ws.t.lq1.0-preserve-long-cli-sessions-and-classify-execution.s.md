---
id: 8ws.t.lq1.0
status: in-progress
priority: high
created_at: "2026-09-29 14:29:08"
estimate: medium
dependencies: []
tags: [ace-llm, e2e]
parent: 8ws.t.lq1
title: Preserve long CLI sessions and classify execution outcomes accurately
needs_review: false
bundle:
  presets: [project]
  files: [ace-llm/lib/ace/llm/atoms/error_classifier.rb, ace-llm-providers-cli/lib/ace/llm/providers/cli/codex_client.rb, ace-llm-providers-cli/lib/ace/llm/providers/cli/molecules/safe_capture.rb, ace-test-runner-e2e/lib/ace/test/end_to_end_runner/organisms/test_orchestrator.rb, .ace-tasks/8ws.t.lq1-close-foundation-gaps-and-integrate/evidence/release-proof-2026-09-29.md, .ace-tasks/8ws.t.lq1-close-foundation-gaps-and-integrate/evidence/install-observations.json]
  commands: []
worktree:
  branch: lq1.0-preserve-long-cli-sessions-and-classify-execution-outcomes-accurately
  path: .ace-wt/ace-t.lq1.0
  created_at: "2026-09-29 15:48:03"
  updated_at: "2026-09-29 15:48:03"
  target_branch: main
---

# Preserve long CLI sessions and classify execution outcomes accurately

## User experience and contract
A CLI agent performing a long, quiet tool call within its configured execution deadline completes normally through ace-llm and ace-test-runner-e2e. Actual timeout, transport failure, nonzero provider exit, successful provider completion, and missing E2E verdict remain distinguishable. Output text mentioning "timeout" does not itself prove a timeout. Existing timeout configuration remains bounded; no blanket increase or disabled deadline.

## Expected behavior
Owner: ace-llm-providers-cli execution/result capture and ace-llm outcome classification. Consumers: ace-test-runner-e2e runner/verifier, ace-review and ace-assign CLI invocations. Carry actual process/transport/deadline evidence through classification; retain partial stdout/stderr and session correlation without secrets. A transport failure with completed inner shell goals is still an incomplete provider session until reconciled; never synthesize a PASS from bundle output.

The reported approximately 230-second failure is a reproduction observation, not a fixed limit or proven root cause. Determine whether the configured deadline, transport, provider exit or wrapper classification terminates the observed session before changing behavior. Do not weaken isolation or substitute unapproved models. On an uncertain tool outcome, do not automatically replay the E2E installation or other side effects via fallback. Preserve the current safe resume/reconciliation contract; unavailable fallback providers yield an actionable terminal diagnostic, not a loop or success.

## Success criteria and verification
- [x] SC1: Reproduce and record the actual timeout/failure boundary and effective configured deadlines from the failing macOS run. Distinguish observed evidence from hypotheses (including alleged idle-stream drop).
- [x] SC2: Deterministic provider fixtures cover long silent success within deadline, actual deadline expiry, transport disconnect, nonzero exit mentioning timeout, and exit-zero output containing timeout. Return the correct distinct outcome; preserve useful captured evidence.
- [x] SC3: E2E runner and verifier consume the result correctly: incomplete/uncertain execution cannot become PASS or automatically replay effects; supported completion gets one final result and no spurious fallback.
- [x] SC4: A focused authorized macOS CLI smoke run covers the former long quiet interval; no auth/HOME/environment isolation regression, and no changes to global user settings or installed gems.
- [x] SC5: Execute bin/ace-test ace-llm all, bin/ace-test ace-llm-providers-cli all, bin/ace-test ace-test-runner-e2e all and bin/ace-test-suite; exact candidate independent verdict. lq1.1 owns the complete published-install rerun.

## Slice and boundaries
One medium execution correctness slice, no publication or general provider fallback redesign. Success/failure typed data is internal; preserve existing public error classes unless review discovers a contract change and updates this spec first. The public behavior/agent protocol changes are described in ux/usage.md.

## Evidence and review questions
Source e45679c1e: SafeCapture has a configured process timeout; ErrorClassifier examines message text. User report supplies ERROR verdict despite successful install goals. Root cause is unconfirmed; implementation diagnosis is required by SC1, no human product decision is pending. Sanitized release evidence is in the parent evidence/release-proof-2026-09-29.md. Do not implement the suspected cause as an established fact.
