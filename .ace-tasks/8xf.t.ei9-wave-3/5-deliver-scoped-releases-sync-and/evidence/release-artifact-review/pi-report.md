All verification complete. Here is the structured review.

---

# Code Review: Canonical Release Artifact Retention (474f22ddf..936a9e7ff)

## Summary

**Verdict: ✅ Approve with minor follow-ups.** This increment adds a well-guarded `retain_release_artifact` operation to the ordinary lifecycle: one bounded binary transfer (64 MiB, single part), manifest/digest/metadata verification, canonical evidence import bound to the live native producer + current candidate + independent review + fresh release-decision authorization, with replay re-authorization and byte readback for the future publisher. I verified the wiring against the actual codebase (`ordinary_origin_at!`, `result_events`, `with_scope`, `bounded_blob`, `ServicePolicy#authorize!` required keys, `CallerAuthorizer`, journal `mutate` block semantics, server error normalization) — the contracts hold. No Critical or High issues found; report caps are genuinely unchanged and the deny-by-default posture is preserved.

## <a id="deep-diff-analysis"></a>Deep Diff Analysis

**Intent:** Source-only vertical slice for release-artifact retention — no publication dispatch, no grant consumption, no new release-decision database. Reuses Assign journal/TransferCodec/CanonicalEvidence and the lab's existing policy reader.

**Impact:**
- `TransferCodec` gains a `:release_artifact` purpose with `[total=64MiB, count=1, each=64MiB]` — validated *before* spooling (verified `validate!` destructuring order `total, count, each` at `transfer_codec.rb:143`).
- `CanonicalEvidence` gains the `"release-artifact"` kind with its own `[each=64MiB, total=64MiB, count=1]` limits and nonempty minimum; report kinds keep `REPORT_LIMITS` unchanged. Cross-kind limit bypass is closed: a release-artifact blob read as `"result"` fails the 64 KiB cap in `verified_bytes`.
- `OrdinaryLifecycle` routes the new upload through `authorize_transfer!` → `authorize_ordinary_release!` (full context check *before* bytes arrive — good DoS ordering), then `dispatch` → `retain_release_artifact`, which re-derives everything inside the CAS block. The `admitted_after_event_digest` (`events.last.fetch("digest")`) is correct because `JournalMutation#mutate` yields the *pre-mutation* chain.
- Lab composition wires `release_authorizer` as a closure over `coordinator` (assigned post-construction — safe since only invoked on retain, but see refactoring notes).

**Alternatives considered by author (per evidence):** initial wire tests expected server error subclasses; corrected to `EvidenceUnavailable` since `OrdinaryClient` deliberately normalizes refusals (`ordinary_client.rb:50`). Classification in `scope.json` is accurate — the product guards were already refusing.

## <a id="code-quality-assessment"></a>Code Quality Assessment

- **Complexity:** `release_context_at!` is dense but follows the sibling `OrdinaryReviews` style; every fetch is journal-derived, not wire-derived. The repeated `release_context_at!` (transfer-auth, pre-CAS, in-CAS, replay recheck) is intentional freshness, not accidental duplication.
- **Maintainability:** Good — limits centralized in `CanonicalEvidence::MAX_RELEASE_ARTIFACT_BYTES` for the manifest path; see Findings #2 for the two places that don't reference it.
- **Test coverage delta:** 4 new native socket tests (happy + replay idempotence + forged `input_digest`, refusal matrix over manifest/bytes/generation/head/native-binding, revoked-grant replay + readback, missing authorizer + cancelled review), 4 manifest tests (including bounded/repeated/oversized metadata), 5 codec/evidence tests. Red/green discipline with honest classification of expectation-reds. Assertion counts in the contract doc match the committed evidence files.

## <a id="architectural-analysis"></a>Architectural Analysis

- **Pattern compliance:** ✅ New module follows the established `Ordinary*` mixin + `OPERATIONS`/`TRANSFER_TRANSFERS` registration; flat molecule/authority placement; CHANGELOGs updated per ADR-020; no backward-compat shims (ADR-024).
- **Dependency changes:** None added — reuses `rubygems/package`, `zlib`, existing molecules. ✅ leans on stdlib/already-required deps.
- **Component boundaries:** ✅ Retention is an input, not a permit: no executor selection (`assert_empty @policy.fetch("operations")`), no dispatch, readback verified against the same canonical prefix. Assign stays lab-agnostic via the injected `release_authorizer` callable.

## Findings

### 🟡 Medium

**M1. Nil-unsafe `Etc.getpwuid(uid).name` in the release authorizer** — `ace-lab/lib/ace/lab/organisms/ordinary_authority_composition.rb:83-86`
```ruby
username = begin
  Etc.getpwuid(uid).name
rescue ArgumentError
  nil
end
```
`Etc.getpwuid` returns `nil` (not an error) for a uid with no passwd entry → `NoMethodError`, which `rescue ArgumentError` does not catch. Consequences: through the wire the server catch-all (`ordinary_server.rb:58`) masks it as a generic `evidence_unavailable` refusal instead of a clean `unauthorized`; through the direct composition path it raises `NoMethodError` where `SecurityError` is the contract (the new test at `ordinary_authority_composition_test.rb:139` with `caller_uid: 42001` only passes on machines where that uid resolves). This mirrors the pre-existing `protected_service_policy.rb:131` idiom, but deviates from the safer in-repo pattern `CallerAuthorizer.local_identity` (`&.name` + bare rescue, `caller_authorizer.rb:17-21`). Suggested fix:
```ruby
username = begin
  Etc.getpwuid(uid)&.name
rescue ArgumentError, NoMethodError
  nil
end
```
Fail-closed either way, so Medium (robustness/error-classification in a security-sensitive path), not High.

### 🔵 Low

**L1. 64 MiB limit encoded in three places with divergent tuple conventions** — `transfer_codec.rb:17` (`release_artifact: [64 * 1024 * 1024, 1, 64 * 1024 * 1024]`, order `total, count, each`) vs `canonical_evidence.rb:22` (`[MAX_RELEASE_ARTIFACT_BYTES, MAX_RELEASE_ARTIFACT_BYTES, 1]`, order `each, total, count`) vs the literal in `transfer_codec_test.rb:52`. The mirrored tables with *different* position semantics are a silent-divergence trap for future edits. Suggestion: reference `CanonicalEvidence::MAX_RELEASE_ARTIFACT_BYTES` from the codec LIMITS (or add a cross-check assertion tying the two tables together).

**L2. Broad `rescue SecurityError` mislabels failure origin** — `ordinary_release_artifacts.rb:73-74`. The rescue wraps the whole `release_context_at!` body (admission, `execution!`, origin/candidate/review lookups included), so a non-authorization `SecurityError` surfaces as "release artifact manifest authorization is unavailable". Narrow it to the `@release_authorizer.call(binding)` site (note `InvalidConfigurationError` from `verify_owner!` intentionally stays un-wrapped; the server normalizes it).

**L3. Test class reopen with filename mismatch** — `ordinary_release_artifacts_test.rb:11` reopens `OrdinaryReviewsTest` (declared `< AceAssignTestCase` in `ordinary_reviews_test.rb:13`). Works with explicit file selection and reuses the heavy native fixture (good), but a reader scanning `ordinary_reviews_test.rb` won't see the 4 extra tests live in another file. Acceptable trade-off; a one-line comment in the base file pointing at the reopeners would help.

**L4. `release_artifact_at!` is head-only by contract** — `ordinary_origin_at!` raises `Conflict` unless `commit == @journal.ref_value` (`ordinary_review_evidence.rb:86`), so the read API accepts an arbitrary `commit:` argument but only succeeds at the current ref. Consistent with sibling readers; worth a doc comment so the future publisher doesn't assume historical-commit reads.

## <a id="documentation-impact-assessment"></a>Documentation Impact Assessment

- **Required updates:** CHANGELOG entries present in both `ace-assign` and `ace-lab` (ADR-020 ✅). The operation contract lives in the task doc; when the publisher increment lands, `retain_release_artifact` params, the read API, and the 64 MiB bound should surface in ace-assign usage docs.
- **API changes:** Additive only (`release_authorizer:` constructor kwarg is optional; absence = deny-all, covered by test). No breaking changes; no migration notes needed (pre-1.0, ADR-024).

## <a id="quality-assurance-requirements"></a>Quality Assurance Requirements

- **Test scenarios for the next increment:** publisher-side immutable staging read via `release_artifact_at!` after the attempt leaves `running` (the `running: false` origin path is currently only exercised while running); a cross-limits regression tying codec LIMITS to `CanonicalEvidence::LIMITS` (see L1).
- **Integration points:** real `bin/ace-test` runs evidenced (socket 9/112, manifest/transfer/evidence 28/167, composition 11/94 — numbers verified against committed summaries). Configured Pi review still required per the contract before integration.
- **Performance:** native socket tests ~20-35s each (real process starts) — expected for this tier. Transient memory holds ~2-3 copies of the artifact (`transfer.bytes.dup`, `blobs` map, git write); acceptable at 64 MiB, worth remembering if the ceiling ever rises.

## <a id="security-review"></a>Security Review

- **Attack vectors:** upload bounded and digest-checked before admission; spool scratch cleaned on success and consumer failure; `metadata.gz` parsing is bounded (header size ≤ 1 MiB, decompression capped at `MAX+1` bytes — zip-bomb safe), single-entry enforced, `Gem::Specification.from_yaml` uses RubyGems' safe loader, and no build files are extracted or evaluated. No filesystem path is accepted as an artifact reference (CAS ref only, regex-anchored in `verified_bytes`).
- **Data flow:** `caller_uid` comes from the journal's kernel-authenticated origin, not the wire; live pane process must match the original `runtime_binding`; binding digest covers input+origin+authorization; the decision must match `operation/project/assignment/attempt/input_digest/target/candidate_head/caller_uid` exactly and be unexpired; visibility deny-by-default with fresh document loads each call (verified load-count semantics). Replay re-runs the full recheck — revoked grants refuse while retained bytes remain readable (correct: readback is not a permit).
- **Compliance:** consistent with ADR-025-style defense-in-depth posture; no secrets logged; only digests and references persisted.

## <a id="refactoring-opportunities"></a>Refactoring Opportunities

- **Technical debt:** the `coordinator = nil` forward-declared closure in `ordinary_authority_composition.rb:47-53` works but is fragile (a retain arriving before coordinator assignment would `NoMethodError` on nil); once the next increment lands, consider resolving coordinator lazily or constructing the authorizer after both objects exist.
- **Code smells:** `OPERATIONS`/`TRANSFER_OPERATIONS` one-liners in `ordinary_lifecycle.rb` are now very long — the established `%w[...] + MODULE::OPS` chaining pattern is preserved, so acceptable, but a future module may justify line-breaking.
- **Future proofing:** L1's shared-limit constant and M1's fix are the two changes I'd land before the publisher increment builds on top.

**Strengths worth acknowledging:** the pre-receipt authorization ordering, the triple recheck discipline (transfer-auth → pre-CAS → in-CAS → replay), unchanged report caps proven by cross-kind refusal tests, and the transparently retained red-run misclassifications in `scope.json` exemplify the repo's evidence contract.