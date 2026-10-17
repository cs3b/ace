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
