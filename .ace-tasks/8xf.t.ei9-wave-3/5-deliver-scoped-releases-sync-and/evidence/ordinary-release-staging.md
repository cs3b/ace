# Ordinary release staging consumer — 2026-10-17

OrdinaryReleaseStaging (ace-lab) is the .5 staging join: it reads retained
release artifacts through the sole Assign owner (release_artifact_at!, now
reachable with the public result_events/journal surface), verifies every
canonical byte digest, reconciles each artifact against the AUTHORITATIVE
registry readback (RubyGems versions API; the CDN-cached latest.json is
deliberately not used), and produces the publisher's staged queue —
dependency-ordered per the manifest's declared order, with per-artifact
states: published (digest match — skip), pending (absent — publish),
conflict (digest mismatch — the registry is immutable; a differing digest
means a different build and hard-blocks, never republish), uncertain
(readback unreachable — reconcile before any retry). It never pushes and
never holds credentials; execution stays with the existing project publisher
in its authorized executor (the .5 contract). Receipts: 5 tests / 20
assertions PASS (published+pending+order, conflict-blocks, uncertain, exact-
set-once order validation, unknown-artifact refusal).

Remaining .5 source: wiring the staged queue into the project publisher's
run owner (iy6 command execution with the declared inputs/executor identity)
and the per-artifact partial-success reconciliation loop on the execution
side; the OTP route stays with child .9 per the spec.
