# ei9.8 campaign join state — 2026-10-17

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

## Current state: RED baseline (expected join work)

`bin/ace-test assign feat` fails fast with 19 failures
(report `.ace-local/test/reports/assign/03190763-c68f-4f28-8cb6-a903992ec100`).
First diagnosed root cause: `LaunchLifecycle#close` (launch_lifecycle.rb:361)
calls `.close` on every registered scope; the two lines register different
scope objects and `ExecutionScopeObservation` does not implement `close`
(NoMethodError). The two lines were developed in parallel worktrees and were
never exercised together — the handoff's predicted "complete review execution
authority join" work, not a pick error.

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
