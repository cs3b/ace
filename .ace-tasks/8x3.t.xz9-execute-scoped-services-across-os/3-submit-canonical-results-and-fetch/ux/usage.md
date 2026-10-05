# Canonical submitted result and authorized fetch — draft usage

Mapped live worker uploads submit_result's exact family schema and normal receipt
first, then declared ordered artifact bytes. A failed zero-artifact receipt sends
only its receipt part. Response returns immutable result_id and three distinct
digests/references; no private receipt/native binding or terminal acceptance.

An authorized peer sends evidence_fetch with mutation_id null and canonical
kind/purpose_id/artifact_id. It receives one exact descriptor and bytes from one
canonical commit; wrong purpose or current visibility revocation refuses. Worker
cannot fetch raw review/observation bytes. No caller path or history commit exists.

Retry the identical live-worker submission with its original mutation ID: same
sanitized reply, no duplicate import. After worker exit/terminality retry refuses.
To correct content, submit a new candidate generation, even at identical HEAD;
fresh mutation ID alone conflicts. Finish is xz9.0-owned and blocked on 9c2 proof,
not a delivered behavior of this child. Full-service guard remains closed.
