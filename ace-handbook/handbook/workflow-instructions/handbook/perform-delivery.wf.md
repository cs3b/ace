---
doc-type: workflow
title: Perform attempt-bound delivery
purpose: Coordinate implementation, exact-head review and authorized delivery on the selected forge
---

# Perform attempt-bound delivery

## Goal

Deliver one committed candidate, using the selected forge and current executed
tests and independent review.

## Prerequisites

- A reviewed task or an explicit implementation scope and project.
- For remote delivery, a pushed candidate and explicit fork/canonical provenance:
  mode, head_repository_url, head_ref, base_repository_url and base_ref.
- An applicable authorization for each effect. Transport credentials do not grant
  permission to merge, publish, deploy or synchronize.

Choose standalone mode for ordinary local task/inline implementation, tests, review
and optional requested version/changelog preparation. Local-only implementation
needs no forge selection or scoped attempt. If remote delivery is requested,
use forge_server or forge_default: true, mutually exclusive; otherwise use the
repository remote. Preserve the first resolved server/repository/PR identity
throughout the work. Managed attempt-bound delivery and its role handoff land in
L5.5; this workflow does not invent grants or impersonate an integrator.

## Project context loading

Read the task or inline scope and actual committed diff. When the work belongs to
an assignment, also read assignment status and the current attempt. If a PR
is recorded, inspect it with
`ace-git pr show IDENTIFIER --format json --server NAME` using the retained selection
(or `--default-server`, otherwise remote resolution). Inside ACE use source
`bin/ace-*` commands. Load the relevant implementation and test instructions.

## Coordinating parallel delivery

The coordinating agent owns the review and integration queue as well as dispatch.
Before opening another scope, review completed candidates and integrate those
whose executed checks and independent verdict permit it. If a candidate cannot
integrate, record its exact blocker and owner in the existing task checklist;
continue independent work only when it advances the same delivery objective.
Do not become a review bottleneck by repeatedly starting unrelated work while
finished candidates wait for your decision.

After integration, verify the actual main and requested remote refs and update
the current checklist. Distinguish committed in a worktree, accepted by review,
integrated locally, pushed and released. A partial merge is useful incremental
work, not task completion. Keep the remaining producer/consumer join explicit
and test it on the combined candidate before declaring that result delivered.

## Standalone delivery

Implement and commit the requested local task/inline scope using existing task
and Git tools. Execute appropriate tests and independent review, retain their
actual artifact references and candidate SHA, and record unfinished criteria.
No managed assignment or canonical receipt boundary is claimed by this route.
Local scope may end here.

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
Remote errors or uncertain effects remain explicit unresolved outcomes; use
authoritative reads and existing provider reconciliation, never blind replay.

Perform any requested local version/changelog changes before final test/review
and merge evidence is accepted. Preparation after a completed delivery is a
separate follow-up candidate/scope and must obtain its own required evidence.
Publication remains separately authorized and gated, including OTP when required.

## Managed delivery (planned L5.5)

Attempt-bound managed delivery — assignment-scoped attempts, exact-head evidence
and the reviewer/integrator role handoff — lands with the role workflow in L5.5.
Until then, standalone delivery above is the active path. Attempt evidence remains
local to the assignment: use `ace-assign attempt start`/`attempt finish` for the
exact execution scope and record actual artifacts, executed checks and the
independent reviewer verdict for the same head. Never substitute a written report
or exit code for accepted evidence.

## Unavailable publication prerequisite

Requested publication is a separate step, never a consequence of merge success.
Use the existing configured publisher prerequisites; an absent publisher or
unavailable required OTP is a routed blocker, not permission to run an alternate
command or account.

If the requested step cannot proceed, record its value-free cause through the
existing assignment failure owner:
`ace-assign fail --assignment ID@SCOPE --message "publication blocked: prerequisite unavailable"`.
Use the actual assignment selectors; standalone work omits them and uses its
existing target. Read `ace-assign status` for that same scope afterward. The step
remains failed/unfinished, with no publication receipt or task completion. Preserve
an uncertain effect separately: a failure report must not claim a definitive denial
or effect absence from a lost reply.

## Uncertainty and resume

When the work belongs to an assignment, read assignment status and retained attempt
events before resuming. Repeat read/check operations safely. On an interrupted
create, update or readiness, use the same forge command for exact-selector
reconciliation. One matching draft may be adopted; zero remains unresolved and
multiple matches conflict. A different requested effect cannot be reported complete
merely because an earlier effect was recovered.

Unknown merge/publication remains unknown pending its existing owner's
reconciliation. Never blindly replay an effect or translate a blocker into
unverified direct provider commands.

## Success criteria

- The requested scope has real artifact, current test and independent review
  evidence for its exact candidate.
- Remote identity and explicit provenance remain fixed with honest unresolved
  outcomes preserved; assignment-backed work records them in its local attempt
  evidence.
- Readiness and authorized integration consume current evidence. CI alone neither
  grants nor vetoes acceptance.
- Optional publication remains separately authorized and unfinished criteria
  remain visible.
