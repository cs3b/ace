# Code Review: Head Comparison Evidence & Source-Owned Head Assessments (v2 Accepted Results)

## Review Summary

**Verdict: ✅ Approve with minor follow-ups.** No Critical or High issues found. The change adds a bounded, fail-closed two-bundle comparison capability to `CandidateTransfer`, and an append-only head-assessment chain to `CampaignManager` with a hard v1→v2 schema fork. Design discipline is strong throughout: every bound is enforced by rejection (never truncation), defaults stay strict, and revocation propagates historically.

---

## Deep Diff Analysis

| Change | Intent | Assessment |
|---|---|---|
| `candidate_head_comparison.rb` (new) | Compare two independently verified bundles as bare Git objects, no materialization | ✅ Correct nesting: `before` and `after` each pass `admit` against an *empty* repo before the verified reviewed bundle is fetched into the after-quarantine; tree bindings re-checked against declared trees |
| `campaign_head_assessments.rb` (new) | Source-owned nonsemantic carry across head/base changes | ✅ Exact-prefix binding, replay idempotence by `input_digest`, chain re-derivation on every read |
| `campaign_manager.rb` v2 snapshot | Separate reviewed vs. accepted head, bind assessment digest | ✅ Field lists correctly sorted; prefix currency extended to 6 fields; `result_identity_for` now includes `head_assessments` so identity rotates per assessment |
| `campaign_evidence.rb` | Replace string-inequality self-approval check with `verify_independence!` callback | ✅ Default (`producer != reviewer`) preserved; callback must return exactly `true` (truthy-string rejected — tested); enforcement added at *both* parse and verify paths, so no window where a self-approval round is persisted |
| `endcap_campaign_rounds.rb`, store, tests | Hard v1 refusal | ✅ Consistent across producer, verifier, and store validation |

**Correctness verification highlights:**
- `verify_head_carry!` chain walk terminates (each iteration shrinks `head_assessments` by one) and requires each event's `to` to equal the next iteration's target — chaining is sound (`campaign_head_assessments.rb:86-115`).
- Reverting the head to the originally-reviewed head short-circuits to acceptance without an assessment — semantically correct (reviewed content is present again).
- Append-only retained verification still works after later assessments: `verify_retained_result!` with the pre-assessment snapshot passes because the prefix cut yields empty `head_assessments` matching the old digest (covered by `campaign_head_assessments_test.rb:75-79`).
- Size accounting in `head_comparison_context` is belt-and-braces correct: per-part subtraction with `.negative?` checks, per-blob `cat-file -s` pre-check, plus a final whole-document bound; `BoundedProcess` oversized results are rejected, never truncated.
- Nested-payload replay (`accepted_snapshot_prefix!` inside `verify_head_carry!`) operates on prefix copies with all keys intact — verified against the store record structure.

## Findings

### Correctness

**[Low] L1 — `record_head_assessment` skips `observe()`, leaving `head_transitions` stale**
`campaign_head_assessments.rb:38-42` writes the record directly but never calls `observe(record, head, base)` (as `record_round` does at `campaign_manager.rb:151`). The transition only appears after a later `finish`. Diagnostics-only, but inconsistent with the existing observation invariant.
*Fix:* add `observe(record, head, base)` before `store.write`.

**[Low] L2 — Misleading failure message on comparison read paths**
`candidate_head_comparison.rb` relies on the host `git()` helper, whose failure message is always "Candidate Git verification failed" (`candidate_transfer.rb:305`). A missing base commit in a bundle (e.g., the `"f" * 40` test) or an oversized `ls-tree` surfaces as a "verification" failure even though this is a read view. The existing test only asserts the error class.
*Fix:* pass a context label into `git()` or rescue-and-rewrap in `head_comparison_context`.

**[Low] L3 — Nil-`oid` ordering in inventory validation**
`candidate_head_comparison.rb:99-101`: if an `ls-tree` line had only two fields, `oid` is `nil` and `oid.match?` would raise `NoMethodError` before the guard completes. Unreachable with real git output and identical to the pre-existing pattern in `materialize`; noting for consistency only. Reordering `oid&.match?` into the short-circuit chain would make it a clean reject.

### Security Review

✅ **Strong.** Specifically verified:
- Environment sanitization hardened correctly: `GIT_ATTR_NOSYSTEM=1` + `core.attributesFile=/dev/null` added (`candidate_transfer.rb:299-303`), and the adversarial test (`candidate_transfer_test.rb:161-193`) plants an evil `.gitattributes`, `GIT_EXTERNAL_DIFF`, and `GIT_CONFIG_COUNT` config injection, then asserts no marker file was created — the child env is rebuilt from scratch, so injected vars never reach git.
- Symlinks are read as blob bytes (`cat-file blob`, mode `120000`), never followed or materialized; submodule/gitlink entries are rejected as unsupported entries.
- `ReadView` thread/lifetime confinement (thread identity + `close`) is enforced and tested, including cross-thread and post-block escape.
- Candidate bundles are never executed; both bundles are `fsck --full --strict`-verified against empty repos before contributing objects.
- `review_independence` trust model: default strict inequality; the callback is an installed-owner capability, must return exactly `true`, and is re-checked on historical consumption (`campaign_evidence_test.rb:32-56`). Documented limitation ("pure callback tests do not attest native installed authority") is honestly recorded in the evidence file.

### Code Quality Assessment

✅ Complexity is high but justified by the domain (authority/evidence chaining). Failure paths are uniformly exception-based and fail-closed. Constants (`HEAD_PROOF_FIELDS`, `SNAPSHOT_PREFIX_FIELDS`, `ACCEPTED_SNAPSHOT_FIELDS`) are correctly sorted for `keys.sort` comparisons — verified element by element.

**[Low] L4 — Mixin implicit host contract**
Both new modules (`CandidateHeadComparison`, `CampaignHeadAssessments`) depend on host internals: `admit`/`git`/`reject!`/`monotonic`/`review_bytes`/`@root`/`self.class::SHA`, and `store`/`@evidence`/`@head_assessment_evidence`/`accepted_snapshot_prefix!`/`current_revisions`/`clean_candidate?`/`projection`/`immutable_projection` respectively. This mirrors the existing `CampaignReadView`/`Endcap` style and keeps files focused, but nothing documents the required host surface. *Suggestion:* one comment line listing the host contract per module (the module header comments partially do this), or extract a collaborator object later.

### Architectural Analysis

✅ Consistent with ADR-011 (organism orchestrating molecules/atoms), ADR-024 (no BC — v1 refused everywhere in one coordinated change), ADR-029/030 where relevant. The v2 schema adds only bound fields; the "no new rounds/budget reset" invariant is structurally guaranteed because `CampaignProjection`/`CampaignPolicy` never read `head_assessments` — verified.

ℹ️ *Design observation (not a defect):* a campaign accepted via head carry reads as **not accepted** under a default-configured manager (e.g., the one built by `ReceiptVerifier#verify_campaign`), since carry verification requires the installed callback. This is the documented "source capability" split; worth remembering when wiring the ordinary composition later (already listed under `remaining` in the evidence file).

### Documentation Impact Assessment

**[Medium] D1 — Store-format break is undocumented against the durability promise**
`campaign_store.rb:71,84` now rejects persisted records lacking `head_assessments` ("corrupt campaign … missing head_assessments"), and `endcap_campaign_rounds.rb:40` + `with_verified_result!` refuse v1 results. ADR-024 makes this policy-legal, but `docs/campaigns.md` §"Restart, contract changes and failures" still instructs users to *retain* `.ace-local/review/campaigns/` across restarts without noting that records written by a pre-v2 binary become unreadable and previously issued v1 receipts can no longer be verified. *Fix:* add one sentence to that section stating the v2 format cut and its effect on retained records.

Otherwise docs are accurate and match implementation (`record_head_assessment` signature, digest semantics, "direct approval has equal reviewed and accepted heads", refusal paths).

### Quality Assurance Requirements

Test coverage is genuinely good: nonancestor bundles, binary/symlink preservation with execution-attempt assertions, expanded-limit refusal, tree-mismatch refusal, thread escape, restart determinism (`contexts.first == contexts.last`), budget preservation, replay conflict, stale prefix, tampered `to`, missing check evidence, chain-of-two with full re-verification and revocation, v1 refusal.

**[Low] T1 — Remaining gaps worth adding:**
- No test for `ReadView` deadline expiry (`Timeout::Error` → `EvidenceUnavailable` conversion at `candidate_head_comparison.rb:17-21`); the "and expires" test name covers lifetime escape, not timeout.
- No test that `record_head_assessment` refuses a dirty candidate (`clean_candidate?` false branch).
- No test for the "head carry has no independent reviewed round" branch (`campaign_head_assessments.rb:89`) — a campaign whose last round lacks approval.

### Refactoring Opportunities

- **[Low] R1:** Repeated full-chain revalidation: every `status`/`finish`/`accepted_result_snapshot` on a carried campaign re-invokes the callback for each chain event plus check-evidence reads, and `record_head_assessment` re-derives the proof again via its final `projection(record)`. Correct-by-design (revalidation over caching), but if chains grow, consider memoizing within a single projection pass only.
- ℹ️ `with_verified_result!` retains the schema-less "full projection" result path (`compact = result["schema"] == v2` is only reachable when the key exists); pre-existing dual mode, unchanged by this diff — noting as future simplification candidate.

---

## Action Items

| # | Severity | Item |
|---|---|---|
| D1 | Medium | Document the v2 store/result format break in `docs/campaigns.md` §Restart |
| L1 | Low | Call `observe(record, head, base)` in `record_head_assessment` |
| L2 | Low | Contextualize `git()` failure messages for comparison read paths |
| T1 | Low | Add timeout-expiry, dirty-candidate, and no-approval-branch tests |

**Strengths acknowledged:** the "verify each bundle independently before it can contribute objects" construction, the adversarial no-execution test, and the exact-prefix append-only chain with revocation propagation are excellent security engineering, and the honest evidence file (RED reports, limits, remaining work) makes the delivery state easy to audit.