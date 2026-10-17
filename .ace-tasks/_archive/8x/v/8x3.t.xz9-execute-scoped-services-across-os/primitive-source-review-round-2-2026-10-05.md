# Primitive source review round 2

Candidate e484a8a passed its full Assign test (842/3633, two existing edge
skips, receipt 8x41ji), but independent exact-source review rejected it for
reserved finish accepting terminal evidence without process_start and Git clean
filters changing artifact bytes. Passing tests did not override those defects.

<a id="detailed_review_format"></a>
<a id="enhanced_output_structure"></a>
<a id="deep_diff_analysis"></a>

## Deep Diff Analysis

The shared cleanup boundary and commit-pinned evidence reads are sound improvements. Two **High** correctness findings remain in the supplied head.

### 1. High — Reject reserved attempts before accepting a finish receipt

**Location:** [evidence_journal.rb:477](/tmp/ace-review-e484a8a/ace-assign/lib/ace/assign/molecules/evidence_journal.rb:477), [attempt_coordinator.rb:789](/tmp/ace-review-e484a8a/ace-assign/lib/ace/assign/organisms/attempt_coordinator.rb:789)

The new reservation state is protected in `start` and `reconcile`, but `finish` still ignores the state returned by `ensure_journal_consistent!` and permits reserved attempts through validation.

Reproduced outcomes:

- With no local cache, `finish` commits `receipt_accepted`, then raises `InvalidTransition` for `reserved → succeeded`. The authoritative journal nevertheless derives `succeeded`.
- With a stale cached `running` state, `finish` succeeds outright despite the journal containing no `process_start`.

Both paths remove the reservation from journal-active ownership without the required launch reconciliation.

**Suggested fix:** Apply authoritative state and reject reservations in `finish` before any journal write:

```ruby
derived = ensure_journal_consistent!(attempt) if attempt.managed?
attempt = attempt.with(state: derived.state) if derived
if attempt.state == "reserved"
  raise AttemptErrors::EvidenceUnavailable, "Protected launch reconciliation required"
end
```

Also validate the terminal transition before appending its receipt, so an illegal transition cannot leave accepted terminal evidence behind.

### 2. High — Preserve artifact bytes when staging canonical imports

**Location:** [journal_mutation.rb:56](/tmp/ace-review-e484a8a/ace-assign/lib/ace/assign/molecules/journal_mutation.rb:56)

`CanonicalEvidence` hashes the submitted bytes, but `git add` applies repository clean filters and line-ending conversion before committing them.

Reproduced with `core.autocrlf=true`: importing `"artifact\r\n"` succeeds, but `journal.blob` returns `"artifact\n"`. The accepted bytes therefore disagree with the recorded SHA-256 and byte count, causing canonical verification to reject an otherwise accepted import.

**Suggested fix:** Stage artifact bytes through Git object plumbing without filters, then insert their object IDs into the index:

```text
git hash-object -w --stdin --no-filters
git update-index --add --cacheinfo 100644,<object-id>,<artifact-path>
```

Pass the original bytes directly as stdin. Binary Ruby strings alone do not disable Git’s conversions.

<a id="code_quality_assessment"></a>

## Code Quality Assessment

*No issues found*

<a id="architectural_analysis"></a>

## Architectural Analysis

*No issues found*

<a id="documentation_impact_assessment"></a>

## Documentation Impact Assessment

*No issues found*

<a id="quality_assurance_requirements"></a>

## Quality Assurance Requirements

Executed against an isolated snapshot of `e484a8a`:

- Supplied focused tests: **69 tests, 389 assertions, zero failures/errors**.
- Additional regression checks: **3 tests, 7 assertions, three failures**, confirming the two findings above.

Add permanent coverage for reserved finishes with and without stale caches, and exact CRLF imports under Git conversion settings. [Regression checks](/tmp/ace-review-e484a8a/ace-assign/test/feat/review_regression_test.rb).

Coverage percentages were not measured; the full package suite was not executed.

<a id="security_review"></a>

## Security Review

*No issues found*

<a id="refactoring_opportunities"></a>

## Refactoring Opportunities

*No issues found*