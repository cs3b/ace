# ei9.8 campaign join state — 2026-10-17

## Captain decision — review_context large-prompt ingress: APPROVED

Decided 2026-10-17 by the Captain (this session, direct question): the
composition's pending context-size proposal is APPROVED as proposed — a closed
purpose-specific canonical `review_context` kind/transfer, permitted ONLY for
an actual owner-selected campaign review-collect attempt with a matching
canonical begin; capped by the existing shared complete-context limit
(`Review::Atoms::CampaignContract::MAX_HEAD_CONTEXT_BYTES`, 128MiB); metadata,
reports and feedback stay at their current small limits; aggregate bytes/count
bounded; exact descriptor provenance retained; already-canonical prompt bytes
are reused during round ingestion instead of re-upload. No arbitrary result may
select the larger kind. Implementation happens with the composition
completion, after the reviewed join lands.

Worktree `.ace-wt/ei9-campaign-join` (branch codex/ei9-campaign-join) from main
`6a18dc11a`. Both reviewed lines cherry-picked:

- Campaign reviewer execution (5 commits, from ei9-ordinary-campaign-owner
  @54096540f): e7ed2210a, 2e37e57bd, a4e0da1a8, 2c083745d, 92dd58a52 — clean.
- Candidate git-root (8 commits, from ei9-candidate-git-root @9d33acd5a):
  5e16a7d94, 93c66a01d, b3f9119b4, a2bc43b40, 0752d0943, 01aa91836, 94656fb86,
  397e9fd13 — four conflict resolutions:
  1. `.5` task spec: union of candidate-test-view contract + standing external
     blocker paragraph.
  2. `ordinary_lifecycle.rb`: union — OrdinaryReleaseArtifacts include/ops AND
     candidate_reference operation (both dispatch branches).
  3. `ordinary_review_evidence.rb`: OrdinaryReviewCollection include AND the
     CandidateReferenceView/with_candidate_reference machinery.
  4. `candidate_transfer.rb` materialize: max_entries prefix-inventory preflight
     (incoming) inserted BEFORE main's MAX_OBJECTS check + batch codec parse
     (kept main's batch sizes/each_candidate_blob structure; incoming's per-blob
     cat-file loop dropped as subsumed). materialize/materialize_repository
     signatures carry max_entries.
  Plus CHANGELOG unions (ace-assign, ace-lab).

## Current state: focused receipts GREEN; feat-group RED is pre-existing

Executed on the joined tree (all green; per-file counts corrected per the
independent review — an earlier table row misattributed a 3-file aggregate):

| File | Result |
|---|---|
| assign feat/candidate_transfer_test.rb | 24 tests / 454 assertions PASS (max_entries preflight + batch codec + campaign read views) |
| assign feat/authority/ordinary_reviews_test.rb | 9 / 98 PASS (union resolution incl. collection + candidate reference) |
| assign feat/authority/command_execution_test.rb | 8 / 42 PASS |
| lab molecules/command_policy_test.rb | 6 / 33 PASS |
| lab molecules/command_test_runtime_test.rb | 5 / 37 PASS |
| lab organisms/command_run_client_test.rb | 8 / 31 PASS |
| assign feat/installed_journal_read_test.rb | 4 / 23 PASS (historical reader) |
| assign feat/canonical_receipt_reader_test.rb | 3 / 17 PASS (historical reader) |

The full `feat` group fails fast with 19 failures on the joined tree — but the
SAME group on unmodified main ALSO fails fast with 19 (different first-seven;
e.g. `test_production_parent_observer_driver_abort…` NoMethodError close is
reproduced on main standalone). The feat group is systemically red on this
macOS host (Linux-native fixtures) and is not a usable join gate; the merge
gate remains the default fast suite plus focused groups and independent
review, per policy.

## Remaining for the join

1. Reconcile the scope registration/close contract across both lines (all 19
   failures; check latest AND historical readers per the handoff).
2. Re-run focused groups: assign feat, review fast/reservation, lab command
   tests, real Unix fixtures.
3. Campaign composition WIP (ei9-campaign-composition @69e742e14, 13 dirty
   files): NOT a pickable block — needs its own review per
   ordinary-campaign-composition-handoff.md; includes the unapproved
   review_context 128MiB prompt-cap decision (closed kind/purpose, owner-only
   selection, full prompt bytes + digests, no global limit raises).
4. Independent review of the joined delta before any merge to main.

## Independent review — VERDICT: APPROVE (2026-10-17)

Independent adversarial review executed at HEAD f0be9eed8 (isolated git-archive
extraction; report at .ace-local/review-campaign-join/review-report.md):
16 commits = 3 spec + 13 picks, subjects and patch-ids reconciled against both
origin worktrees (9/13 byte-exact; the 4 differing picks differ only at the
four conflict sites); all 8 focused receipts re-run and passing with matching
counts; all four conflict resolutions verified line-quoted; no duplicate
definitions; lockfiles untouched; ace-review fast suite 1008/3330 PASS at HEAD.

Findings disposition:
1. MEDIUM — scope statement corrected: picks e7ed2210a and a4e0da1a8 DO carry
   five ace-review files (+58/-4: reserve_execution replay request-id in
   campaign_manager.rb, request_id validation in campaign_store.rb, docs,
   CHANGELOG, tests), byte-identical to Line A's independently reviewed HEAD.
2. MEDIUM operational — the worktree transiently held composition-port WIP
   during review; the WIP is committed on branch
   codex/ei9-campaign-composition-join (05e8aa967) and the join branch
   worktree is verified clean (`git status --porcelain` empty at f0be9eed8).
   Lesson recorded: never switch a reviewed worktree's branch mid-review.
3. LOW — receipt table corrected above (24/454 per-file; 41/594 was a 3-file
   aggregate invocation).

Merge gate status: independent verdict APPROVE retained. Remaining before
merge to main: the mandatory full default suite on this branch, then merge
(no republish of existing versions; version bumps/floors only at the next
coordinated release).

## Composition completion progress (branch codex/ei9-campaign-composition-join)

- Port rebased onto merged main (0115b34f4).
- Join #1 (campaign merge gate) IMPLEMENTED and proven (3627c8aea):
  merge_evidence_at! refuses campaign-associated candidates before review
  resolution — an ordinary direct review can no longer bypass CampaignManager
  acceptance; the fixed merge admission inherits the refusal through the same
  projection. The read transport surfaces the server rejection as
  evidence_unavailable (assertion class adjusted accordingly). Receipt:
  ordinary_reviews 10 tests / 121 assertions PASS.
- Next joins in order: review_context large-prompt ingress under the approved
  decision (TransferCodec purpose + campaign-begin-bound submit_result
  eligibility + CanonicalEvidence kind + aggregate bounds + tests), public
  retained driver, round ingestion proofs, cancellation resolution, historical
  test-evidence wiring, comprehensive tests + actual Pi review.

## review_context ingress implementation (in progress, branch codex/ei9-campaign-composition-join)

Implemented under the Captain-approved decision: CandidateLimits gains
REVIEW_CONTEXT_BYTES (= CampaignContract::MAX_HEAD_CONTEXT_BYTES) and
REVIEW_CONTEXT_ARTIFACTS (8); CanonicalEvidence gains the closed
"review-context" kind (reviewer role, shared cap for each/total, 8 artifacts);
TransferCodec gains the :review_context purpose (receipt ≤16KiB + up to 8
context parts under the shared cap) with a fixed receipt-size check;
OrdinaryResults gains the submit_review_context operation
(REVIEW_CONTEXT_KEYS; eligibility validated against the PRODUCER assignment's
real journal events: exactly one non-cancelled assign_review naming this
reviewer attempt with campaign data, plus a matching canonical campaign_begin
event; reviewer live identity verified at head; import under the review-context
kind; event type review_context_submitted; ordinary receipts keep their small
budgets and can never select this purpose). Fixed en route: method-name
collision — the handler is ordinary_review_context_submission (the evidence
module already defines ordinary_review_context(binding)).

Regression state: existing 10 tests / 121 assertions still pass with the
ingress code in place. The NEW focused test
(test_review_context_ingestion_binds_campaign_selection_and_matching_begin)
is RED at its campaign_begin step and the debugging trail is retained here
for the next session: with temporary instrumentation, the failing
origin check saw the producer chain INCLUDING a register_assignment event
inside the producer-run attempt filter AND an already-appended campaign_begin
event with chain_valid=false on replay, while the existing campaign test's
identical filter shows no register event and its begin passes. First failed
attempt surfaced empty events at a stale commit. Lead: the begin mutation's
replay/authorize path sees a different chain shape in the new test's
sequencing — compare the register event's attempt linkage and the mutate
replay authorizer ordering before the begin call. All instrumentation has
been reverted; the tree is syntax-clean with the red test intact.

### Round 7 debugging addendum (review_context red test)

Fixed a real handler bug: ordinary_review_context_submission read the producer
assignment's events UNFILTERED (mixing the definition-producer register chain
into the origin check); it now selects the producer attempt from the selected
review's producer_origin before origins validation.

Narrowed the remaining campaign_begin failure decisively:
- register-event linkage is IDENTICAL in the existing (green) campaign test
  and the new test (attempt_id "definition-<name>"; excluded by the
  producer-run filter in both).
- campaign_status immediately before begin returns a HEALTHY campaign at the
  CURRENT journal commit (campaign_id, rounds, journal_commit), so the journal
  state including the campaign mutations is fully visible to read paths.
- Yet begin's authorize receives a producer-run-filtered chain of
  [intent, process_start, start_attempt, submit_candidate, assign_review] —
  WITHOUT campaign_start/campaign_pin. That list cannot be a valid historical
  prefix (assign_review follows the campaign mutations), so it is a FILTER
  exclusion, not a stale read: suspicion is now the attempt_id carried by the
  campaign_start/campaign_pin mutation events themselves (chained to a
  different attempt id than "producer-run") or the mutate-block event filter.
- Next session entry point: one debug line printing each campaign_start/
  campaign_pin event's attempt_id at write time and at begin's read.

Existing 10 tests / 121 assertions remain green; all instrumentation removed;
the new test remains the only red.

### review_context ingress COMPLETE (d0f05eb1a)

The focused test is green: ordinary_reviews 11 tests / 135 assertions PASS
(includes the full campaign flow through begin, a >64KiB prompt artifact under
the review_context purpose, exact-mutation replay, and fresh-second-submission
conflict). Neighboring regressions green: candidate_transfer 24/454,
command_execution 8/42. Fixes landed during the final push:
- ReceiptTransfer.decode parameterized (max_artifact_bytes/max_total_bytes);
  the review-context path passes the shared cap, ordinary results unchanged.
- ReceiptVerifier sees a review-nil projection of the campaign collection
  receipt (its self-approval semantics apply to producer review verdicts, not
  reviewer-produced collections); the canonical stored receipt keeps the
  campaign review reference with its own consistent digest, and
  validate_review_context_receipt! enforces the binding.
- EvidenceEvent registers the review_context_submitted type.
- Test receipt shape carries the verifier-required review fields plus the
  campaign reference; reviewer generations follow register+start (no queue op).

Remaining .8 joins: public retained driver, round ingestion proofs (consume
the stored review-context result into campaign rounds with byte reuse),
cancellation resolution, historical test-evidence wiring, comprehensive
public-path tests + actual Pi independent review, then the joined branch
re-verification and merge.

### Round ingestion join COMPLETE (2c02a67d0)

The campaign collection terminal now accepts the retained review-context
result: retained_review_context_result validates the review_context_submitted
event and its binding (including the campaign review reference); finish
completes from either result kind; with_review_collection! reads context
artifacts under the review-context canonical kind. Focused test extended
through the full join: queue_finish → submit_review_context (oversized prompt)
→ exact-mutation replay → fresh-second conflict → supervisor finish →
collection proof + canonical reader, asserting the EXACT prompt bytes are
reused from the canonical store (no re-upload). Receipt: ordinary_reviews
11 tests / 137 assertions PASS. Fixes en route: reviewer queue completion is
required before finish (scope subtree); the collection proof requires the
hyphenated review-execution check name.

Remaining .8 joins: public retained driver, cancellation resolution,
historical test-evidence wiring, comprehensive public-path tests + actual Pi
independent review, branch re-verification and merge.

### Public retained driver join COMPLETE

OrdinaryCampaignRunner (ace-lab organism) drives one canonical campaign review
round: retained campaign_begin mutation — a REPLAYED begin is an observation
that never dispatches; the execution boundary matches the begin's canonical
session_binding before the single-attempt model dispatch; a failed execution
submits nothing; the collected context returns through a retained
submit_review_context request whose receipt carries the campaign reference and
exact artifact digests. Contract receipts: 4 tests / 20 assertions PASS
(fresh-begin dispatch + submission; replay-never-dispatches; failure submits
nothing; boundary drift refuses). Fixes en route: lambdas cannot yield (block
parameter), receipt hash key consistency, and the boundary-drift test now
forces engine-side drift (an echoing fake can never mismatch its own begin).

Remaining .8 joins: cancellation resolution, historical test-evidence wiring,
CLI/workflow surface exposure of the runner, comprehensive public-path tests +
actual Pi independent review, branch re-verification and merge.

### Cancellation resolution join COMPLETE

A supervisor-revoked campaign review selection now settles its execution
reservation as a transient unavailable failure inside the prior-selection
branch of ordinary_campaign_review_selection!: cancellation is never a
successful execution (the succeeded path still requires the exact terminal
collection), and reselection proceeds under the campaign's EXISTING retry
budget (INFRASTRUCTURE_RETRIES governs; no fresh budget is invented). The
failure class was deliberately chosen: authorization is TERMINAL in the
campaign policy and would hard-block the round; unavailable is the transient
class that permits retry. Focused test: cancel → reassign succeeds with a new
execution_id under the same campaign; completed_rounds stays 0. Receipt:
ordinary_reviews 12 tests / 143 assertions PASS.

Remaining .8 joins: historical test-evidence wiring, CLI/workflow surface
exposure of the runner, comprehensive public-path tests + actual Pi
independent review, branch re-verification and merge.

### Branch regression sweep GREEN (round 12)

All composition-branch focused receipts re-verified together: ordinary_reviews
12/143, campaign runner 4/20, owner admission 10/45, prepared candidate review
16/57, candidate transfer 24/454, command execution 8/42 — zero failures.

### Historical evidence wiring — scoped design (next implementation)

The CampaignManager evidence dependency contracts (campaign_evidence.rb):
check_evidence.call(receipt, head:, name:, historical:) → executed-test proof;
review_evidence.call(receipt, head:, artifacts:, historical:) → review session
proof; approval_evidence.call(receipt, head:, artifacts:, ...) → approval
proof; manager-level head_assessment_evidence separately. Defaults today are
the composition's `unavailable` stubs. The wiring joins supply source-owned
callables in the Lab authority composition (mirroring the existing
release_authorizer late-binding pattern: closures over the lifecycle variable
assigned after construction): check_evidence closes over the command evidence
owner (canonical executed tests incl. the historical candidate_reference
view), review/approval/head_assessment close over the lifecycle's canonical
review readers (with_review_collection!/review_at_reference! and the accepted
review records), each validating the provided receipt bytes against the
canonical journal at the bound head — material/uncertain changes require the
real independent delta review, and the original reviewed head stays separate
from the accepted head.

### Historical check-evidence wiring (first half) COMPLETE

CommandExecution gains canonical_check_reference!(execution_id:, head:) — the
canonical backstop for campaign check proofs: the referenced execution must
exist in the ordinary journal as a purpose-test command that exited zero with
the recorded source head (historical references validate against real records
without requiring the current candidate binding). The Lab authority
composition wires the campaign owner's check_evidence dependency: the
campaign-repo receipt read (CampaignExecutionEvidence#check, unchanged
semantics incl. historical mode) now ALSO backstops canonically through the
installed command owner. Review/approval/head-assessment readers stay
fail-closed until their canonical joins land. Receipts: command_execution
9 tests / 49 assertions PASS (passing proof + wrong-head/unknown-id/exit-1/
non-test refusals); owner admission 10/45 PASS.

Remaining .8 joins: review/approval/head-assessment canonical readers,
CLI/workflow surface exposure of the runner, comprehensive public-path tests +
actual Pi independent review, branch re-verification and merge.

### Review-session canonical wiring COMPLETE

OrdinaryReviewCollection gains canonical_review_reference!(attempt_id:,
head:, digest:): the referenced reviewer attempt (located by scanning the
journal's assignments for the attempt chain) must hold exactly one retained
review-collect result — ordinary OR review-context — whose receipt digest and
reviewed head match the campaign reference. The composition's review_evidence
dependency is wired late-bound over the lifecycle (same closure pattern as
release_authorizer/coordinator): campaign-repo session read plus the canonical
backstop. Receipts: ordinary_reviews 13 tests / 148 assertions PASS (proof +
wrong-head/wrong-digest/unknown-attempt refusals); owner admission 10/45.

Remaining .8 joins: approval/head-assessment canonical readers (approval
scans for the accepted-review mutation bound to head/actors/digest),
CLI/workflow surface exposure, comprehensive public-path tests + actual Pi
independent review, branch re-verification and merge.

### Approval canonical wiring COMPLETE

OrdinaryReviewEvidence gains canonical_approval_reference!(head:,
reviewer_actor:, digest:): an accepted independent review must exist in this
journal bound to the reviewed head and reviewer actor with the referenced
receipt digest, and must not have been revoked (a post-acceptance cancel
refuses). The composition's approval_evidence dependency is wired late-bound
like the others: campaign-repo approval read plus the canonical backstop.
Receipts: ordinary_reviews 14 tests / 155 assertions PASS (proof +
wrong-head/wrong-actor/wrong-digest/revoked refusals); owner admission 10/45.

Evidence wiring status: check ✅, review-session ✅, approval ✅. The
manager-level head_assessment_evidence remains fail-closed by default (its
canonical source is the accepted-head assessment records; wiring follows with
the assessment-join work). Remaining .8: head-assessment wiring,
CLI/workflow exposure, comprehensive public-path tests + actual Pi review,
branch re-verification and merge.

### Negative-path suite extended

New adversarial proofs for the review_context ingress: a receipt claiming a
SUBSTITUTED campaign round reference refuses (the canonical campaign binding
rejects metadata substitution); CORRUPTED artifact bytes that differ from the
declared digest refuse at transfer decode; and the honest submission succeeds
immediately after both refusals (the refusals leave no poisoned state).
Fixture note: the reviewer's queue completion must precede the submissions
(generation ordering), and the transport refusal codes carry no server detail
by design — the assertion pins the refusal class plus the follow-on success.
Receipt: ordinary_reviews 15 tests / 161 assertions PASS.

Comprehensive public-path coverage now includes: oversized-prompt ingress,
exact-mutation replay, fresh-second conflict, pre-begin refusal, cancellation
+ reselection, revocation (selection and approval), boundary drift, replayed
begin, failure-submits-nothing, wrong-head/actor/digest/attempt refusals,
metadata substitution, artifact corruption, canonical byte reuse at
ingestion, and finish-through-collection. Remaining .8: head-assessment
wiring, workflow-surface exposure, actual Pi independent review, branch
re-verification and merge.

### Head-assessment wiring — correctly sequenced with the Pi review phase

Reading campaign_head_assessments#head_assessment_proof! settles the design:
the head_assessment_evidence callable is an ASSESSMENT EXECUTOR — it produces
the strict-schema proof (authority/rationale/complete-context digest) by
actually executing the delta assessment, with material/uncertain changes
requiring an executed delta round. That is runtime reviewer behavior, not
composition wiring: it is sequenced together with the actual configured Pi
independent review (which itself supplies the executed assessments), rather
than as a standalone composition join. Check/review/approval canonical
backstops (composition-side) are complete; the assessment executor lands with
the Pi review.
