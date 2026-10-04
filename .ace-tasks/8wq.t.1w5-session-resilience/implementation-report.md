# Recovery implementation report

Base: ce7e39228. Branch: codex/wave4-recovery. Own worktree: .ace-wt/codex-wave4-recovery. Task remains in-progress; independent current-head review and installed Lab acceptance are required.

Skills applied: as-task-work, as-git-worktree-create, as-task-plan, as-test-plan, as-test-verify-suite and as-git-commit. Loaded their workflows and task/project bundles. The source ace-task plan invocation produced no output for more than three minutes; interrupted it under task/work's plan-retrieval guard. Current specification, inspected owner APIs and the following explicit plan replace that unavailable artifact.

- Step 01 (spec expected behavior/interface): establish verified process identity at the runtime owner layer; pin PID/UID/OS birth/host, native shell/pane/session and Herdr agent-session/terminal. Verify runtime molecule, shared adapter and wrapper tests.
- Step 02 (resume/SC1): add read-only recovery snapshot and public resume. Load accepted journal history, checkpoint, attempts, pending HITL references and external/inbox facts. Adopt only verified current owners; preserve unknown writers and resources. Verify organism/public CLI cases with real journal.
- Step 03 (signed consumer contract): reuse Herdr's signed verifier, event/generation/key/target checks and existing attempt journal. Support exact proof re-verification after consumer crash; expose bind_inbox and reconcile_inbox library consumer operations. Verify signed consumer matrix with actual RSA signatures.
- Step 04 (overseer interface): expose recovery reasons/liveness/last verified observation and preserve unreadable state as unknown. Verify overseer JSON projections/dashboard.
- Step 05 (SC3): execute affected full deterministic suites and default fast monorepo verification; scoped commit, then independent review. Preserve installed acceptance as an unmet external gate.

Authorization remains the existing actor/service boundary. OS process observation grants no service/HITL/effect privilege. No receipt bytes, command-line arguments, OTPs or private keys are journaled. Signed inbox outcomes are transport facts and never settle business effects or succeed an assignment. Unresolved old events retain their pinned verifier context; rotation may be postponed.

Installed limitations: this host's deterministic native replies cannot attest actual queue consumption or process-tree closure. Live Herdr/Pi compaction/reload and close/stop with a writing child, preserving worktree files/unmerged commits, must pass separately before Lab cutover. gad.8/.b owns protected signing and actual native observer operations. No signed proof is fabricated from disappearance, age, shell survival or elapsed authorization.

Verification results and final commit are recorded below after execution.

Executed verification:
- Runtime full: 160 tests / 434 assertions, no failures/errors (8x3yu3), including exact OS birth, same-second reuse, ancestry revalidation and real orphan writer.
- Tmux full: 343 / 909, no failures/errors (8x3yi3).
- Herdr full: 454 / 1464, no failures/errors (8x3ymt).
- Overseer full: 255 / 1015, no failures/errors (8x3yio).
- Assign full: 799 / 3071, no failures/errors, 2 intentional skips (8x3yqv), before final attribution hardening; final focused recovery verification recorded below.
- Default fast monorepo suite with bounded 600-second package timeout: 51 packages, 11044 tests / 33368 assertions, no failures/errors, 24 skips. Initial parallel default 120-second run exhausted assign timeout and exposed an existing Herdr process-test fixed-sleep startup race; actual child PID-file readiness replaced that sleep and the complete rerun passed.

Pre-review corrections: exact platform birth replaces whole-second process timestamps; capture brackets metadata with birth observations and validates ancestor identities/parents again. Inbox snapshots are journal-registration-driven for both live and archive records; changed attempt, key, payload or generation remains unknown. Signed reconciliation must match prior journal registration before the verifier can settle the transport. No native privileges or signed observations are inferred.

Final focused verification: 74 tests / 363 assertions passed (8x3ypn); precise-birth/attribution run covered 75 / 368 with only a new test fixture using the wrong projection field, corrected from inboxes to inbox_events. Final signed recovery suite: 10 tests / 126 assertions passed (8x3yw7), including substituted live/archive attempt/key/payload/generation. The signed consumer registration guard was included in this final run. git diff --check passed.

Scoped commits: 40eb746d3 (runtime/tmux ownership), 394508556 (Herdr verifier/factory/native ownership), c14a0cc6c (precise birth and ancestry revalidation), 624ed89fd (overseer recovery projection), followed by the assignment recovery implementation commit containing this report. Candidate is ready for independent review; no main merge, task completion, gem preparation or publication performed in this worktree.
