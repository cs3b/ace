# Code Review: Ordinary Campaign Owner — Terminal Collection Reader, Historical Review Reads, Stable Reservation IDs

**Scope reviewed**: diff `69c2ea054..d5b11b93e` (ace-assign authority modules + tests, ace-review campaign manager/store + tests, docs/CHANGELOGs, task evidence artifacts). All findings below were verified against the surrounding source in the repo, not just the hunks.

**Overall verdict**: ✅ Solid, well-tested change. No Critical/Blocking issues. The security posture (fail-closed evidence validation, thread/commit-confined readers, idempotent reservations) is consistently enforced. A few Medium/Low items below are worth addressing.

**Strengths**
- ✅ `reserve_execution` replay semantics are exactly right: successor check before replay, input-binding equality (`round_id/scope/provider`), observation-not-authorization return of prior state, retry budget still consumed for *new* request IDs (`ace-review/lib/ace/review/organisms/campaign_manager.rb:231-262`).
- ✅ Store-level invariant enforcement (`campaign_store.rb:117-130`): `request_id` format validation plus cross-record uniqueness means tampered/duplicated IDs fail on every read, not just at write time.
- ✅ The `with_review_collection!` reader closure (thread confinement + journal-commit pin + artifact-membership + digest check, invalidated via `ensure`) is a strong escape-prevention pattern, and the test explicitly exercises the escaped-reader case.
- ✅ Collection-vs-approval separation is enforced and *tested* (`refute ... review_status ... accepted` after a successful collection read) — the core invariant of this PR is provable.
- ✅ Test style matches existing conventions (`assert_raises(ArgumentError)` for `Contract::Invalid < ArgumentError`, client-level `EvidenceUnavailable` mapping, journal `blob` stubbing for corruption).

---

## Enhanced Output Structure

### Deep Diff Analysis

**1. `ordinary_review_collection.rb` (new, ace-assign)**
- **Intent**: Expose the reviewer's terminal `review-collect` execution (submitted result + supervisor `finish` receipt) as canonical collection evidence without granting approval or counting a campaign round.
- **Impact**: New public owner API `with_review_collection!` included into `OrdinaryReviewEvidence`; consumes existing helpers (`result_events`, `retained_ordinary_result`, `ordinary_result_context`) from `OrdinaryResults`, so no logic is duplicated. Correctly reuses `ordinary_review_selection!` for cancellation-current checks.
- **Alternatives**: A separate reader class was avoided in favor of the established host-module pattern (`@journal`/`@project` ivars) — consistent with siblings (`OrdinaryReviews`, `OrdinaryResults`).

**2. `review_at_reference!` + `ordinary_review_selection!` (ordinary_review_evidence.rb)**
- **Intent**: Historical campaign consumption can read an original accepted review by `review_id` after the candidate has advanced, while cancellation remains current-state.
- **Impact**: Refactor of `review_at!` into shared `ordinary_review_receipt_at!` is behavior-preserving (verified: extracted body matches the previous inline logic); the new path deliberately skips current-candidate validation, which is the feature.
- **Alternatives**: Head-match is belt-and-braces given `review_id` uniqueness (`SecureRandom.hex(16)`); acceptable.

**3. `cancel_review` early return (ordinary_reviews.rb:141-147)**
- **Intent**: Allow supervisor revocation targeting the *original* review candidate after the producer advanced (previously blocked by `candidate_at!` raising on stale heads).
- **Impact**: Verified non-regressive in the accepted-review case: the old code also returned before the "already accepted" check, so cancel-after-accept behavior is unchanged; only the stale-head case newly succeeds, guarded by exact `head/candidate_generation` match against the original selection plus supervisor identity + `expected_generation` CAS. Double-cancel now raises `ReceiptRejected` (via `ordinary_review_selection!`) — same class as the old revoked-assignment path.
- **Alternatives**: None needed; the early-return placement before `candidate_at!` is the minimal correct shape.

**4. `reserve_execution` `request_id` (campaign_manager.rb) + store validation**
- **Intent**: Stable source-selected reservation IDs so a lost response or failed journal publication recovers the original reservation without a second provider dispatch.
- **Impact**: Matches the documented contract in `docs/campaigns.md`. Replay skips `execution_round_projection!`/scope checks, but those were validated at creation and are re-validated on every store read (`read_record` checks phase/round/scope existence per entry), so no gap. The newly added successor check on `reserve_execution` brings it in line with `record_round`/`resume`/`assess_finding` — this is effectively a bug fix (previously reservations were possible on superseded contracts).

### Code Quality Assessment
- **Complexity metrics**: The single `unless` in `with_review_collection!` (lines 28-37) compounds ~10 conditions (result presence, derived state, terminal/completion cardinality, result_id/digest/operation/verdict/head/binding equality, event-payload equality). High cognitive load; see Refactoring.
- **Maintainability index**: Good — new module follows sibling patterns, no new dependencies, no schema changes beyond an optional `request_id` key tolerated on read.
- **Test coverage delta**: Positive. New tests cover replay identity/conflict, uncertain/failed replay, retry exhaustion, superseded contract, historical read (happy/wrong-head/revoked), collection reader (pre-finish, escaped reader, tampered sha/blob, forged attempt, cancelled). Gaps noted under QA.

**Findings:**

- 🟡 **Medium — rescue clause in `with_review_collection!` masks caller-block errors** (`ordinary_review_collection.rb:57-59`). `rescue KeyError, TypeError` also applies to exceptions raised inside the consumer's block passed to `yield proof, reader` (the reader itself raises `EvidenceUnavailable`, but arbitrary consumer `fetch` mistakes become `"ordinary collection evidence is incomplete"`). Unlike `ordinary_review_receipt_at!` — where the same pattern only wraps internal calls — here the rescue spans caller code. *Fix*: build and validate `proof` in a helper method carrying its own rescue, then `yield` outside the rescue:
  ```ruby
  proof = ordinary_collection_proof!(events: events, commit: commit, reference: reference) # rescues KeyError/TypeError internally
  yield proof, reader
  ```
  This preserves fail-closed behavior for evidence problems without rewriting consumer bugs into evidence failures.

- 🟢 **Low — error-class consistency for reference mismatches** (`ordinary_review_collection.rb:30-37`): a wrong `result_id`/`receipt_digest` in the caller-supplied reference raises `EvidenceUnavailable` ("no exact successful terminal execution"), while a wrong `reviewer_attempt_id` raises `ReceiptRejected`. Both are caller-reference problems; consider splitting reference-binding mismatches out of the monolithic `unless` into the `ReceiptRejected` path for consistent caller ergonomics.

- 🟢 **Low — test formatting**: `ace-review/test/fast/organisms/campaign_convergence_test.rb` — no blank line between the end of `test_source_reservation_replays_after_completion...` and `def test_severity_correction...` (inherited from the original file's quirk, but the two new tests do use blank lines; make the boundary consistent).

### Architectural Analysis
- **Pattern compliance**: ✅ ATOM layering respected — `OrdinaryReviewCollection` is an authority-side composition over existing molecules (`CanonicalEvidence`, `CanonicalAttemptState`, `retained_ordinary_result`); `CampaignManager`/`CampaignStore` split (decision vs. durable invariant validation) is preserved and correctly extended.
- **Dependency changes**: None. `ordinary_review_collection.rb` is wired via `require_relative` in `ordinary_review_evidence.rb` and included before use; it relies on host ivars (`@journal`, `@project`) exactly like siblings. Runtime references (`Molecules::CanonicalAttemptState`) resolve through the existing lifecycle requires — same pattern as the including file.
- **Component boundaries**: ✅ Collection does not leak into approval (`review_status` untouched), campaign round counting, or merge consumption — the "remaining" list in the evidence JSON correctly names those as separate joins.

### Documentation Impact Assessment
- **Required updates**: ✅ Done — `ace-review/docs/campaigns.md` documents `request_id` replay semantics accurately (including "never authorizes a second dispatch" and source-owner reconciliation duty); both CHANGELOGs have Unreleased/Added entries per ADR-020.
- **API changes**: Non-breaking additions (`request_id:` optional kwarg; new owner methods). Store read tolerance for entries without `request_id` keeps existing durable records readable — appropriate given records must survive restarts (this is persisted-state tolerance, not a compatibility shim, so it does not conflict with ADR-024).
- **Migration notes**: Not required.

### Quality Assurance Requirements
- **Test scenarios** (suggestions, not blockers):
  - Collection reference with a wrong `result_id` or wrong `receipt_digest` (currently only the forged `reviewer_attempt_id` case is covered) — pins the `EvidenceUnavailable` behavior explicitly.
  - A collection whose reviewer finished with a non-`succeeded` verdict (e.g., `failed`) — the derived-state check is currently only exercised via the pre-finish (running) case.
  - `reserve_execution` replay with `dry_run: true` (no write, same prior returned).
- **Integration points**: The future CampaignEvidence join (listed under `remaining`) is the real consumer of both new APIs; the source-slice evidence JSON correctly marks installed acceptance as outstanding.
- **Performance benchmarks**: Linear event scans (`ordinary_review_selection!` scans all events twice: assign + cancel) mirror existing patterns in this file; no regression concern at journal sizes in scope.

### Security Review
- **Attack vectors**: ✅ Strong. Forged attribution (wrong reviewer attempt), tampered bytes (sha/blob), escaped readers (thread/commit confinement), revoked selections, and superseded contracts all fail closed with distinct error classes. Reservation replay cannot mint a second dispatch or bypass retry budgets (verified against `CampaignPolicy.retry_decision`, `INFRASTRUCTURE_RETRIES = 2`).
- **Data flow**: No secrets introduced; digests are compared, never logged with content. The `proof` exposes only journal-derived binding metadata.
- **Compliance**: n/a.

### Refactoring Opportunities
- **Technical debt**: 🟢 Low — extract the 10-condition `unless` in `with_review_collection.rb:28-37` into a named predicate (e.g., `terminal_collection_matches?(result, terminals, completions, reference, assigned, reviewer)`) or a series of early raises with specific messages; this would also resolve the error-class consistency note above.
- **Code smells**: 🟢 Low — cancellation-scanning logic is now duplicated between `ordinary_review_assignment!` and `ordinary_review_selection!`; a shared `revoked?(events, review_id)` atom would remove the near-identical `events.any? { cancel_review ... }` blocks.
- **Future-proofing**: When the CampaignEvidence join lands, prefer reusing `with_review_collection!`'s proof/reader directly rather than re-deriving terminal state — the confinement contract is the valuable part.

---

**Out-of-scope observations** (noted, not flagged): the `.ace-tasks/...` plan/evidence files are process artifacts consistent with repo conventions; the evidence JSON honestly records RED-state errors (2) and open `remaining` items — no issues there.

**Recommended actions before merge**: address the Medium rescue-scope item (small, isolates consumer bugs from evidence failures); the rest are optional polish.