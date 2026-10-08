# Current observation delivery commands — 2026-10-08

This implements the existing observation/import/sign/reconcile contract. It does
not accept native installation or close this task's success criteria. Final
combined code review remains required.

`ace-herdr inbox observe` remains a read-only candidate inspection. The actual
canonical producer is `ace-assign inbox-observe`, called by the configured
observer. Required selectors are `--project`, `--mapping`, `--assignment`,
`--attempt`, `--inbox-context`, `--event`, `--claim-generation`, `--mutation`,
and `--expected-generation`. It asks the fixed authenticated context owner for
the current original event and native observation, constructs the closed
sanitized observation artifact, and calls `import_observation` through the
existing assignment authority transport. The authority independently verifies
the current registration, persisted native correlation and configured runtime
and observer. A positive response names an opaque immutable `evidence_id`.
Uncertain native history returns uncertainty without an import or resend.

`ace-assign inbox-settle` is called by the distinct configured signer. It
requires `--project`, `--mapping`, `--assignment`, `--attempt`,
`--inbox-context`, `--event`, `--evidence`, `--mutation`, and
`--expected-generation`. The input is a canonical evidence ID, never a receipt,
observation JSON, key path, runtime endpoint or asserted outcome. The signer
fetches the exact retained artifact/provenance, independently verifies it
against the current authenticated context and installed trust map, and loads
only the fixed protected `receipt_private_key` reference. Its public key must
match the current event's pinned key. It derives the existing consumed y23
receipt, then calls `reconcile_inbox` with those exact signed bytes and current
expected registration.

Both operations retain existing `observe_to_sign` context admission across
their source flow and explicitly end it only after a verified response. Lost
or invalid responses do not manufacture completion or discard an unresolved
admission. Every retry retains the original mutation and generation. The
signer's proof bytes depend only on immutable evidence and the original event,
not the latest journal head or wall clock, allowing exact proof replay.

Unknown/unmapped peers, wrong selectors, stale claim, changed keys/runtime,
worker-writable native evidence, conflicting observations, unavailable authority
and forged provenance refuse. No fallback, alternate signing oracle, second
ledger or message body publication is added. Supersession remains outside these
commands until its separate native proof contract is delivered.

Small maintained source checks cover the actual artifact byte flow, authority
transport/consumer, key verification and signed reconciliation. Actual distinct
OS users, native Codex/Pi, installation and task execution remain solely in
lab-config:8wl.t.gad.2.
