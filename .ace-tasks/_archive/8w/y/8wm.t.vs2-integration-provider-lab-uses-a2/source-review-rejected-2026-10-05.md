# REJECT — exact candidate 5afccf58add072057524486bc6b5cb3f84282e0f

Independent review of 7ebb11c3..5afccf58. Isolated worktree: /tmp/ace-wave5-vs2-review, branch codex/wave5-vs2-review.

## Verified P1: preserve original native incarnation across consume and enqueue

ace-hitl/lib/ace/hitl/live_client.rb:63-64 hands Inbox only session/pane plus the managed envelope. The full owner returned at line 42 is reduced to a session/pane comparison at line 43. After boundary.consume returns, Inbox.enqueue freshly observes the pane at ace-herdr/lib/ace/herdr/organisms/inbox.rb:88 and uses that newly observed thread/terminal as the immutable delivery binding. If the original native thread exits/restarts in the same pane between the scoped consumer check and enqueue, the new thread receives the old answer without a refusal or signed supersession. Existing Inbox drift checks compare delivery with this already-replaced enqueue binding, so they do not prevent this initial misrouting.

Verified deterministic reproduction extends existing real Store + real Inbox test: immediately after boundary.consume succeeds, replace the executor-observed native agent_session UUID from ...0001 to ...0002. LiveClient deliver succeeds, calls the native submit once, and persisted binding.thread is ...0002. No original-incarnation binding reaches Inbox. Carry the accepted full owner/target into enqueue and require exact initial target match; preserve it through retries rather than re-establishing authority from a reused pane.

Executed regression receipt: .ace-local/test/reports/hitl/8x40sq, 10 tests / 74 assertions, one expected regression failure: original thread ...0001 expected, replacement ...0002 actual. Earlier refusal-style reproduction .ace-local/test/reports/hitl/8x40rs: expected BindingError/ValidationError but nothing raised. reproduction.patch preserves reviewer-only test extension.

## Executed candidate tests

- LiveClient: 8x40ou, 9 / 71 green.
- Hermes pending producer: 8x40ov, 3 / 18 green.
- Assignment runtime binding: 8x40pb, 4 / 32 green.
- Contract managed envelope: 8x40pq, 5 / 25 green.
- Herdr Inbox: 8x40q1, 37 / 205 green.
- Managed CLI wait: 8x40qg, 5 / 21 green.
- git diff --check: green.

Author full-package receipts reviewed in implementation-report.md; no redundant full suite or CI requirement introduced. Actual native/Telegram/multi-UID installed acceptance, SC2 and gad.2/.8/.b, remain separate and unproved by this source review.

## Additional verified findings

- P1, ace-hitl-hermes/lib/ace/hitl/hermes/runtime.rb:48: new publish_pending runs outside continuous-loop rescue. A single Lifecycle::TransportError from pending during a service restart exits serve(false), stopping the sole polling owner for all channels. Preserve requests, expose failure and retry publication while maintaining bounded continuous polling. Independently reproduced in Hermes receipt 8x40wp: 4 tests / 19 assertions, one regression failure (TransportError instead of later loop stop).
- P2, ace-hitl/lib/ace/hitl/live_client.rb:66: after reconcile(retry_delivery:false) verifies supersession and leaves event queued, ordinary deliver calls inbox.deliver and resubmits it. Require explicit retry_delivery:true for this transition. Independently reproduced HITL receipt 8x40wo: native call count increases 1 to 2 after ordinary deliver.
- P2, ace-herdr/lib/ace/herdr/organisms/inbox.rb:71: envelope validation scans secret shapes only inside an optional nested answer message. Direct managed Inbox consumers with absent message can enqueue otp=123456 with its matching digest, persisting both. Gate actual managed payload before persistence regardless of message field. Independently reproduced HITL receipt 8x40wo: expected ValidationError but none raised.

Supplemental explicit codex:gpt-6.1-sol ace-review completed exit 0: session review-8x40qs, report review-report-gpt-6.1-sol.md. All four findings independently checked and marked valid/pending via ace-review-feedback (8x40w57g/h/i/j). HITL probes 8x40wo: 12 / 75, three regression failures; Hermes probes 8x40wp: 4 / 19, one regression failure. These failures are intentional assertions of required safety behavior. Reviewer reproduced through bin/ace-test only. No source fix, push, publish or merge performed; parent and repair agent received all findings.

