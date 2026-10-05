# Read-only retained Inbox settlement source review

Verdict **REQUEST CHANGES** at exact `32e73993bef06542d4c2bb433410a6ccf4d9bbda`. Delta adds verify_reconciliation to existing Inbox proof owner; no handler/startup/whole-task claim.

**P2 — Require canonical registration on the new read-only verifier.** `ace-herdr/lib/ace/herdr/organisms/inbox.rb:248` requires an expected_registration keyword but forwards nil unchanged; shared helper line262 conditionally skips the registration comparison for nil, preserving reconcile's older optional mode. Thus verify_reconciliation can approve a retained local signed settlement without comparison with a canonical accepted registration. Keep ordinary reconcile's explicitly optional behavior, but new canonical retained verifier must reject nil/malformed registration and require exact existing event/attempt/payload/key fields under the event lock. Independent actual-RSA consumed replay fixture passes nil and receives successful completed settlement; expected ValidationError fails.

Otherwise the extracted shared verifier retains existing event lock, exact signed receipt/raw/signature and local claim/binding checks, replay-only admission for settle:false, actual replacement-target native observation and refusal behavior. A replay returns before transition/save; settle:true preserves previous uncertain/delivered reconciliation. Existing public status/deliver/reconcile remain public. Construction or supplied canonical native fields do not become proof.

Independent own checkout receipts under `.ace-wt/review-9c2-runtime/.ace-local/test/reports/herdr/`:

- Factory/retained verification tests **3/15 PASS**, `2b9556bd-f5c9-4721-9c08-b103621543b3`.
- Existing Inbox tests **44/272 PASS**, `2e9fbe24-5c9f-4da7-9dac-48b0cabb1c21` (ordinary reconciliation/regression semantics).
- Independent nil-registration refusal regression **3 tests/11 assertions/1 failure/0 errors**, `e39cf8f7-9765-48f3-9026-04aaa6c94d3b`. Scratch `.ace-local/review/inbox_nil_registration_test.rb` retained; actual signed retained consumed settlement succeeds with nil.

No source edits, broad suite, native/privileged/VM/probes. Findings sent root/author; startup and installed acceptance remain open.
