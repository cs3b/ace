# Independent journal primitive review — APPROVE

Exact head: `b458644c009cf73fbfd044d99a5ba64949ce2e16`. Independent detached worktree `/tmp/ace-wave5-journal-review`; source repair `41d681451ce9c543e36abf8f9a94aaabfb4ff399` against `e484a8aab`. Read prior independent review-8x417w findings and bounded source/test delta. No primary or author edits.

Both prior High findings resolved. Finish adopts authoritative derived state and refuses reserved ownership before candidate validation or receipt acceptance, including absent cache and stale running cache. Terminal transition validation precedes append. Canonical mutation blobs are hashed from original binary stdin without filters and staged by object ID; reuse compares accepted canonical blob rather than smudged checkout bytes. Original CAS/replay boundary and failed-writer cleanup remain intact.

Executed via bin/ace-test in exact-head worktree:
- Independent prior canonical reservation/CRLF probes, adapted only to accept newly required EvidenceUnavailable classification: assign/8x41on, 3 tests / 8 assertions, green. Checks accepted receipts remain empty and derived reservation survives both cache modes; canonical bytes equal original CRLF.
- Author coordinator regressions: assign/8x41pj, 52 tests / 239 assertions, green, including unbound finish, intent-only recovery, stale state and concurrent finishes.
- Author journal mutation regressions: assign/8x41ow, 10 tests / 147 assertions, green, including autocrlf plus real clean/smudge filters, canonical byte/hash preservation, immutable reuse/replay/checkout deletion, original reserved actor, and rejected staged data cleanup across append/record/service writers.

65 tests / 394 assertions executed independently, zero failures/errors. git diff --check clean; tracked worktree clean. No remaining verified P1/P2 in this bounded repair scope.

APPROVE source primitive repair. This does not establish protected installed origin, distinct-UID policy/endcap proof, or final Lab acceptance.

Final full-package receipt 8x4201 confirms 845 total tests (843 passed,
2 existing skips), 3,661 assertions, no failures/errors. Source integrated as
749bda001; receipt-only follow-up retained in 911a3c911.

Post-merge combined coordinator, journal mutation and HITL runtime-binding
verification: 8x421p, 66 tests / 418 assertions, no failures/errors. The four
verified source findings from both rejected rounds are resolved. This does not
close xz9.0: the protected endcap is now the next authored source slice.

## Existing consumers on integrated main

Source revision 9f8833c70: full Lab tests 8x423b passed 178 total / 599
assertions, no failures/errors, one existing skip. Full Review tests 8x424z
passed 941 total / 2975 assertions, no failures/errors, four feature skips.
These checks cover existing service and campaign consumers after journal
integration; they do not claim delivery of the new protected endcap.
