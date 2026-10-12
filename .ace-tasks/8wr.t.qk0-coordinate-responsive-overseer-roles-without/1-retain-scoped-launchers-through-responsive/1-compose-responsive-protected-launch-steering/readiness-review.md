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
