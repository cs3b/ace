All changed files verified against their hosts, callers, and tests. Here is the structured review.

---

# Code Review: Foundation Review Follow-ups — Read-Error Context, Assessment Observation, v2 Format Docs, Regression Tests

## Review Summary

**Verdict: ✅ Approve.** No Critical, High, or Medium issues found. This diff is the remediation round for the prior foundation review's action items (D1, L1, L2, L3, T1 — L4 comment contracts included), plus the committed review-evidence artifacts under `.ace-tasks/`. Every fix was verified against the actual source: the observe-before-persist invariant, the rescue scope, the nil-safe guard, the docs claims against store/endcap rejection code, and the three new tests' execution paths. All items are correctly and minimally addressed.

## Deep Diff Analysis

| Change | Intent | Assessment |
|---|---|---|
| `candidate_head_comparison.rb:104-105` | Contextualize read-path failures (L2) | ✅ Single-level wrap, no recursion (the `reject!` inside `rescue` is not re-caught); scoped to `head_comparison_context` only, so admission-phase rejections in `with_head_comparison` ("Reviewed tree differs from accepted tree") stay unwrapped — the prefix reliably distinguishes read phase from admission phase |
| `candidate_head_comparison.rb:113` | Nil-safe `oid` guard (L3) | ✅ A two-field `ls-tree` line now cleanly rejects as "unsupported Git entry" instead of raising `NoMethodError`; the subsequent `{"oid" => oid}` construction is unreachable with a nil `oid` |
| `candidate_head_comparison.rb:9-10`, `campaign_head_assessments.rb:10-11` | Document mixin host contracts (L4) | ✅ Accurate one-line summaries of the required host surface |
| `campaign_head_assessments.rb:46` | Observe before persistence (L1) | ✅ Matches the `record_round` precedent (`campaign_manager.rb:151`); the replay path correctly skips it; `observe` self-dedupes on identical head/base |
| `campaigns.md:161` | Document the v2 format cut (D1) | ✅ Claims verified against code: store rejects missing `head_assessments` (`campaign_store.rb:71-72, 83-86`), endcap requires `accepted-result/v2` (`endcap_campaign_rounds.rb:40-43`), non-v2 schemas refused (`campaign_manager.rb:351-353`) |
| `candidate_transfer_test.rb:151, 157-170`; `campaign_head_assessments_test.rb:64, 101-112, 114-131` | Regression coverage (T1) | ✅ All three requested branches covered; see QA section for path verification |
| `.ace-tasks/.../evidence/*` | Review evidence artifacts | ℹ️ Out-of-scope observation: workflow artifacts, expected in this repo; hashes/metadata only, no secrets |

**Correctness verification highlights:**
- **Message-wrap safety:** No existing test asserts exact equality on messages produced inside `head_comparison_context` — all use `assert_match`/`assert_includes` (`candidate_transfer_test.rb:151, 229`), and `/oversized/` still matches the wrapped form. No regression.
- **Deadline test mechanics:** `deadline` is computed at `with_head_comparison` entry (real clock), and the stub is installed only inside the yield, so `admit`/`fetch` phases run unstubbed. The stubbed `monotonic` trips the `remaining <= 0` guard in `git()` (`candidate_transfer.rb:295-296`) → `Timeout::Error` → `ReadView` rescue → `EvidenceUnavailable "head comparison deadline expired"` — exactly the conversion T1 asked to cover. Stubbing private methods on instances is established practice in this suite (e.g., `event_commits_test.rb:97`, `launch_scope_admission_test.rb:442`).
- **Dirty-candidate test:** `Contract::Invalid < ArgumentError` (`campaign_contract.rb:13`), so `assert_raises(ArgumentError)` is correct; the raise at `campaign_head_assessments.rb:39-41` precedes both `observe` and `store.write`, and `assert_equal before, store.read(id)` transitively proves no persisted observation.
- **No-approval carry test:** `verify_head_carry!` fails at the last round's missing `approval` before ever consulting the evidence owner; `status` captures the message into `reasons` (`campaign_manager.rb:721-737`), so both `assert_includes` and `refute accepted` are on solid paths.

## Findings

### Correctness

*No issues found.* All five fixes behave as intended in the changed lines; error classes, fail-closed semantics, and store invariants are preserved throughout.

### Security Review

✅ **No new attack surface.** The added `rescue` re-raises (`reject!`) rather than swallowing — no error is silently converted to success, and the wrap cannot mask a rejection as a success path. The `oid&.match?` guard tightens inventory validation. No environment, process-spawn, or path changes in this diff. Evidence artifacts contain digests and token counts only.

### Code Quality Assessment

✅ Consistent with the surrounding fail-closed, exception-based style. Tests follow the suite's established `stub` patterns and fixture idioms.

**[Low | Suggestion] Wrap scope covers semantic bound rejections too** — `candidate_head_comparison.rb:104-105` prefixes *all* `ReceiptRejected` raised in the read path, including this method's own bound messages, yielding e.g. "Head comparison read failed: Complete head comparison context is oversized". Harmless today (all assertions are substring-based), but a future caller distinguishing "limit exceeded" from "git read failed" by message would conflate them. A context label parameter on `git()` (as the original L2 fix suggested) or narrowing the `rescue` to the git-dependent reads would keep semantic messages unwrapped. Not blocking.

### Architectural Analysis

✅ The `observe` placement mirrors `record_round` exactly (append event → observe → conditional write), keeping the observation invariant uniform across mutation entry points. The host-contract comments formalize the existing mixin pattern without introducing indirection. Docs placement in the restart/durability section is where operators will look. Consistent with ADR-024 (documented cut, no fallback) and ADR-011.

ℹ️ Pre-existing, unchanged by this diff: `with_verified_result!` retains the schema-less full-projection path alongside the v2 compact path (`campaign_manager.rb:351, 362`). Noted previously as a future simplification candidate; out of scope here.

### Documentation Impact Assessment

✅ D1 is resolved. The new paragraph's three factual claims each check out against code: required `head_assessments` key, v1 receipt rejection, and no migration/fallback. The "retain original bytes and provenance" guidance aligns with the existing retention policy in the same section. No other docs reference the old behavior.

### Quality Assurance Requirements

✅ All three T1 gaps are closed with meaningful assertions:
- Deadline expiry: exact-message assertion plus empty-authority cleanup check.
- Dirty candidate: message, error class, and byte-identical store state.
- No-approval carry: reason-string inclusion plus empty `head_assessments`.

Two existing tests were strengthened from class-only to message-level assertions (`candidate_transfer_test.rb:150-152`, `campaign_head_assessments_test.rb:64`) — good regression hygiene.

ℹ️ *Coverage note (not a gap):* the deadline test trips `git()`'s entry guard rather than a real `BoundedProcess` mid-read timeout; the `Timeout::Error → EvidenceUnavailable` conversion under test is identical either way, and BoundedProcess timing is that component's own concern.

### Refactoring Opportunities

- The prior review's R1 (memoize chain revalidation within a single projection pass) was declined with a recorded rationale in `response.json` — revalidation-over-caching preserves the authority boundary; reasonable to revisit only with evidence of hot chains.
- The `git()` context-label idea from the Low suggestion above would also serve the future `head_comparison_delta`-style read paths if more views are added.

## Action Items

| # | Severity | Item |
|---|---|---|
| — | Low (suggestion) | Optionally narrow the read-failure wrap or add a `git()` context label so semantic bound messages stay unwrapped |

*No blocking items.* 

**Strengths acknowledged:** each fix is minimal and lands exactly where the invariant lives (observe beside the write, wrap inside the read path, guard inside the parser); the strengthened existing assertions rather than only-new tests show genuine regression discipline; and the committed evidence file honestly records the declined R1 with its security rationale, keeping the delivery auditable.