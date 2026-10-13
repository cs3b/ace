# Structural transfer readiness — 2026-10-07

Independent reviewer review_lab_bootstrap APPROVE: transfer the unchanged reviewed responsive launch, steering, roles and proposal behavior from qk0.1 to real child qk0.1.1. Preserve SC1–SC3, input/retry/usage contracts and source ownership. This child depends on qk0.1.0 and existing qk0.1 prerequisites, never on its parent; there is no dependency cycle. Parent now owns only the two-child outcome map. Original whole behavioral review is retained in the parent readiness-review.md. No new behavior or implementation acceptance is implied.

The transfer prevents ace-task’s automatic terminal-child completion from declaring the still-unimplemented responsive composition done when independent review qk0.1.0 closes. Installed acceptance remains gad.2. qk0.3’s actual artifact producer and Lab source publication are still prerequisites.

Exact transfer review additionally required correcting nested bundle.files, the child usage relative link and adding a frontmatter title; all three mechanical corrections are applied before promotion. No behavioral change.

## Draft follow-up for preserved PR44 ownership amendment — needs review

This follow-up does not edit or restate the four PR44-owned qk0 amendment files.
Review the preserved amendment at branch record `h8x-final-records`, commit
`6a5c8d88448859920f6d612475e84807d7434f2c`, then apply the following acceptance
deltas to qk0.1.1 before readiness promotion. The preserved role/worktree/recovery
clauses remain the normative candidate; this note neither adopts them into main nor
claims installed charter behavior.

### Ownership and queue isolation

- Run two project delivery queues concurrently under two project overseers. Each
  owner selects its own dependency-aware integration order, worktrees, reviews,
  records and cleanup. The Lab coordinator changes cross-project priority,
  pause/resume and capacity without issuing either project's PR integration or
  taking ownership of its queue.
- Preserve runtime authority in native Assign/service state. Before cleanup,
  sanitize and version only durable specifications, decisions and result/evidence
  references needed by a fresh checkout. A fresh checkout/session reconstructs the
  reviewed plan, ownership, exact candidate and unresolved references without
  treating Git records as live authority or copying private `.ace-local` journals,
  credentials or secrets.

### Exact integration context and recovery matrix

Every case records observed repository/worktree/branch, task/attempt, PR/provenance,
candidate and target ancestry, actual owner, durable operation reference, next
permitted action and exit criterion:

| Observation | Required decision |
| --- | --- |
| Live owned writer | Preserve it and route the next action to that owner; no competing writer or cleanup. |
| Dirty/untracked or diverged canonical checkout | Preserve commits/WIP, attribute recovery and reconcile through review/integration; never reset or wait generically. |
| Confirmed remote merge with stale local main | Synchronize the owned canonical checkout after fresh remote observation; never remerge. |
| Lost acknowledgment/result | Query the same durable request reference read-only; never resubmit an uncertain effect. |

Integration preflight joins the selected checkout/worktree/branch, project,
task/attempt, normalized PR URL, head/base repositories and refs, candidate head,
review/test evidence and fresh target ancestry. Acceptance refuses a wrong
repository despite the same SHA, wrong worktree/branch, moved remote target and
stale evidence; an empty managed-PR metadata field or task label never overrides
actual forge/repository provenance.

### Goal/watch adoption

Reuse qjy's named live-session timer/watch and wake-only mechanisms. Bind each
subscription to the active project goal/plan and original attempt; after reload,
adopt it exactly once and wake the same project owner. Pause, close or supersede
disables obsolete dispatch while retaining observations and uncertain operations.
Both idle and busy callbacks coalesce and advance one eligible recorded action
without another Captain nudge. No external timer/service, second goal store or
replacement attempt is introduced.

This delta also consumes qkb.1's ordinary integrator acknowledgment/status
contract: only its durable accepted reference permits `WAIT`; missing producer or
receiver is attributable `BLOCKED`, and terminal integration is accepted only from
the exact bound receipt. Implementation and installed acceptance remain open.

### Integration-coordination contract + sibling-PR acceptance (Captain, 2026-10-12)

Codified generically in the project-overseer role charter and the ace-assign
delivery instructions; this acceptance extends (never replaces) the follow-up
above. Contract clauses: every integration invocation resolves fresh
repository, PR, candidate exact head, target base/head, review/test evidence,
dependencies and authorized executor before any mutation, and rechecks
target/head immediately before mutation — a race invalidates eligibility; a
target that is NOT an ancestor of the candidate head yields an actionable
typed `needs-rebase` outcome — never a merge, never a silent rewrite; the
overseer delegates as-git-rebase (`wfi://git/rebase`, including CHANGELOG
preservation) in the candidate's isolated worktree and obtains refreshed
exact-head checks plus independent review of the NEW head before resubmission;
the low-level privileged integrator only enforces gates and returns typed
outcomes (merged / needs-rebase / blocked / uncertain) and never authors,
rebases or reviews its own candidate; relay alone is not execution — the queue
owner monitors until receipt and continuation; queue states ready /
needs-rebase / reviewing / integrating / merged / blocked / uncertain
reconcile against actual forge/process receipts using existing goal/wake/watch
primitives (no new heartbeat service), a persisted queue adopts on restart
without duplicate execution, and worker PR-ready stays distinct from delivery
done; never push directly to main, never switch the canonical checkout to a
topic branch, never reuse a stale review as approval for a different or moved
head.

Acceptance scenario — two reviewed sibling PRs (serial preparation + serial
integration):

1. Two sibling PRs, each independently reviewed off a common base; the queue
   selects the first by dependency-aware integration order. Any further
   queued PRs (PR3..N) keep their existing branches and heads untouched.
2. The privileged integrator merges the first sibling via ONE scoped
   integration request; the merge receipt and verified remote outcome record
   that main moved. That receipt causes preparation of ONLY the second
   sibling — never a mass rebase of the remaining queue.
3. Preparing the second sibling: the fresh target check shows current main
   is NOT an ancestor of its candidate head → typed `needs-rebase` returned
   to the queue owner; no merge, no silent rewrite (a common old base does
   NOT make the siblings sequentially fast-forwardable).
4. The overseer delegates as-git-rebase in the second candidate's isolated
   worktree; the applicable checks re-run and an INDEPENDENT EXPLICIT review
   binds to the NEW exact head — patch identity may support a short delta
   review but never substitutes the explicit independent head approval (the
   old approval is void); PR updated, remote candidate head/base verified,
   ONE scoped integrator request resubmitted.
5. The queue waits/reconciles the actual integration receipt, refreshes
   main, then selects and prepares ONLY the next candidate. Changed-target
   recheck immediately before the mutation: a race detected there voids
   eligibility and re-enters `needs-rebase`. No rollback/reset of the first
   sibling's merged batch work.
6. Uncertain-receipt reconciliation: a lost or ambiguous integration receipt
   for either sibling reconciles by the original durable request reference —
   at most one effect per request, never blind retry.
