# Code Review: NotFound Classification Correction, CHANGELOGs, and Evidence Delta

## Summary

This delta closes the follow-up items from the prior Pi review of `03dfdb1a2`: (1) `AttemptErrors::NotFound` raised by an unknown command reference is now converted to `ReceiptRejected` inside `verify_fixed_merge_evidence!`, with a red/green regression proving the classification; (2) Keep-a-Changelog entries land for both affected gems, including an explicit breaking-callout for the mandatory `purpose` policy field; (3) the tangled policy sentence in `ace-lab/docs/usage.md` is split; (4) the review evidence bundle (disposition, metadata, manifests, regression JSONs) is retained. The one-line product change is correct, complete across all three merge-guard sites, and does not mask record-level `NotFound` conditions. No blocking, high, or medium findings.

## Strengths

- ✅ **Single funnel, full coverage.** All three merge verification sites (`admit_fixed_merge_request` guard at `ace-assign/lib/ace/assign/organisms/attempt_coordinator.rb:332`, `begin_fixed_merge_effect` guard at `:352`, `with_fixed_merge_evidence` at `:356`) route through the one `verify_fixed_merge_evidence!` method, so adding `AttemptErrors::NotFound` to the rescue at `:372` fixes admission, effect-begin, and pre-effect classification in one edit — the existing test then re-verifies begin and pre-effect refusal paths after the missing-reference admission attempt.
- ✅ **No masking of distinct semantics.** Record-level `NotFound` conditions still propagate as `NotFound`: the pre-scope check at `attempt_coordinator.rb:350`, and the journal lookups in `evidence_journal.rb:1365`/`:1386`, all sit outside the rescue, which only wraps the evidence-verification subtree. Verified: the only `NotFound` source inside that subtree is `CommandExecution#projection` (`command_execution.rb:154`, "command reference is unknown") — exactly the intended target; sibling verifiers raise `EvidenceUnavailable`/`Conflict`/`KeyError→ReceiptRejected`.
- ✅ **Valid regression proof.** The new test reference `"missing-command"` matches `ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,63}\z/` (`command_execution.rb:18`), so it passes the selector check and genuinely reaches the `NotFound` path — confirmed by the red-run backtrace in `unknown-command-regression.json`. The test deep-clones via `Marshal` (matching the established forged-record idiom) and asserts fail-closed no-write (`assert_nil coordinator.fixed_merge_record("merge-1")`).
- ✅ **CHANGELOG entries address the prior Medium #2 properly.** Both gems get `## [Unreleased]` entries in correct Keep-a-Changelog section order; `ace-lab` adds a `### Changed` entry explicitly calling out that policy entries without `purpose` are refused — the breaking-change operator note the prior review requested. Version bumps are deferred to the coordinated root cut per the disposition, which is consistent and stated.
- ✅ **Docs fix resolves the ambiguity.** The reworded paragraph at `ace-lab/docs/usage.md:603-606` now cleanly separates "test purpose requires nonnull source" from "with `purpose: command`, source may both be null for a non-Git probe."
- ✅ **Evidence bundle is internally consistent.** Disposition numbers match the JSONs (9 tests / 121 assertions / PASS at 20:52; red at 20:58:57 with the `NotFound` backtrace; green 13 assertions at 21:00:06), and the red/green sequencing matches the stated "no product change after the protected run until the separately recorded correction."

## Critical/Blocking Issues

*No issues found*

## High Issues

*No issues found*

## Medium Issues

*No issues found*

## Low Issues

### 1. Protected regression suite was not re-run after the product-code change

**Files:** `.ace-tasks/.../evidence/ordinary-review-proof-pi/protected-regression.json`, `unknown-command-regression.json`

The 9-test protected regression ran at 20:52:28, before the rescue edit (~20:59); after the change only the single targeted test re-ran green. The protected files (`endcap_review_plan_test.rb`, `review_import_interruption_test.rb`) do not exercise the fixed-merge path, so risk is minimal, but the repo's merge policy is executed-tests-on-the-final-surface. **Suggested fix:** re-run the protected regression (or the full ace-assign suite via `ace-test`) on the post-correction tree before merge and record it alongside this evidence.

### 2. Missing trailing newline in the retained review report

**File:** `.ace-tasks/.../evidence/ordinary-review-proof-pi/review-report-review-default.md:117`

The report ends without a newline (diff marker `\ No newline at end of file`). Trivial evidence-hygiene nit; every other retained artifact ends cleanly.

**Unable to verify (noted, not flagged):** the SHA-256 digests in `llm_metadata.yml`/`metadata.yml` against the retained files, and the `metadata.yml` empty PR/campaign fields — the latter appears intentional for a source-manifest review without PR binding.

## Deep Diff Analysis

- **Rescue broadening (`attempt_coordinator.rb:372`)** — Intent: classify an unknown command reference as an evidence refusal (`ReceiptRejected`) rather than letting `NotFound` leak and render a pending merge "skipped" instead of "refused" (prior review Low #3). Impact: confined to the merge guard; message "canonical ordinary review or executed test evidence is unavailable" remains accurate for the new covered case. Alternatives (rescuing at `CommandExecution#projection` or mapping in the journal) would be broader than needed; the chosen site is the narrowest correct one.
- **Test addition (`ordinary_reviews_test.rb:89-92`)** — Intent: prove the classification end-to-end through the real journal using canonical records. The mutation targets `request.test_evidence[0].reference`, which is exactly the field consumed by `verify_merge_evidence_at!` → `merge_evidence_at!` → `test_evidence_at!`; the request-vs-projection equality check is never reached because the evidence derivation fails first, so the assertion exercises the intended seam, not an accidental one.
- **CHANGELOG/docs** — documentation-only, directly discharging the prior review's Medium #2 and Low #4.

## Code Quality Assessment

- **Complexity:** unchanged; the edit adds one symbol to an existing rescue list.
- **Maintainability:** the rescue list now enumerates four error families; acceptable given each maps to a distinct failure mode inside the verification subtree. A comment listing which raiser produces `NotFound` would help future auditors, but is optional.
- **Test coverage delta:** +2 assertions on an existing feat test with real server/Git/journal fixtures; red/green evidence retained with report IDs.

## Architectural Analysis

- **Pattern compliance:** no layering changes; error-family normalization stays in the organism (coordinator) where the guard contract lives, leaving `CommandExecution`'s `NotFound` semantics intact for its own callers (e.g., `command_status` still surfaces "missing" refusals via `ordinary_server.rb:54-55`).
- **Dependency changes:** none.
- **Component boundaries:** unchanged; no new private-API reach-ins.

## Documentation Impact Assessment

- **Required updates:** delivered — both CHANGELOGs and `usage.md` wording. The `command-run-design.md` wrap artifact mentioned in the prior review reads coherently at HEAD and was reasonably left alone.
- **API changes:** none in this delta; the breaking `purpose` requirement is now documented as a `Changed` entry with an operator-facing refusal note.
- **Migration notes:** covered by the changelog line ("previous entries without purpose are refused"); consistent with ADR-024.

## Quality Assurance Requirements

- **Test scenarios:** the unknown-command-reference case is now covered at admission with fail-closed no-write assertion; begin/pre-effect refusal paths re-verified in the same test.
- **Gaps:** post-change protected-suite re-run (Low #1). The prior review's optional suggestions (duplicate-ID `uniq` direct test, exclusion-interplay test) remain future work by the disposition's own framing and are not action items here.
- **Integration points:** unchanged; no composition changes in this delta.

## Security Review

- **Attack vectors:** none introduced. The change tightens classification only; a forged/unknown test reference is refused at every guard site with no durable write (asserted). No new data flows.
- **Data flow:** unchanged.

## Refactoring Opportunities

- Optional: a short comment on the rescue listing the `NotFound` producer (`CommandExecution#projection`) to keep the error-family mapping auditable.

**Verdict:** Approve — the targeted correction is correct, minimal, and fully covers the classification gap it set out to fix; the process/doc items from the prior review are discharged. Re-running the protected regression on the post-correction tree before merge is recommended (Low #1) but not blocking.