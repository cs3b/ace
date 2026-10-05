---
doc-type: workflow
title: Perform attempt-bound delivery
purpose: Coordinate implementation, exact-head review and authorized delivery on the selected forge
---

# Perform attempt-bound delivery

## Goal

Deliver one committed candidate in explicit standalone or managed mode, using
the selected forge and current executed tests and independent review.

## Prerequisites

- A reviewed task or an explicit implementation scope and project.
- For managed delivery, a managed assignment and an active scoped attempt for each
  delivery action; use the actual assignment and
  attempt IDs from the execution boundary, never caller-invented actor identity.
- For remote delivery, a pushed candidate and explicit fork/canonical provenance:
  mode, head_repository_url, head_ref, base_repository_url and base_ref.
- An applicable authorization for each effect. Transport credentials do not grant
  permission to merge, publish, deploy or synchronize.

Choose standalone mode for ordinary local task/inline implementation, tests, review
and optional requested version/changelog preparation without a managed assignment.
Choose managed mode when the request supplies an assignment or requires its
canonical attempt/receipt boundary. Standalone output cannot satisfy managed or
protected acceptance. Local-only implementation needs no forge selection or
scoped attempt. If remote delivery is requested,
use forge_server or forge_default: true, mutually exclusive; otherwise use the
repository remote. Preserve the first resolved server/repository/PR identity
throughout the assignment. Missing service or authorization yields a specific
blocker; this workflow does not invent grants or impersonate an integrator.

## Project context loading

Read the task or inline scope and actual committed diff. In managed mode also
read assignment status, current attempt and retained delivery parameters. If a PR
is recorded, inspect it with
`ace-git pr show IDENTIFIER --format json --server NAME` using the retained selection
(or `--default-server`, otherwise remote resolution). Inside ACE use source
`bin/ace-*` commands. Load the relevant implementation and test instructions.

## Standalone delivery

Implement and commit the requested local task/inline scope using existing task
and Git tools. Execute appropriate tests and independent review, retain their
actual artifact references and candidate SHA, and record unfinished criteria.
No managed assignment, protected service receipt or canonical qjl acceptance is
claimed by this route. Local scope may end here.

For an explicitly authorized standalone remote scope, use existing neutral
primitives on the chosen base repository/forge. Record actual head/base
repository URLs and refs; canonical provenance means matching repositories,
while fork provenance requires its explicit source URL. A pushed source ref must
match the candidate SHA. Draft creation defaults to true:

`ace-git pr create --server NAME --head HEAD-REF --head-repo HEAD-REPOSITORY-URL --base BASE-REF --expected-head CANDIDATE-SHA --title TITLE --body-file DESCRIPTION --format json`

Read the returned exact PR identity. Update with
`ace-git pr update IDENTIFIER --server NAME --expected-head CANDIDATE-SHA --body-file DESCRIPTION --format json`.
Use the retained default/remote selection instead of `--server NAME` when
applicable. Review through the existing neutral review workflow with the same
selection. Before readiness or merge, require passed executed tests and accepted
independent review for that exact candidate and the actual operation authorization;
the low-level PR command does not establish these gates itself. Readiness uses
`ace-git pr ready IDENTIFIER --server NAME --expected-head CANDIDATE-SHA --format json`.
Only an actually authorized standalone integrator may call
`ace-git pr merge IDENTIFIER --server NAME --expected-head CANDIDATE-SHA --method METHOD --format json`.
This is not a worker fallback when a managed/protected service is unavailable.
Remote errors or uncertain effects remain explicit unresolved outcomes; use
authoritative reads and existing provider reconciliation, never blind replay.

Perform any requested local version/changelog changes before final test/review
and merge evidence is accepted. Preparation after a completed delivery is a
separate follow-up candidate/scope and must obtain its own required evidence.
Publication remains separately authorized and gated, including OTP when required.

## Managed delivery steps

1. Record the requested delivery steps and their owners before implementation.
   Follow the existing task-work plan. Commit the implementation and run appropriate
   package tests. If requested, perform local version/changelog preparation with
   `ace-bundle wfi://release/local` before final evidence and merge; it does not
   publish. Keep unfinished task criteria open; a bounded source checkpoint
   cannot mark an entire installed task done.
2. For remote delivery, prepare a concrete title and description from the changes
   and executed validation. Load `ace-bundle wfi://git/pr/create` and use the actual
   managed assignment and active delivery attempt. The executable operation is
   `ace-assign delivery --assignment ID --attempt ATTEMPT --operation create --title TITLE --body-file DESCRIPTION`.
   Provide `--parameters FILE` if required for the assignment's explicit delivery
   mapping. Creation defaults to a draft. Record its returned server, repositories,
   refs, PR number/URL and exact candidate_head.
3. Execute the independent review workflow `ace-bundle wfi://review/pr` against that
   exact PR and retained forge selection. Preserve its actual round completion rule,
   findings and reviewer identities. Fix confirmed blocking findings and rerun
   affected tests. Every new committed candidate, including task-only edits,
   invalidates prior ready/merge evidence. Historical approval remains history.
4. Obtain coordinator-accepted current-head test and independent review receipts
   through the existing assignment boundary. File existence, fabricated approval,
   exit zero or a worker claim cannot replace acceptance. Distinguish base_head,
   candidate_head, evidence_git_ref and journal_commit; evidence commits do not
   advance the deliverable branch. CI status is visible and advisory; failed
   executed tests, stale evidence or unresolved review findings still block.
5. Prepare the final PR body with the concrete behavior, executed checks,
   independent verdict and remaining limitations. Load
   `ace-bundle wfi://git/pr/update` and execute
   `ace-assign delivery --assignment ID --attempt ATTEMPT --operation update --body-file DESCRIPTION`.
   Mark ready only with accepted exact-head reference files:
   `ace-assign delivery --assignment ID --attempt ATTEMPT --operation ready --tests TEST-REF --review REVIEW-REF`.
   Each reference file contains only attempt_id and receipt_digest.
6. Hand off merge only to the existing authorized integrator/service for the exact
   PR, candidate and operation. Its executor uses the neutral provider merge with
   both required values:
   `ace-git pr merge IDENTIFIER --server NAME --expected-head CANDIDATE-SHA --method METHOD --format json`.
   METHOD is the authorized squash, merge or rebase choice, never an implicit
   default. The assignment worker consumes a completed verified service receipt:
   `ace-assign delivery --assignment ID --attempt ATTEMPT --operation merge --tests TEST-REF --review REVIEW-REF --service-request REQUEST`.
   This command does not dispatch or execute its own pending merge. If no actual
   configured executor or valid receipt is available, retain the routed blocker.
7. Local version/changelog preparation is optional requested work from step1.
   It must be included before final exact-head evidence and merge. Preparation
   requested after a completed merge starts a separate follow-up candidate/scope;
   the old merge does not accept its amended content.
   Publication, deployment and synchronization are distinct operations with their
   own valid authorization, executed technical evidence and any required OTP.
   Authorized merge does not authorize them. Do not add an unnecessary proposal
   for an already authorized operation or fabricate an unavailable proposal API.
8. Record the exact delivered scope, candidate, receipt references, review verdict
   and remaining gates. A requested delivery-only scope can finish after its
   authorized merge; publication is not mandatory. Keep the task in progress until
   all of its actual acceptance criteria are satisfied.

## Uncertainty and resume

In managed mode, read assignment status and retained qjl delivery events before
resuming. Repeat read/check operations safely. On interrupted create, update or readiness, use the
same delivery command for exact-selector reconciliation. One matching draft may
be adopted; zero remains unresolved and multiple matches conflict. A different
requested effect cannot be reported complete merely because an earlier effect
was recovered.

Unknown merge/publication remains unknown pending its existing owner's
reconciliation. Never blindly replay an effect, substitute a generic PR result
for a service receipt or translate a blocker into direct gh/fj commands.

## Success criteria

- The requested scope has real artifact, current test and independent review
  evidence for its exact candidate.
- Remote identity and explicit provenance remain fixed with honest unresolved
  outcomes preserved; managed mode records them in the existing attempt journal.
- Readiness and authorized integration consume current evidence; managed merge
  additionally consumes exact service receipts. Standalone output cannot satisfy
  managed/protected acceptance. CI alone neither grants nor vetoes acceptance.
- Optional publication remains separately authorized and unfinished installed
  criteria remain visible.
