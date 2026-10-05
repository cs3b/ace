# Canonical result implementation verification

Source candidate: `e4e4e1352e180bd5b177d28c291e87a6e82aa09a`, comprising implementation `3287ac350` and the merge of documentation-only main `3056f002c`. Source remained frozen throughout independent review and final gates. This receipt is a documentation-only follow-up; task closure and integration belong to the parent delivery lane.

The implementation adds private `result_submitted` records and canonical imports through the existing journal/CAS, live-worker result submission, purpose-bound evidence fetch, the existing services attempt-status projection, and validation in the actual Client. Campaign-bearing result and review receipts refuse before local campaign lookup. Launch-only request schema and role-filtered base fields remain covered. Full-service completeness remains closed: this change supplies no finish, recovery, inbox, signing, no-effect or cleanup implementation.

Tests use real Git refs, blob bytes, journal chains, CAS, and actual Client/Server seams. Injected kernel identities are source fixtures, not proof of installed native protection. No native launch/security/privilege probes, VM/container experiments or real Lab deployments were executed.

## Executed final gates

| Command | Result | Receipt |
| --- | --- | --- |
| `bin/ace-test ace-assign feat ace-assign/test/feat/endcap_results_test.rb` | PASS: 13 tests, 200 assertions, no failures/errors | `.ace-local/test/reports/assign/8x4ana/` |
| Independent reviewer: `bin/ace-test ace-assign feat ace-assign/test/feat/endcap_results_test.rb ace-assign/test/feat/authority/transfer_server_test.rb` | PASS: 17 tests, 224 assertions, no failures/errors, 4m 2s | `.ace-local/test/reports/assign/8x4atp/` |
| `bin/ace-test ace-assign all --profile 20` | PASS: 974 total, 972 passed, 2 skipped, 4681 assertions, no failures/errors, 20m 39s | `.ace-local/test/reports/assign/8x4b77/` |
| `bin/ace-test-suite` | FAIL: Assign reached configured 120-second ceiling; other 50 package entries passed. 10395 passed, one timeout error, 24 skipped, 31205 assertions, 120.24s total | Original terminal outcome retained; printed Assign `latest/summary.json` pointed to stale focused `8x4ana`, not a new timeout report |
| `bin/ace-test-suite --timeout 300` after full Assign and independent review completed | PASS: same default fast targets, 51 package entries, 11202 passed, 24 skipped, 34165 assertions, no failures, 140.19s total. Assign 806 tests/2960 assertions in 137.22s | Assign `.ace-local/test/reports/assign/8x4b9o/`; suite terminal summary |

The second suite run changes only the invocation timeout; source and suite configuration were unchanged. Its success does not make the unchanged 120-second default invocation green. Suite configuration includes two Lab entries, retained unchanged.

Independent source verdict: **APPROVE**, no verified blocking findings, for exact frozen `e4e4e1352e180bd5b177d28c291e87a6e82aa09a`. Report: `/Users/mc/Ps/ace/.ace-local/review/xz9-canonical-result-source-review.md`.

## Retained development outcomes

Existing review baseline is separate: 3 tests/33 assertions passed in the primary checkout's `.ace-local/test/reports/assign/8x49xp/`. New-feature receipts are in the isolated worktree.

- `8x4a2h`: 5/77, one role-denial failure; corrected coarse role authorization before lookup.
- `8x4a5y`: 9/129 passed; `8x4a9s`: combined regression 26/248 passed; `8x4aen`: 11/166 passed.
- `8x4ai8`: 13/200, one test-teardown error; corrected socket variable scope.
- `8x4al7`: load failure from eager error-class dependency; moved `MalformedTransfer` into the existing attempt-error owner. Business receipt rejection remains distinct from malformed framing.
- `8x4am8`: framing/codec/receipt regression 16/84 passed.
- A filename-filter invocation selected zero files and is not counted as verification.

Services discovery/fetch reject body bytes using request EOF before exposing the read. The Client half-closes only evidence-fetch and attempt-status requests with the result selector. Existing persistent gate behavior is unchanged and covered by the final gates and independent review.

Documentation syntax validation passed. Optional documentation analysis failed because provider `codex:gpt-6-sol` returned an incomplete result; no fallback analysis was claimed. Its existing artifacts remain under `.ace-local/docs/analyze-8x4a7p/`. `git diff --check` passed before source freeze.
