# Guarded queue notification source checkpoint

## Scope and independent readiness

Parent independently approved the fixed notification/native-channel contract in `41fe28f4f` and the explicit Q queue / W notification-only retry contract in `985f87ccc`. This checkpoint implements that bounded source slice; it is not an independent source approval or xza.3 completion.

The admitted context owner persists the actual queue issuer in the existing DeliveryRecord at the same locked claim publication. Its admitted claim distinguishes `queue` from `wake`; the actual native queue claim remains the original generation/owner pair. An explicit W retry at current generation preserves Q, its receipt and queued payload and issues only the source-fixed notification. The private event wake tuple binds operation/input/generation/original digest; issuing is published before IO, which occurs outside both context and event exclusions. Fixed guarded response decoding alone distinguishes sent/not-issued/uncertain. A lost result or interrupted publication never authorizes another notification.

Canonical retirement compares actual Q claim history, not an invented queue action containing the claim-kind metadata. Signed supersession deliberately removes the current claim_owner; historical Q attribution then requires exact single claim-history and same-generation superseded reconciliation. This is attribution only; the existing separately authenticated canonical completion is still required for a new queue claim.

## Executed evidence

- Herdr selected direct/context-owner/context-server/native-control files: 52 tests / 376 assertions PASS, report `herdr/3d96a963-436c-4e1d-a46c-0c2e1c4d83cc` (before final historical supersession precision; final successor report appended below).
- Actual original direct issuer -> authenticated canonical reconciliation/restarted replay and existing readonly stale observer: 2 / 23 PASS `assign/68d1ceef-cbcb-4882-8aa7-daea07ad1559`. Its second line selector 547 selected the preceding test, not the supersession retry; it is not retry evidence.
- Actual private signed supersession refusal -> canonical accepted completion -> exact replacement queue claim once: 1 / 33 PASS `assign/ea1581b5-0861-4d15-8a18-4356180107d6`, selected current line 548.
- Retained failure `assign/9b63258f-c025-447a-8e5a-4c06fae62995`: unconditional current claim_owner lookup refused signed supersession; repaired through exact historical Q attribution above.
- Earlier failures are retained: old preparation interface, obsolete uncontrolled wake fixture, and fault fixture failing to propagate through the existing per-key Inbox clone. The final tests exercise actual issuing and finish publication failures before/after durable event publication.

Pure owner-phase tests run the real ProtectedNativeControl fixed payload, origin validator and response parser with a controlled transport/preflight fixture. They prove positive not-issued -> end -> restart -> fresh W -> one notification and zero payload resend; same-W replay; lost/issuing/uncertain replay; failure before/after issuing and finish publication; forged Q/input/receipt/original digest and W readback; exact canonical Q/W retained-record joins. A notification callback successfully reads the actual context store and event while issuing, proving neither exclusion spans notification IO. Pure canonical verifier inputs are explicitly not substituted authenticated canonical acceptance.

Final frozen-source Herdr rerun after historical supersession precision and explicit canonical operation identity: **52 / 376 PASS** `herdr/baadd85f-98f8-4cdb-b090-27582224d826`. Raw retained output was read; no skipped cases.

## Remaining gates

The complete SAME Lab producer -> held Runtime entry -> actual selected child subprocess -> registered CLI composition is still required. The controlled transport fixture does not prove installed native endpoint provenance or actual Codex/Pi queue semantics. Actual stopped-owner/dead-launcher no-writer recovery, maintained initialization ACK/producer publication, protected LiveClient adoption, and the complete family negative matrix remain open. This checkpoint does not mark tasks or SCs done. Installed/native acceptance remains gad.2; Lab service producer remains gad.8.
