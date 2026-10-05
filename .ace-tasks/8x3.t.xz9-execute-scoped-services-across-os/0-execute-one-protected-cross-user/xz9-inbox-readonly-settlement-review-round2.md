# Read-only retained Inbox settlement review — round 2

Verdict **APPROVE bounded checkpoint** at exact `073ec3a7e181c03fc06ce5ea800340b02f600baa`, cumulative32e739 + correction. Prior REQUEST CHANGES report/failed independent receipt retained.

New verify_reconciliation requires a nonnil closed registration Hash with exactly event_id, attempt_id, payload_sha256 and receipt_key_sha256; IDs use existing bounded EVENT syntax, digests lowercase SHA256. It forwards that mandatory exact map to the existing under-event-lock comparison. Nil/empty/extra/bad-digest inputs refuse; ordinary reconcile's optional registration behavior is unchanged. Existing retained signature/local claim/binding/replacement checks and replay return before transition/save remain shared. No new actionable finding established.

Independent own checkout at frozen commit, no uncommitted author Endcap work: candidate factory/verification tests, existing44/272 Inbox regression coverage and original independent nil-registration regression all executed together: **50 tests /307 assertions PASS**, receipt `.ace-wt/review-9c2-runtime/.ace-local/test/reports/herdr/549e1c60-0d18-4400-90e0-ea7d20077848/`. Previous failed receipt e39cf8f7 remains historical; no broad suite/native/privileged/VM probes or source changes.

Approval covers read-only retained settlement verification only. Assign canonical provenance import, handlers/startup, whole xz9.0/9c2 and installed acceptance remain separate/open.
