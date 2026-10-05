# Independent exact-head implementation review — APPROVE

Candidate: `66c91a82d01b419fd26517a8d0fccb72647db30a`, detached independent worktree `/tmp/ace-wave5-vs2-final-review`. Reviewed round-two delta from `13e527247d7eeea82daff7fa4678ca0029c9ff29`, retained original repair behavior, and source authorization/cursor/frame handling. No primary or author worktree edits.

All four round-two findings resolved. Service pending returns bounded pages measured with the actual Protocol result envelope including newline. Client follows advancing keyset cursors; Store includes retained consumed native public claims and offers direct per-ID read rather than deleting recovery evidence. Each page requires transport authority and each included record retains project authorization. Cursor is only a validated ordering key, never a pathname or authorization grant. Stable IDs are de-duplicated and sorted; new IDs before an in-flight cursor are explicitly observed on the next scan. Oversized individual records fail visibly rather than silently dropping claims. Unrestricted sender labels no longer bypass authoritative lifecycle read; captain requester publishes while unmanaged instruction remains untouched. Managed envelope now requires String digest and canonical parsed calendar timestamps.

Original four findings remain repaired: immutable owner target prevents replacement adoption; ordinary delivery cannot implicitly retry signed supersession; actual payload secret gate works without nested message; continuous Hermes owner survives pending outage and retries.

Executed independent targeted receipts (all zero failures/errors):
- HITL paging real socket, 120 native claims plus fresh ask, bounded/disjoint pages, invalid cursor, other-project visibility and direct recovery read: `hitl/8x41mf`, 1 test / 10 assertions.
- Original independent incarnation/retry/secret probes plus LiveClient regression suite: `hitl/8x41mr`, 14 / 92.
- Herdr durable Inbox regression suite: `herdr/8x41mr`, 40 / 233.
- Hermes current producer/captain/unmanaged instruction regressions: `hitl-hermes/8x41mh`, 7 / 35.
- Original independent pending outage probe plus producer suite: `hitl-hermes/8x41mt`, 6 / 32.
- Managed envelope strict String/calendar tests: `hitl-contract/8x41mf`, 7 / 31.
- Scoped policy: `hitl/8x41mz`, 10 / 29; real service boundary: `hitl/8x41n7`, 20 / 99.

All tests invoked through bin/ace-test in the independent exact-head worktree. git diff --check clean and tracked worktree clean. Parent full-suite receipts are complementary; redundant unrelated full suites were not rerun.

Verdict: APPROVE this source implementation head; no remaining verified P1/P2 findings in reviewed repair scope. This does not establish actual native/Telegram/multi-UID installed or full Lab acceptance; those remain separate acceptance deliverables.

## Additional installation verification

Exact source 66c91a82d: installed-consumer fixture hitl-contract/8x41nc passed
1 test / 66 assertions, separate empty GEM_HOME per consumer, local archives
without network fallback. This does not prove the actual Lab installation.

## Main integration

Merged reviewed source as 0d9590097. Post-merge checks passed:
- Assign runtime binding: 8x41og, 4 tests / 32 assertions.
- HITL live delivery plus bounded pending: 8x41od, 12 / 95.

Task remains in progress for installed acceptance. This source enables qjz
implementation without claiming installed native/Telegram/signing completion.
