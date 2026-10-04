# Native observations — draft usage

## Genuine consumed evidence

Protected supervisor runs proposed `ace-herdr inbox observe --event event-1 --format json`. Expected observed only after a genuine exact native consumption fact, with bound event/attempt/generation/digest/runtime and authority-issued evidence reference. No signing or event transition. Codex/Pi extraction candidates and blocking runtime evidence are defined in observation-authority-contract.md; current submit receipts cannot satisfy this.

## Missing or untrusted source

A queue vanishes, matching text appears without exact client identity, or a worker supplies an observation filename. Expected uncertain; signer produces no receipt and runtime is not resent/cleaned up.

## Sign and generation race

Deployment-controlled gad.b signer verifies authority evidence and current canonical event, signs existing y23 bytes with the pinned key, then reconciles through Herdr's event lock and assign's public consumer API. Generation changed after observation/signing refuses stale proof. Positive superseded proves non-consumption and verifies replacement_target before allowing a fresh claim.

## Protected transport and actual native producer

Observer imports schema v1 evidence through authenticated import_observation; fixed signer fetch_observation verifies canonical blob/provenance, obtains context shared signing admission and submits exact signed bytes through assignment reconcile_inbox. Context owner performs expected_registration and signature verification under its event lock; no cross-user receipt filename is accepted. Worker cannot fetch private native evidence or choose outcome.

The Codex producer must retain clientUserMessageId in existing inbox submission_intent before native add, then retain queued submission ID from actual bound runtime reply. Existing codex queue CLI has no client-ID/structured receipt interface and does not satisfy this. Controlled native completed-turn/restart evidence is retained, but actual endpoint/Herdr integration and busy/duplicate/race drills remain draft blockers. Pi TUI producer attribution and exact removal are unproved.

Key replacement uses xza.3 exclusive begin_rotation/commit_rotation after all events completed and admitted signers positively ended. gad.8 installs/readbacks the real pair within that interval; unresolved/unknown state refuses.
