All claims verified against source. Here is the structured review.

---

# Code Review — Ordinary Transport Fixture Join (HEAD~1)

## Summary

Small, well-scoped change: wires the existing `FixedMergeEvidenceFixture` into the real-socket E2E transport test (repairing two positive scenarios broken by the newly mandatory canonical merge evidence owner), adds one negative test proving revoked evidence refuses before any repository mutation, and records honest evidence artifacts. **No Critical or High findings.** All behavioral postconditions asserted by the new test are guaranteed by verified source paths, not incidental.

## Deep Diff Analysis

**Change 1 — Fixture wiring** (`ace-lab/test/organisms/ordinary_listen_e2e_test.rb:4,49`)
- **Intent:** supply the now-mandatory `ordinary_merge_evidence:` owner to `AttemptCoordinator`; without it, `verify_fixed_merge_evidence!` fails closed and both positive merge scenarios refuse.
- **Impact:** matches the sibling pattern exactly (`ordinary_merge_receiver_test.rb:33` uses the identical require path and identical `(@merge_evidence = ...)` wiring) — consistency ✅.
- **Alternatives:** none needed; this is the established sibling pattern.

**Change 2 — New negative test** (`ordinary_listen_e2e_test.rb:209-218`)
- **Intent:** prove the revoked-evidence refusal over the real socket, fail-closed, pre-mutation.
- **Impact (verified):**
  - Fixture raises `AttemptErrors::ReceiptRejected` → receiver maps it to `ordinary_merge_authorization_invalid` (`ace-lab/lib/ace/lab/organisms/ordinary_merge_receiver.rb:157-158`) ✅.
  - `assert_nil fixed_merge_record("request-a")` is a *guaranteed* postcondition: the admission guard runs inside `prepare_fixed_update` (`evidence_journal.rb:1531`) **before** `write_mutation_blobs`/commit (`evidence_journal.rb:1492-1510`), so a raising guard leaves no record, event, or commit ✅.
  - `git("checkout", "feat/a")` before the request makes the producer's `verify_candidate_head!` pass, isolating the failure surface to the evidence check specifically — good test hygiene ✅.
- **Alternatives:** could additionally assert re-enabling evidence lets the same request succeed, but that path is already covered by test 1; no gap.

**Change 3 — Comments/docs/evidence**: boundary clarification in the header comment is accurate (native authority controlled; `ordinary_reviews_test` owns the real canonical coverage — consistent with the fixture's own docstring). Evidence artifacts cross-check: 6 tests / 46 assertions matches the 6 test methods in the file; `suite-ea6-red/` exists with 51 summaries + `lab-report.md` as the delivery map claims ✅.

## Findings

| # | Severity | Location | Finding |
|---|----------|----------|---------|
| 1 | **Low** | `ace-lab/test/organisms/ordinary_listen_e2e_test.rb:4` | Third ace-lab file now `require_relative`s into `ace-assign/test/support/`. Pre-existing pattern (two siblings already do this), so this diff is consistent — but the structural debt is compounding: ace-assign test reorganization or gem packaging without `test/` breaks ace-lab. Suggestion: promote `FixedMergeEvidenceFixture` to `ace-test-support` (the designated shared-infrastructure gem per the gem guide). |
| 2 | **Low** | `ace-assign/test/support/fixed_merge_evidence_fixture.rb:12` | Fixture raises `ReceiptRejected` directly, which is *not* in `AttemptCoordinator#verify_fixed_merge_evidence!`'s re-wrap rescue list (`EvidenceUnavailable, UnauthorizedIdentity, Conflict, NotFound`). Same error class → identical receiver mapping → identical wire code, so no behavioral divergence today; but the double bypasses the re-wrap the real owner exercises. Consider raising e.g. `EvidenceUnavailable` so the double walks the same normalization path. |
| 3 | **Low** | `.ace-tasks/8xf.t.ei9-wave-3/evidence/ordinary-transport-fixture-join/summary.json` | Missing trailing newline (`\ No newline at end of file`). Trivial hygiene; perpetual diff noise for some tooling. |

No Critical/High/Medium findings. *No issues found* in logic, error handling, contract violations, or security-affecting behavior within the changed lines.

## Code Quality Assessment

- **Complexity:** negligible delta; the new test is linear and synchronous (no polling needed — the refusal is returned in the request envelope).
- **Maintainability:** good — the fixture's `enabled` flag gives future tests a one-line lever for the revoked path; per-test `setup` instantiation prevents cross-test leakage of `enabled = false` (only the new test disables it).
- **Test coverage delta:** +1 negative test closing a real gap (revoked-evidence refusal over the real socket was previously unproven at this composition layer); +2 repaired positive scenarios.

## Architectural Analysis

- **Pattern compliance:** ✅ follows sibling receiver-test wiring verbatim; ATOM boundaries respected (fixture is an explicit boundary double, documented as such).
- **Dependency changes:** test-time only; no runtime dependency changes. Finding #1 notes the growing cross-gem test-support coupling.
- **Component boundaries:** the header-comment update correctly narrows the test's claim to socket/decision/merge/settlement composition — avoids overclaiming native acceptance.

## Documentation Impact Assessment

- **Required updates:** none beyond what's included; delivery-map addition accurately states scope and the pending full suite.
- **API changes:** none.
- **Migration notes:** n/a.

## Quality Assurance Requirements

- **Test scenarios:** ✅ covered — typed refusal code, no canonical record, no repo mutation (all three postconditions independently asserted).
- **Integration points:** the tracked follow-up is the **full current suite after correction** (`scope.json: "full_suite_after_correction": "pending"`). Under the repo's merge policy (executed tests + reviewer verdict; CI advisory), the focused 6/46 PASS satisfies the gate, but the delivery map's own requirement should be executed before this wave closes.
- **Performance:** new test adds ~4s (deterministic, no retry loops — the refusal path is synchronous); teardown already bounded.

## Security Review

- **Attack vectors:** the new test *strengthens* the security posture — it proves the evidence check refuses before any durable write or ref mutation (guard-before-write verified in `evidence_journal.rb:1492-1531`), i.e., an attacker who revokes/withholds canonical evidence cannot obtain even a pending record.
- **Data flow:** no secrets introduced; `test-scoped-token` is fixture-only and pre-existing.
- **Compliance:** boundary documentation is honest and matches the fixture's stated scope.

## Refactoring Opportunities

- **Technical debt:** Finding #1 — relocate shared fixture into `ace-test-support` as a batch (all three requiring files at once), not in this diff.
- **Code smells:** none in the changed lines; the dense inline assignment `(@merge_evidence = ...)` mirrors the sibling test, so changing it here alone would reduce consistency.
- **Future proofing:** *Future consideration only (not an action item)* — if more evidence-owner states emerge (expired, wrong head), the fixture could grow typed failure modes; current boolean is sufficient.

**Verdict:** ✅ Approve. Executed focused tests (6/46 PASS) + verified postconditions satisfy the merge gate; the pending full-suite rerun is correctly tracked in the delivery map as the closing step for this wave.