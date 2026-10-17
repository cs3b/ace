All verification complete. Here is the structured review.

---

# Code Review: Review Follow-Up Increment (936a9e7ff..dbb95a746)

## Summary

**Verdict: ✅ Approve.** This increment dispositions every finding from the prior release-artifact review (`pi-report.md`): M1 is fixed and regression-pinned, L1 and L3/L4 are addressed, and L2 plus the coordinator forward-binding are declined with sound, verified rationale. I verified each remediation against the actual sources — the safe-navigation fix sits in a path where both lookup-failure behaviors (`ArgumentError` and `nil`) are now stub-tested machine-independently; the codec↔evidence cross-check destructures both LIMITS tables in their true positional orders; the reopener comment matches a real file; and the head-only readback comment matches the reader's actual `Conflict` precondition. No Critical, High, or Medium issues found in the changed lines.

## <a id="deep-diff-analysis"></a>Deep Diff Analysis

**1. Nil-safe uid→username resolution** — `ace-lab/lib/ace/lab/organisms/ordinary_authority_composition.rb:83`
- **Intent:** Resolve M1 — tolerate both boundary behaviors of `Etc.getpwuid` for an unresolvable uid (`ArgumentError` on the responder's Ruby 3.4.8, `nil` on platforms/Rubies that return it) instead of crashing into the server catch-all.
- **Impact:** `Etc.getpwuid(uid)&.name` plus the retained `rescue ArgumentError` covers both outcomes. Downstream is safe: `CallerAuthorizer.matchable_identities(nil, uid)` explicitly guards nil (`caller_authorizer.rb:30-33`), so numeric-uid principals still authorize via the `"41001"` grant key and no username is forged. This matches the established `CallerAuthorizer.local_identity` pattern (`&.name` at `caller_authorizer.rb:18`).
- **Alternatives:** The responder's `response.json` documents that the reviewer's original nil-return claim was not reproducible on their Ruby — rather than adjudicating the platform dispute, both behaviors are made tolerated *and* stub-pinned. That is the correct resolution.

**2. Boundary-pinning test** — `ace-lab/test/organisms/ordinary_authority_composition_test.rb:155-168`
- **Intent:** Make M1's fix environment-independent.
- **Impact:** The test stubs `Etc.getpwuid` with both a raising and a nil-returning lookup and asserts the authorizer still returns the exact decision through the full real composition (`verify_owner!` → `verify_join!` → visibility → `ServicePolicy#authorize!`). It also stabilizes the pre-existing sibling happy-path test, which calls the real `Etc.getpwuid(41001)` and previously depended on the machine's failure mode.

**3. Cross-tier limits regression tie** — `ace-assign/test/feat/transfer_codec_test.rb:51-57`
- **Intent:** Close L1's silent-divergence trap between the mirrored 64 MiB tables with different tuple conventions.
- **Impact:** Verified against both sources: `TransferCodec::LIMITS[:release_artifact]` is `[total=64MiB, count=1, each=64MiB]` (destructured `total, count, each` in `validate!`), `CanonicalEvidence::LIMITS["release-artifact"]` is `[each=64MiB, total=64MiB, count=1]` (destructured `max_each, max_total, max_count` in `import_plan`). The test's destructuring matches both, asserts `MAX_RELEASE_ARTIFACT_BYTES == each`, and ties the full tuples — any future single-sided edit now fails fast.

**4. Contract-comment follow-ups (L3, L4)** — `ordinary_release_artifacts.rb:18-19`, `ordinary_reviews_test.rb:13-15`
- **Impact:** The reopener comment points at `test/feat/authority/ordinary_release_artifacts_test.rb`, which genuinely reopens `OrdinaryReviewsTest` (verified). The readback comment accurately reflects the `commit == @journal.ref_value` precondition.

**5. Evidence bundle** — four archived runs (service 30/310, publication 16/138, policy-followup 12/96, limits-followup 17/96) plus review metadata and the disposition record.

## <a id="code-quality-assessment"></a>Code Quality Assessment

- **Complexity:** Minimal delta — one safe-navigation operator, two flat tests, two comments. No new branches in production code.
- **Maintainability:** Improved. The two most fragile spots flagged last round (divergent limit tables, environment-dependent uid lookup) are now guarded by tests rather than convention.
- **Test coverage delta:** +2 tests, +4 assertions, all green. Numbers cross-check: composition went 11/94 → 12/96 (exactly the new test's two loop assertions); the codec file contains exactly the 17 tests named in `limits-followup/raw_output.txt`.

## <a id="architectural-analysis"></a>Architectural Analysis

- **Pattern compliance:** ✅ Tests placed in the correct tiers (`test/organisms/`, `test/feat/`); the cross-check test keeps the tie adjacent to the transport table it guards.
- **Dependency changes:** The new `require "ace/assign/molecules/canonical_evidence"` in `transfer_codec_test.rb` is test-only — transport retains no storage dependency, an acceptable alternative to referencing the constant from the codec table (both live in ace-assign, so this was a layering choice, now guarded either way).
- **Component boundaries:** ✅ No interface changes; lib deltas are comments plus one operator. Evidence lives under the task's `evidence/` contract directory per repo practice.

## Findings

### 🔴 Critical / ❌ Blocking
*No issues found*

### 🟡 High
*No issues found*

### 🟢 Medium
*No issues found*

### 🔵 Low
*No issues found in the changed lines.*

**Out-of-scope observations (not code issues in this diff):**
- 💡 The identical un-hardened idiom `Etc.getpwuid(uid).name` remains at `ace-lab/lib/ace/lab/molecules/protected_service_policy.rb:131` (and `ordinary_owner_config.rb:163`, `command_executor.rb:51-52`, `ace-hitl/lib/ace/hitl/providers/lab/protected_assignment_binding.rb:19`). All pre-existing and fail-closed through server normalization, but now divergent from the pattern this diff establishes as canonical. Worth a small consistency follow-up before the publisher increment.
- ⚪ The composition site rescues only `ArgumentError` while `CallerAuthorizer.local_identity` uses a bare rescue. Both *known* outcomes are covered and pinned; the narrow rescue arguably swallows less. No action needed.
- ⚪ The generated `summary.json` / `pi-report.md` / `response.json` artifacts lack trailing newlines — cosmetic, machine-generated.

## <a id="documentation-impact-assessment"></a>Documentation Impact Assessment

- **Required updates:** None outstanding. Both gems' `Unreleased` CHANGELOG entries already cover the retention feature; these follow-ups (hardening, tests, comments) fold into the unreleased feature scope per Keep a Changelog practice, so no separate entry is required pre-release.
- **API changes:** None — comment-only lib changes. No migration notes (pre-1.0, ADR-024).
- **Dispositions:** L2 (broad `rescue SecurityError`) and the coordinator forward-binding are declined in `response.json` with rationale I verified: any `SecurityError` in the composite admission context still maps to `UnauthorizedIdentity` (no exception grants a permit), and the authorizer lambda is only reachable through the server graph constructed *after* `coordinator` assignment — no invocation path exists before assignment.

## <a id="quality-assurance-requirements"></a>Quality Assurance Requirements

- **Test scenarios:** None missing for this delta. Both remediation tests assert through real collaborators (composition graph, descriptor tables) rather than re-implementing logic.
- **Integration points:** ✅ Regression surface re-run and archived: service delivery/endcap replay (30/310), protected publication flow/authority/boundary (16/138), plus the two follow-up files. Counts in `response.json` match the committed `summary.json` files.
- **Performance:** No runtime cost change (safe navigation only); follow-up test runs are sub-second.

## <a id="security-review"></a>Security Review

- **Attack vectors:** The M1 fix does not widen authorization: with `username = nil`, `matchable_identities` yields only the numeric uid string, all-digit usernames remain excluded from the username namespace, and visibility still requires a configured principal. An unresolvable uid cannot forge identity — it simply matches (or fails) via its uid key.
- **Data flow:** Unchanged. `caller_uid` still originates from the kernel-authenticated journal binding, not the wire. No secrets in the committed evidence (hashes and counts only).
- **Compliance:** Fail-closed posture preserved in both tolerated failure modes; an exception or nil in this path can only refuse, never permit.

## <a id="refactoring-opportunities"></a>Refactoring Opportunities

- **Technical debt:** The sibling `Etc.getpwuid(...).name` sites listed above are the only remaining copies of the pre-fix idiom — a five-line consistency sweep would retire the pattern entirely.
- **Code smells:** None introduced.
- **Future proofing:** When the publisher increment lands, consider promoting the codec↔evidence limits tie into a shared named constant if a third table ever appears; two tables with a regression tie are fine, three would justify the constant.

**Strengths worth acknowledging:** the reviewer/responder disagreement over `getpwuid` behavior was resolved exactly right — make both outcomes tolerated and stub-pinned instead of arguing platform specifics; the cross-check test converts last round's most likely future-edit mistake into an immediate failure; and the disposition record in `response.json` gives auditable rationale for the two declines. This closes the follow-up cleanly ahead of the publisher increment.