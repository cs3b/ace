# Code Review: Ordinary Campaign Owner — Review-Fix Delta (Rescue Scope, ReceiptRejected Reference Mismatches)

**Scope reviewed**: diff `d5b11b93e..22dd780f2` (ace-assign `ordinary_review_collection.rb` refactor + feat test extensions, ace-review test formatting, committed review-evidence artifacts). All findings were verified against the current repo source, not just the hunks; the changed module's blast radius was confirmed by search (`with_review_collection!` has exactly one definition and one test consumer).

**Overall verdict**: ✅ Correct, minimal fix delta. No Critical/Blocking, no High, no Medium issues. The prior review's Medium rescue-scope finding is properly resolved, the two Low items are addressed, and both declined optional refactors are justified. Evidence chain (RED → GREEN → focused rerun) is internally consistent.

**Strengths**
- ✅ **Rescue-scope fix is exactly right** (`ace-assign/lib/ace/assign/authority/ordinary_review_collection.rb:10-26`): `yield proof, reader` now sits outside any `rescue`; the `rescue KeyError, TypeError` lives inside the new private `ordinary_collection_proof!` and spans only construction/derivation calls (`strict!`, selection, origins, event scans, proof assembly). Consumer exceptions now propagate with identity preserved — pinned by `assert_same error, caught` in the test.
- ✅ **`ensure active = false` placement is correct**: it stays on `with_review_collection!`, wrapping the yield, so the reader still closes on exceptional consumer exit (verified by the new post-raise `escaped.call(artifact)` assertions). It also runs harmlessly when proof construction raises (locals are nil-initialized at parse time).
- ✅ **Terminal-check rewrite is provably equivalent**: the completion payload comparison now checks journal-internal self-consistency (`completions.first... == [result.fetch("result_id"), result.dig("receipt", "digest"), "succeeded"]`) and caller-reference equality moved to a separate `ReceiptRejected` check. By transitivity, the acceptance region is identical to the old conjunction; only the error class for a wrong reference changed (`EvidenceUnavailable` → `ReceiptRejected`), which is the intended fix. `result.fetch` in the new check is safe — the preceding terminal `unless` guarantees `result` is truthy.
- ✅ **Test design pins the exact new branches**: `"f" * 64` deliberately passes the 64-hex format gate so the digest mismatch reaches the `ReceiptRejected` branch (not the `ArgumentError` gate); `"wrong-result"` passes `token!`; mutated keys are restored (`original_value`) so later assertions in the long scenario stay valid.
- ✅ **Evidence discipline**: `classification.md` maps every prior finding to its resolution (including reasoned declines for the two optional refactors, consistent with the repo's simplest-implementation principle), and `manifest.json` verdict honestly marks the delta review pending.

---

## Enhanced Output Structure

### Deep Diff Analysis

**1. `with_review_collection!` split + `ordinary_collection_proof!` extraction (`ordinary_review_collection.rb:10-26, 28-80`)**
- **Intent**: Isolate evidence-construction failures (`EvidenceUnavailable`) from consumer-block bugs, per the prior review's Medium finding.
- **Impact**: Public surface unchanged (same method, same kwargs, same return — block value; `ensure` doesn't alter it). The private helper carries the rescue; reader construction (`CanonicalEvidence`, thread/commit confinement lambda) moved out of the rescued region. Grep confirms the module has a single consumer, so the refactor's blast radius is fully covered by the feat test.
- **Alternatives**: This is the shape the prior review recommended verbatim (proof helper with its own rescue, yield outside). No further indirection introduced — appropriate.

**2. Reference-mismatch split into `ReceiptRejected` (`ordinary_review_collection.rb:47-49`)**
- **Intent**: Distinguish "journal lacks an exact terminal execution" (evidence problem) from "caller's reference names a different execution" (reference problem), aligning with the existing forged-`reviewer_attempt_id` path.
- **Impact**: Error-family consistency improved; all three caller-reference mismatches (`reviewer_assignment_id`/`reviewer_attempt_id` via the earlier slice check, `result_id`, `receipt_digest`) now raise `ReceiptRejected`. Both new cases are executed in the regression.
- **Alternatives**: None needed.

**3. Test extensions (`ace-assign/test/feat/authority/ordinary_reviews_test.rb:259-281`)**
- **Intent**: Prove exception identity preservation, reader closure after consumer raises, and the new `ReceiptRejected` behavior for both reference keys.
- **Impact**: Adds 8 assertions inside the existing scenario test; placement and loop style match the file's conventions; no state leakage between iterations (reads only; reference restored each pass).

**4. Formatting fix (`ace-review/test/fast/organisms/campaign_convergence_test.rb:117`)**
- Blank line between tests — resolves the prior Low formatting note. No behavior change; the file is included in the focused 16/108 rerun.

**5. Committed evidence artifacts (`.ace-tasks/8xf.t.ei9-wave-3/.../ordinary-campaign-execution-review/*`)**
- RED (`rescue_red.json`: 1 failed / 9 assertions) → GREEN (`rescue_green.json`: 1 passed / 20 assertions) at `test/feat/authority/ordinary_reviews_test.rb:221`, plus focused ace-review rerun (16/108) and the pre-fix full review fast run (1007/3327). Counts and timestamps are consistent across `manifest.json`, `classification.md`, and the JSON reports. SHA-256 equality between the committed copies and the `.ace-local` sources is not independently verifiable in this read-only environment — unable to verify, not flagged.

### Code Quality Assessment
- **Complexity metrics**: The 10-condition terminal `unless` remains (deliberately — classification.md explains the remaining conjunction is one terminal-evidence invariant), but the compound method is gone: construction, validation, and yield are now separately readable. Net cognitive load reduced.
- **Maintainability index**: Good — private helper follows sibling naming (`ordinary_review_selection!`, `ordinary_review_receipt_at!`), no new dependencies, no public API change.
- **Test coverage delta**: Positive. New coverage: consumer `KeyError`/`TypeError` identity, post-raise reader closure, both reference-mismatch branches.

**Findings:**

- 🟢 **Low — reader-internal `KeyError`/`TypeError` mapping narrowed** (`ordinary_review_collection.rb:17-24`). `ordinary_result_context(result.fetch("binding"))` and `canonical.read(...)` execute inside the consumer's block, now outside any rescue; previously a raw `KeyError` from these would have been rewritten to `EvidenceUnavailable`. In practice unreachable for journal-admitted results: the proof guarantees the `binding` hash exists, and `CanonicalEvidence.read` raises its own typed `EvidenceUnavailable` on digest/bytes mismatch (proven by the corrupt-blob assertion in the GREEN rerun). Note and accept as design intent — consumer-scope code owning its exceptions is the point of the fix. If strict mapping is ever wanted, wrap only the two internal reader calls, never the yield.
- 🟢 **Low — CHANGELOG delta not recorded**. The ace-assign Unreleased "Added" entry ("Read canonical terminal review collection separately from approval…") still accurately describes the feature, and the error-class refinement is pre-release internal detail, so this is acceptable under ADR-020's intent; optionally fold a clause noting reference mismatches raise `ReceiptRejected` into that entry before release.
- 🟢 **Low — evidence file hygiene**: the four committed JSON reports and `review-report-review-default.md` lack trailing newlines (`\ No newline at end of file`). Cosmetic; generated artifacts, but a trailing newline would keep future ace-lint/markdown checks quiet.

### Architectural Analysis
- **Pattern compliance**: ✅ ATOM layering intact — the extraction is an intra-module refactor of an authority composition; the molecule usage (`CanonicalEvidence`, `CanonicalAttemptState`) is unchanged.
- **Dependency changes**: None. `OrdinaryReviewCollection` still included via `OrdinaryReviewEvidence` (`ordinary_review_evidence.rb:15`); `ordinary_collection_proof!` is private, reachable only from the host.
- **Component boundaries**: ✅ No approval leakage — `refute ... review_status ... accepted` still follows the consumer-exception loop; collection remains read-only evidence.

### Documentation Impact Assessment
- **Required updates**: `classification.md` accurately documents each disposition; `manifest.json` verdict ("Medium rescue scope fixed after reproduced RED, delta review pending") matches reality. No doc updates required by the code change itself.
- **API changes**: Non-breaking. Same public method and reference keys; only the exception class for wrong `result_id`/`receipt_digest` references changed (`EvidenceUnavailable` → `ReceiptRejected`), both within the attempt error family, and the feature is unreleased (ADR-024 applies).
- **Migration notes**: Not required.

### Quality Assurance Requirements
- **Test scenarios**: The prior review's optional scenarios (non-`succeeded` finished verdict for collection, `dry_run: true` reservation replay) remain unexecuted; `classification.md` argues they are covered by existing terminal-state and store transaction contracts — reasonable, carried over as suggestions only, not action items.
- **Integration points**: Post-fix, the full ace-assign fast suite was not rerun (only the single feat test RED→GREEN, plus ace-review focused/full runs). Given the confirmed single-consumer blast radius this is defensible, and `classification.md` transparently claims no new full-suite result; a full `ace-test ace-assign fast` pass before merge would be cheap insurance consistent with the repo's full-coverage bias.
- **Performance benchmarks**: No change — same event scans, one extra comparison per read.

### Security Review
- **Attack vectors**: ✅ Fail-closed preserved. Every tampered/mismatched input still raises; only the exception class changed. Reader confinement invariants (thread identity, journal-commit pin, artifact membership, active flag) are intact and re-proven after exceptional consumer exit. Forged attribution, tampered bytes, revoked selection, and reference mismatches each fail with distinct, typed errors.
- **Data flow**: No secrets; digests compared, never logged with content. The proof still exposes only journal-derived binding metadata.
- **Compliance**: n/a.

### Refactoring Opportunities
- **Technical debt**: None new. The remaining compound `unless` and the duplicated cancellation-scan predicates are explicitly dispositioned in `classification.md` with sound rationale (one terminal-evidence invariant; distinct selection semantics).
- **Code smells**: 🟢 Low — if the reader's internal calls ever grow, consider a small `ordinary_collection_read(artifact:)` helper so the "reader internals raise typed errors" property is structural rather than incidental.
- **Future-proofing**: When CampaignEvidence lands, consume `with_review_collection!`'s proof/reader directly rather than re-deriving terminal state (carried over from the prior review; still the right call).

---

**Out-of-scope observations** (noted, not flagged): the `.ace-tasks/...` evidence tree follows repo conventions; `manifest.json` `checks[].source` paths point at gitignored `.ace-local` locations as provenance pointers with committed copies alongside — intentional. `metadata.yml` contains empty optional fields (campaign binding, PR URL), consistent with the non-PR execution mode.

**Recommended actions before merge**: none blocking. The Medium fix is verified correct with reproduced RED→GREEN evidence; optionally address the Low notes (trailing newlines, one-line CHANGELOG clause, full ace-assign fast rerun) as polish.