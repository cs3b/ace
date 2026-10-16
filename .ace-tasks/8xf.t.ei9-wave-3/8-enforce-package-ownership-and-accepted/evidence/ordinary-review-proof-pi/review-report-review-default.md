# Code Review: Ordinary Candidate/Review Ingress and Canonical Merge Proof

## Summary

This slice adds source-level ordinary review ingress (`OrdinaryReviews`, `OrdinaryReviewEvidence`), a canonical merge-evidence join (`OrdinaryMergeEvidence`, `CommandExecution#test_evidence_at!`), an explicit `purpose: test` root-policy contract, and wires the fixed merge coordinator to re-verify canonical evidence at admission, effect-begin, and pre-effect. The design is consistently fail-closed, lock ordering is uniform, and the test/docs evidence matches the declared remaining work. No blocking correctness defects were found; the notable items are operational (filesystem-heavy verification under the journal writer lock) and process (missing CHANGELOG entries).

## Strengths

- ✅ `CommandExecution#test_evidence_at!` (`ace-assign/lib/ace/assign/authority/command_execution.rb:80-113`) enforces an exact, closed invariant set: 4-stage lifecycle, `purpose == "test"` with exact head/tree, root launcher (uid 0), kernel identity matching the root witness slice, executor cwd/uid binding, and byte-size caps. No inference from argv or exit status — exactly as the design doc requires.
- ✅ Lock discipline is sound and consistent: every scope acquires task key → assignment key in the same order (`ordinary_merge_evidence.rb:14-23`, `ordinary_review_evidence.rb:19-22`, `ordinary_completion.rb:33-34`), and the verify path acquires no exclusion locks, so the journal-writer-lock guard cannot invert against lifecycle locks — matching the stated invariant in the module comment.
- ✅ TOCTOU handling: review operations re-authorize under scope and again inside the CAS mutation block with `current_events`/`prefix`; merge evidence is pinned to a held CAS prefix and re-derived at each Forge-effect boundary (including after readback — both revocation tests cover the comment and merge-post seams).
- ✅ `ReceiptVerifier`'s `review_independence_verifier` hook cleanly replaces only the actor-equality branch; the strict default is preserved for every existing caller, and the new test (`receipt_verifier_test.rb:79-94`) correctly proves replace/deny/verdict-path behavior with a genuine self-review fixture ("fork-1" == producer actor).
- ✅ Honest test boundaries: `FixedMergeEvidenceFixture` is an explicitly documented boundary double, while `ordinary_reviews_test.rb` runs the real socket server, real Git bundles, real Unix process identities, and real journal CAS.
- ✅ Fail-closed composition: `merge_evidence_at!` requires `@command_evidence.journal.equal?(@journal)`; a missing owner refuses everywhere; client maps every refusal envelope to `EvidenceUnavailable` with "retain original mutation" semantics.

## Critical/Blocking Issues

*No issues found*

## High Issues

*No issues found*

## Medium Issues

### 1. Filesystem-heavy evidence re-verification runs under the journal writer lock

**Files:** `ace-assign/lib/ace/assign/organisms/attempt_coordinator.rb:352-364`, `ace-lab/lib/ace/lab/molecules/command_owner_admission.rb:63-75`, `ace-assign/lib/ace/assign/molecules/evidence_journal.rb:1482-1560`

`verify_fixed_merge_evidence!` is invoked from inside `update_fixed_merge_request`'s `with_lock` (via the CAS guard, re-run on every `CAS_ATTEMPTS` retry). The real `CommandOwnerAdmission#command_test_evidence!` reloads the policy document on every call (`@policy_loader.call` → `CommandPolicy.load`) and `verify_context!` walks up to 20,000 directory entries plus trusted-directory checks. Consequences:

- All journal writes (the single shared ordinary authority writer) serialize behind a filesystem walk per merge admission/begin/effect check.
- The hardcoded 30s deadline (`Process.clock_gettime(...) + 30`) can be exceeded on large source trees, producing spurious `EvidenceUnavailable` refusals and downstream lock-wait revocations — the exact risk class the plan's test map calls out.

**Suggested fix:** cache the loaded policy per process with a short TTL or fingerprint check, and inside the merge guard compare a cheap binding (policy fingerprint + source digests already stored in the definition) instead of re-walking the tree; reserve the full `verify_context!` walk for command admission (`command_request!`) where it already runs.

### 2. Missing CHANGELOG entries for both affected gems

**Files:** `ace-assign/CHANGELOG.md`, `ace-lab/CHANGELOG.md`

This slice adds user-visible operations (`submit_candidate`, `assign_review`, `export_candidate`, `accept_review`, `cancel_review`, `review_status`, `merge_evidence`), a new verifier hook, a coordinator constructor parameter, and a **breaking root-policy schema change** (`purpose` now required — `command_policy.rb:60-61` rejects every existing policy document without it). ADR-020 and the gem guide require a Keep-a-Changelog entry and semver bump with every change; neither gem's changelog was touched. The breaking policy change especially deserves an explicit "Changed/Breaking" note so operators know installed policies must add `purpose` before reload.

## Low Issues

### 1. Potential `NoMethodError` on nil `payload.data` in review-assignment scan

**File:** `ace-assign/lib/ace/assign/authority/ordinary_reviews.rb:151-153`

```ruby
cancelled = selected && events.any? { |event| ... event.dig("payload", "data", "review_id") == data.fetch("review_id") }
```

If an `assign_review` mutation event exists but its `payload.data` is nil, `selected` is truthy and `data.fetch` raises `NoMethodError` before the later `unless data && ...` nil-guard is reached. Journal-produced events always carry data, so this is unreachable in practice, and the failure stays fail-closed (server maps it to `evidence_unavailable`), but the guard below shows nil-data was intended to be handled. Use `data&.fetch("review_id")` in the scan.

### 2. Hardcoded 30s deadlines in the coordinator merge paths

**File:** `ace-assign/lib/ace/assign/organisms/attempt_coordinator.rb:356, 369-371`

The 30s constant is duplicated across `verify_fixed_merge_evidence!` and `with_fixed_merge_scope` with no caller-supplied knob, while `with_fixed_merge_evidence` holds an exclusive assignment lock across external Forge network I/O. Concurrent `finish`/review operations will burn their own deadlines waiting. Consider a named constant and a configurable budget for the effect interval.

### 3. `verify_fixed_merge_evidence!` rescue breadth vs. receiver error families

**File:** `ace-assign/lib/ace/assign/organisms/attempt_coordinator.rb:360-362`

The rescue converts `EvidenceUnavailable/UnauthorizedIdentity/Conflict` → `ReceiptRejected`, but `AttemptErrors::NotFound` (e.g., from `projection` in `test_evidence_at!`) propagates and surfaces as `ordinary_merge_unavailable` at admission and `:skipped_terminal` in `execute` rather than the evidence-refusal family. Post-admission this is near-impossible (append-only journal; admission already verified), so informational — but if it ever fires, a pending record would look "skipped" instead of "refused".

### 4. Documentation wording in the policy paragraph

**File:** `ace-lab/docs/usage.md:600-604`

After the insertion, the sentence flow is tangled: "…is never inferred from executable name or exit0. Source head/tree are both null for a non-Git probe…" — the "both null" clause now applies only to `purpose: command`, since test purpose requires nonnull source. A sentence split would remove the ambiguity. Same minor wrap artifact in `.ace-tasks/.../command-run-design.md:86-89`.

## Deep Diff Analysis

- **Ordinary review ingress (`ordinary_reviews.rb`, `ordinary_review_evidence.rb`)** — Intent: source-owned candidate/review operations on the existing journal/exclusion owners without protected launch shims. Impact: six new operations plus transfer bindings; independence resolved from native origins (distinct process generation, session UUID case-insensitive, pane) rather than actor names, enabling shared-account agents. Alternatives considered and rejected (per plan): actor aliases, shell-child PIDs, separate stores — correctly, since those are fabricable.
- **Canonical merge evidence (`ordinary_merge_evidence.rb`, `command_execution.rb`)** — Intent: only an accepted review plus root-witnessed `purpose: test` executions with exact candidate head/tree may ground a merge; worker check strings are not execution proof. Impact: `merge_evidence` read projection must be byte-copied into the retained request; admission/begin/pre-effect guards re-derive and compare exact projections. The four-stage + root-witness invariant set is the strongest part of the change.
- **`ReceiptVerifier` hook** — minimal, additive; preserves the strict distinct-actor default for all existing callers (verified: only `ordinary_verify_review!` passes the hook).
- **Coordinator/receiver gating** — removal of the receiver's name-based `reviewer_independence!` in favor of the canonical owner is a deliberate model change (documented in plan and usage docs); HITL authorization remains the merge authority.
- **Policy `purpose`** — strict-key validation makes the field mandatory and un-inferable; all in-repo policy documents were updated (`command_policy_test.rb`, `command_executor_probe.rb`); no other CommandPolicy-format documents exist in the tree (verified by grep).

## Code Quality Assessment

- **Complexity:** `ordinary_reviews.rb` methods are long (`ordinary_review_operation` ~60 lines) but follow the established CAS/authorize/re-authorize idiom of `ordinary_results.rb`; conditional density is high yet each branch maps to a distinct operation contract.
- **Maintainability:** heavy use of dig-chained invariant checks (`test_evidence_at!`, `ordinary_independent_agents!`) is verbose but deliberately explicit for a security boundary; extracting named predicate helpers would aid future readers.
- **Test coverage delta:** +5 feat tests (real server/Git/Unix), +1 fast verifier test, +2 policy tests, updated receiver/request/composition tests; evidence JSON records green runs for assign/lab suites with report IDs. Coverage aligns with the declared responsibility map; installed two-worker acceptance is honestly marked pending.

## Architectural Analysis

- **Pattern compliance:** ATOM layering respected (molecules/organisms/authority modules); no new stores; composition (`ordinary_authority_composition.rb:44-53`) reorders construction so lifecycle, command execution, and coordinator share one journal/exclusion owner, with `assert_same` composition tests proving the join.
- **Dependency changes:** `OrdinaryLifecycle` gains optional `command_evidence`; `AttemptCoordinator` gains optional `ordinary_merge_evidence` — both fail closed when absent. Read-only coordinator constructions (`ordinary_merge_request.rb:222`) correctly omit it.
- **Component boundaries:** `@journal.send(:chain_mutation_events, ...)` reaches into private journal API, but this mirrors the existing `ordinary_results.rb` precedent rather than introducing a new violation.

## Documentation Impact Assessment

- **Required updates:** `ace-lab/docs/usage.md` comprehensively covers the new operations, transfer semantics, and capability boundaries (campaign refusal, head-move refusal as current boundary). Task plan/design docs updated. **Missing: CHANGELOG entries and version bumps for ace-assign and ace-lab (Medium #2).**
- **API changes:** breaking for installed root-policy documents (mandatory `purpose`) — acceptable under ADR-024 pre-1.0, but should be called out as a Breaking changelog entry since it refuses previously-valid configs at load time.
- **Migration notes:** none required per ADR-024; a one-line "add `purpose` to each command" operator note in the changelog would still help.

## Quality Assurance Requirements

- **Test scenarios already covered:** generic/unfinished/failed/wrong-source/wrong-head test executions; same-session/same-process relabeling; self-review; changed reviewer binding mid-accept; corrupt canonical report bytes; replay after revocation; revocation between readback and Forge write (both seams); missing owner fail-closed.
- **Gaps worth adding later:** (1) a test exercising `with_fixed_merge_evidence` blocking a concurrent `finish` on the same assignment (exclusion interplay is currently only proven by construction); (2) a guard-latency test bounding `verify_context!` work; (3) `merge_evidence_at!` duplicate-ID rejection (`uniq` check) is untested directly.
- **Integration points:** installed composition test asserts the owner join; installed two-fresh-worker acceptance remains the declared gate (correctly not claimed here).

## Security Review

- **Attack vectors:** relabelled independence (blocked: session UUID + process generation + pane, case-insensitive session compare), oversized payloads (2048-byte argv reference cap, 12,000-byte reply cap, 16-artifact/256KB canonical caps), corrupt/tampered canonical bytes (SHA-256 re-derivation on every read, original-vs-canonical receipt comparison), TOCTOU (CAS prefix pinning + guard re-verification at each effect boundary), policy revocation races (tested at both pre-comment and pre-merge seams).
- **Data flow:** no secrets traverse the new payloads (peer uid, digests, argv, native identity tuples); `ReceiptVerifier`'s forbidden-field hygiene still applies to review receipts.
- **Model change note:** the receiver-level actor-name self-review guard was removed in favor of native-origin independence; the reviewer may share the producer's human account by design, with HITL authorization retaining merge authority. This is a documented, deliberate shift — worth a line in the threat-model docs when the campaign owner lands.

## Refactoring Opportunities

- Extract the long invariant chains in `test_evidence_at!` and `ordinary_independent_agents!` into named predicate methods for auditability.
- Consolidate the review-operation authorization triple-call (`authorize!` at server, `authorize_transfer!`, dispatch, in-scope, in-CAS) where redundant — currently up to five live peer checks per request; consistent with the codebase idiom but costly on hot paths.
- Introduce a shared deadline budget constant for merge/evidence verification instead of three hardcoded `+ 30` sites.

**Verdict:** Approve with comments — address the CHANGELOG/process gap before merge and consider the under-lock verification cost as a fast follow-up; the correctness and security posture of the slice itself is solid.