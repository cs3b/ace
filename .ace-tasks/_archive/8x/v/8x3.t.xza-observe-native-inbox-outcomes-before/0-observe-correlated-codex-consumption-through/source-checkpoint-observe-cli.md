# Protected inbox observe CLI source checkpoint

Base `9d660f840`; worktree `/tmp/ace-inbox-observe-cli`. Source implementation
only; task completion and the single combined independent review remain open.

`ace-herdr inbox observe` now requires explicit project, mapping, inbox context,
assignment, event and attempt token IDs plus a positive retained claim generation.
It uses the existing held ProtectedInboxSelection and authenticated
InboxContextClient. Missing protected installation, wrong flags and malformed
selectors refuse before any ordinary configuration read. Existing installed
selection permits supervisor discovery; no selector/authority policy was widened.

The CLI reads the validated `status_context` for the requested original
project/mapping/context/assignment association. It admits the actual kernel
process with purpose `observe_to_sign`, deliberately without `original` in this
non-direct admission. The query sends only retained operation/key generation,
event, attempt and claim generation. Before presentation it checks closed
candidate fields, exact context/op/key/event/attempt/claim association, payload
digest and complete binding, plus the sanitized observation shape. A second
validated same-selection status must equal the initial record before read-only
admission can end. Invalid/lost candidate or end responses do not manufacture
completion; no ensure block releases an unverifiable admission.

Output adds `candidate: true`. Neither a completed-turn candidate nor an
uncertain candidate creates an evidence ID, signature, receipt, canonical
settlement, retry or resend. The existing context ingress keeps its original
30-second deadline through retained-record locks and native read. The command
does not add a native endpoint, broker, environment or authority signing route.
Usage documents contain the exact explicit invocation and partial-source limits.

## Executed checks

- `bin/ace-test ace-herdr fast test/fast/commands/inbox_test.rb
  test/fast/organisms/inbox_context_server_test.rb`: 18 tests, 135 assertions,
  pass; report `.ace-local/test/reports/herdr/bbd86954-782f-413f-9653-7aea17631a3c/`.
- `bin/ace-test ace-herdr feat test/feat/protected_inbox_cli_test.rb`: 3 tests,
  371 assertions, pass; report
  `.ace-local/test/reports/herdr/5fea4d8e-4a66-498f-a519-f4c27e9a9f72/`.
- `git diff --check`: pass.

The existing registered CLI/controlled Unix socket test uses maintained owner
and native-reply fixtures. It exercises consumed and uncertain candidate output,
ordinary-peer refusal, forbidden flags, stale claim generation, nine malformed
candidate association variants, retained admission on invalid responses, exact
same-record readback, and no ledger mutation or additional submission. These
fixtures are deterministic source evidence, never installed native proof.

No model, native/provider probe, gem installation, E2E execution, main merge,
push or release was run. Authority import/signer integration and the unsettled
startup/installed provenance acceptance remain open under lab-config:8wl.t.gad.2.
