---
id: 8x1280
title: qk1.1-assignment-drive-delivery
type: standard
tags: [assignment, worktree, recovery]
created_at: "2026-10-02 01:28:55"
status: active
---

# qk1.1-assignment-drive-delivery

Delivery retro for assignment 8x0z4k (work-on-task 8wr.t.qk1.1, forge-neutral review lifecycle), driven through the full ace-assign cycle: hidden-spec render → `ace-assign create` → drive loop with fork delegation. Companion to the worker-perspective retro 8x1192 (recovery lessons inside the subtree).

## What Went Well

- **Separate-workspace discipline held end-to-end.** All implementation, tests, release prep, task metadata, and retros live on the worktree branch `.ace-wt/8wr-t-qk1-1-review-lifecycle`; the shared checkout stayed untouched apart from assignment bookkeeping. Overlay instructions in the rendered job YAML were enough to transmit the contract to forked workers.
- **Deterministic prepare via the shipped atom.** Rendering the hidden spec with `Ace::Assign::Atoms::PresetExpander.expand` (instead of hand-writing YAML) kept the queue faithful to the shipped preset and made the worktree overlay a small, reviewable delta.
- **Recovery chain converged.** Stalled worker 1 (livelock on its own fork-run wrapper) and timed-out worker 2 (1800s cap mid-implementation) were both recovered without losing work: partial progress was already committed per-scope, so round 2 resumed from commits and finished implementation + pre-commit-review + verify-test + release-minor + create-retro within one 3600s window.
- **Receipt mechanics solved for worktree delivery.** `CACHE_BASE=<shared store>` + cwd inside the worktree binds `live_head` to the worktree HEAD while writing into the shared assignment store — matching how fork workers' receipts were accepted. All eight attempts accepted first try once this pattern was fixed.
- **Suite triage was decisive.** The 7 remaining monorepo failures were proven pre-existing (identical on main) or fixed-upstream (llm-providers-cli passes on current main) within one comparison run; nothing was papered over.

## What Could Be Improved

- **First fork worker livelocked on its own launcher.** The worker saw `ruby bin/ace-assign fork-run …` in `ps`, concluded another agent owned the scope, and sleep-polled for ~25 minutes. Nothing in the subtree instructions warned about this; the anti-stall directive only entered via recovery-onboard.
- **Default fork timeout (1800s) is too small for a "large" implementation slice.** Worker 2 was killed mid-implementation with 26 dirty files; only the earlier per-scope commit habit saved the work. The re-fork needed `--timeout 3600` to finish.
- **`ace-assign add --child` cannot inject recovery children below depth 2**, so the canonical recovery-onboard/continue-work child pattern is impossible under a depth-3 leaf (010.01.04); the fallback (children of the subtree root + manual file renames to fix insertion order) worked but is fiddly and undocumented.
- **`ace-assign retry` places the retry step at top level**, outside the fork subtree — the wrong recovery shape for fork work (it had to be removed by hand).
- **The suite runner's default per-package timeout (120s) is under half of ace-review's real runtime (~200s)**, so a standard `ace-test-suite --target all` reports false timeout failures for ace-review and ace-assign; only a `--timeout 900` rerun shows the true (green) state.
- **Hidden-spec schema drift:** the create workflow doc sketches `session:` as the top-level key, but the runtime ingests `assignment:` + `steps:`. First `create` call failed on the documented shape.

## Action Items

- **Stop** treating a visible fork-run wrapper process as evidence of a competing worker; **continue** shipping per-scope commits during implementation (they carried this delivery); **start** adding an explicit "your launcher is not a competitor — execute inline" line to fork subtree instructions (done for this assignment via recovery-onboard; worth promoting into wfi://task/work or the fork launcher prompt).
- **Start**: raise the default fork `execution.timeout` for large-slice assignments (or scale it from the task's advisory size), so mid-implementation TERMs stop happening.
- **Start**: document (or automate) the depth-2 recovery injection pattern: add recovery children to the subtree root, then renumber sibling step files to restore ordering; and record that `retry` is top-level-only.
- **Start**: default `ace-test-suite` per-package timeout to ≥900s (or auto-scale from the slowest package's last runtime) so full-suite runs stop flagging ace-review/ace-assign as timeouts.
- **Start**: align the create workflow doc's hidden-spec sketch (`session:`) with the runtime contract (`assignment:` + `steps:`).
- **Consider**: make `ProjectRootFinder` honor `PROJECT_ROOT_PATH` from nested worktrees (currently ignored for cache_dir resolution from .ace-wt children), which would remove the need for the `CACHE_BASE` workaround in receipt submission.

## Addendum: Review-Campaign Endgame (2026-10-02 evening, rounds 51–60)

- **The full-diff-per-round treadmill is structural, not diligence.** Each campaign round re-reviewed the entire growing diff (~100 commits) with a fresh reviewer session, so every round manufactured at least one new confirmed High — 44 recorded rounds before this addendum, only 3 ever clean, against a binding 3-round budget. The loop broke only when dispositions got discipline: confirmed Highs fixed same-cycle, Mediums accepted with documented reasons, and rounds capped. It still took r51–r60 (10 more rounds, 9 code fixes) to reach two consecutive clean rounds; three findings re-appeared across rounds in mutated form (the abbreviated-SHA finding was "fixed" by rejection in r52 and had to be re-fixed by prefix binding in r56 after a reviewer correctly challenged the remedy's premise).
- **Accepted dispositions do not settle a fresh-eyes reviewer.** r52 accepted the commit_id fallback as medium; r57 re-raised it as high and would have kept re-raising every round. When a finding recurs across sessions, fix it — acceptance only works for findings a fresh session is unlikely to re-derive.
- **`campaign finish` is blocked by a genuine design defect (follow-up needed).** Record-round requires resolved findings (feedback file `status: done`), and resolve archives + annotates those files — but finish's freshness gate re-verifies every historical receipt artifact by exact path+digest, so any campaign that resolves findings mid-campaign can never finish. The snapshots store (`campaigns/evidence/<sha>.s.md`) allowed restoring 14 of 20 stale references; the rest are unrecoverable. Fix direction: verify against content-addressed snapshots, or make resolve non-destructive to receipt-referenced paths.
- **Local-subject campaigns cannot run delta rounds.** `--delta` requires PR-subject campaigns (subject.pr set); with a local diff subject the pin must be the full base..head selector, so every round is a full review. PR-subject campaigns should be preferred when a forge PR exists.
- **Mechanics worth remembering:** pins are immutable (a head change orphans the round id); `feedback verify` mutates the finding file, so collect receipts must be re-submitted under a fresh attempt after verifying before record-round; the campaign finish/evidence path resolves the assign store from the inherited `CACHE_BASE`, so export it for every campaign command; `ace-assign start/finish` act on the *selected* assignment — `select` explicitly before step work when the store holds more than one.
