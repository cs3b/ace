# Independent journal primitive review — APPROVE

Exact head: `b458644c009cf73fbfd044d99a5ba64949ce2e16`. Independent detached worktree `/tmp/ace-wave5-journal-review`; source repair `41d681451ce9c543e36abf8f9a94aaabfb4ff399` against `e484a8aab`. Read prior independent review-8x417w findings and bounded source/test delta. No primary or author edits.

Both prior High findings resolved. Finish adopts authoritative derived state and refuses reserved ownership before candidate validation or receipt acceptance, including absent cache and stale running cache. Terminal transition validation precedes append. Canonical mutation blobs are hashed from original binary stdin without filters and staged by object ID; reuse compares accepted canonical blob rather than smudged checkout bytes. Original CAS/replay boundary and failed-writer cleanup remain intact.

Executed via bin/ace-test in exact-head worktree:
- Independent prior canonical reservation/CRLF probes, adapted only to accept newly required EvidenceUnavailable classification: assign/8x41on, 3 tests / 8 assertions, green. Checks accepted receipts remain empty and derived reservation survives both cache modes; canonical bytes equal original CRLF.
- Author coordinator regressions: assign/8x41pj, 52 tests / 239 assertions, green, including unbound finish, intent-only recovery, stale state and concurrent finishes.
- Author journal mutation regressions: assign/8x41ow, 10 tests / 147 assertions, green, including autocrlf plus real clean/smudge filters, canonical byte/hash preservation, immutable reuse/replay/checkout deletion, original reserved actor, and rejected staged data cleanup across append/record/service writers.

65 tests / 394 assertions executed independently, zero failures/errors. git diff --check clean; tracked worktree clean. No remaining verified P1/P2 in this bounded repair scope.

APPROVE source primitive repair. This does not establish protected installed origin, distinct-UID policy/endcap proof, or final Lab acceptance.

Integration awaits the final full-package receipt for this repaired head.
