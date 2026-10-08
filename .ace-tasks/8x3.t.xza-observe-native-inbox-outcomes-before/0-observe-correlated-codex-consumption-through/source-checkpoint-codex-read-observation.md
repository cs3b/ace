# Codex read-only observation source checkpoint

Source base: `6c2ce34b3`; worktree: `/tmp/ace-codex-read-observation`.
Task completion and the combined independent review remain open.

## Implemented boundary

`CodexAppServerTransport#observe` reuses the existing websocket-driver transport
and initialization on the authenticated socket supplied by the held runtime.
It sends only `thread/read` with the retained exact thread ID and
`includeTurns: true`. A positive query requires one exact retained client ID in
one uniquely identified completed turn/item, full legacy history, and the
transient SHA-256 of the single text input matching the retained intent.
Missing client IDs, identical text alone, incomplete or partial history,
malformed replies, ambiguous matches, transport loss and expired budgets return
uncertainty. It returns sanitized identifiers and the digest; no text bodies,
delete/supersession decision, queue add, or resend.

`CodexRuntimeSelection#observe` requires the retained submission association,
optionally validates its retained queue receipt, and uses the existing
`with_connection` checks before and after the read. A changed held artifact or
native process/endpoint association discards a positive result. The caller's
absolute deadline is capped by the original admitted handler deadline and is
passed to the transport without resetting the budget. The submission path now
also uses that capped connection deadline.

Public `NativeQueueExecutor#observe(agent:, thread:, event_id:, digest:,
submission:, deadline:, receipt: nil)` requires the typed original Codex runtime;
there is no CLI fallback. A lost queue-add reply may yield a correlated read
without a queue ID, represented explicitly by `queued_submission_id: nil`.
No missing ID is fabricated.

## Evidence and verification limits

Local retained evidence read: parent `observation-authority-contract.md`,
`evidence/codex-live-observation.json`, restart/endpoint observation evidence,
and the retained genuine Codex 0.159.3 `ThreadReadParams.json` and
`ThreadReadResponse.json` schemas under the primary checkout's
`.ace-local/lab-readiness/codex-schema/v2/`. These establish the provider query
shape and completed-turn default, not installed acceptance of this source.

The maintained Socket.pair/real websocket-driver tests and existing typed
selection fixture exercise source byteflow only. No native process, model,
provider, root-start, or deployment probe was run. EndpointProtection and the
pending ACL/root-start decision were not changed.

Executed via the worktree's `bin/ace-test`:

- Transport/executor files: 25 tests, 179 assertions, pass.
- Existing InboxContextService fixture file: 11 tests, 123 assertions, pass.
- Same three files together: 36 tests, 302 assertions, pass (3.0 seconds), report
  `.ace-local/test/reports/herdr/d1f17150-9d70-4ea2-97d0-7fe679b46880/`.

Initial fixture-only failures: the deliberately oversized reply correctly
closed the client, causing the controlled sender's EPIPE; the sender now accepts
peer close/reset. The changed held-artifact negative also correctly refused the
outer scope exit; the test explicitly expects that refusal. Neither fix weakens
the product boundary. Attempts to select a test method with `--filter` discovered
that the current runner filters file names; both reported no matching files and
are not execution evidence. The actual existing fixture file was then executed.

## Remaining producer/consumer state

This slice provides a validated provider query, not authority-issued observation
evidence. At this base there is no public retained-event observation consumer
joining this sanitized query to the context owner; root is implementing that
separate owner route. The current authenticated receipt schema requires its own
authority-issued native reference, so no signer/import adapter or canonical
consumption transition is invented here. Installed runtime/provenance acceptance,
authority signing, and the full xza/qkc acceptance remain open.
