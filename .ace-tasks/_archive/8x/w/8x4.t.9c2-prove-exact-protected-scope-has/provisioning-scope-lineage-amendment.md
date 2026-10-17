# Pre-child scope lineage — normative amendment candidate

This amendment supersedes the full-binding-before-layout ordering in
scope-owner-proposal.md and specification-readiness-candidate.md. It is a
specification candidate for independent review, not implemented or installed proof.
No child identity can be asserted before genuine 09j creation provenance exists.

## Fixed unit graph and ordered provisioning

The parent slice has no direct or transitive dependency that starts its service.
The service's fixed `Slice=` creates normal Requires/After toward the parent,
not reverse activation. Under existing slot exclusion the authority issues
StartUnit(parent), authenticates/pins its live cgroup and InvocationID, commits
parent scope_bound, revalidates seal/lineage, then issues StartUnit(service).
There is no paused child, delay/retry workaround or pre-start guessed binding.
StopWhenUnneeded=no retains the active parent after service stop. Service unit
metadata need not be retained by a parent Wants edge: current live observations
and canonical native lineage verify it; an inactive unit disappearing cannot
supply proof or launch provenance.

Manifest validation inspects effective installed units, drop-ins, alias/template
instances and wants/requires/upholds symlinks plus manager dependency/trigger
properties. Refuse reverse activation via any reachable parent start dependency,
boot/target enablement of the service, socket/path/timer, restart/Upholds,
OnSuccess/OnFailure or other external activation route. Only authorized owner's
fixed StartUnit(service) after committed parent lineage may start it. Service
Slice placement, child-to-parent ordering and no stop propagation to parent must
match. Unknown/unreadable effective graph or jobs refuses admission. No new OS
verbs or broad privilege are added.

After seal, completed stop and actual whole-parent emptiness, systemd may GC
inactive service metadata. Absence of that metadata is allowed for positive
closure only when the exact retained active parent object/InvocationID is still
freshly verified, its recursive population is zero, admission is sealed and no
pending activation can repopulate it. Canonical native/service lineage, if it
was committed, remains required history; it is not repinned to a current unit.
For running/provisioning or before a stop request, a live service must still
have exact observable identity and parent placement. Missing current metadata
then gives no permission to start, adopt or guess cleanup. During closure with
no current service to stop, verify whole-parent emptiness directly; absent
service status is never evidence of emptiness. A missing/replaced parent is
always unprovable, regardless of service status. No process-local D-Bus retention
is assumed. This supersedes earlier proposal wording requiring current service/
native identity after successful stop; parent proof never loses its own checks.

Version-pinned primary basis: systemd v257
[resource-control documentation source](https://raw.githubusercontent.com/systemd/systemd/v257/man/systemd.resource-control.xml)
defines Slice's automatic Requires/After toward the slice;
[unit documentation source](https://raw.githubusercontent.com/systemd/systemd/v257/man/systemd.unit.xml)
defines Wants/Requires activation and dependency symlinks. These establish edge
direction, not an executed fixture or proof of deployed unit retention.

## Immutable canonical stages

Use the existing attempt journal and slot-before-attempt exclusion, with four
closed private observations. No existing observation is edited or retrofilled.

1. `scope_provisioning` retains its existing intent payload before activation.
2. `scope_bound` records only the positively observed retained parent generation:
   `{project_id, assignment_id, attempt_id, mapping_id, slot_id,
   reservation_generation, scope_generation, deployment_digest, boot_id,
   slice_invocation_id, cgroup_identity, resource_identities}`. Object schemas
   remain those in the proposal. `scope_generation` is this event's journal
   generation. Commit it before starting the native service, creating readiness
   baseline or calling layout. Parent identity must be freshly authenticated and
   pinned; lost parent-start reply permits exact reserved-slot inspection only.
3. `scope_native_bound` records `{scope_generation, scope_binding_event_id,
   service_invocation_id, server_identity, socket_identity, workspace_id}` only
   after authenticating the installed native incarnation/readiness. It precedes
   layout. Each field retains the proposal's existing exact origin checks.
4. `scope_child_bound` records `{scope_generation, scope_binding_event_id,
   native_binding_event_id, original_process_binding}` only from 09j's original
   authenticated layout reply, exact returned pane query and genuine child gate.
   Release requires all stages, current lineage, boundary and original-child
   membership. Absence of either later event is no permission to release.

The events form one immutable lineage; there is no mutable full binding, nullable
child field, compatibility representation or additional store. Each later event
references the same original parent and cannot replace a prior native/child
incarnation. Startup/activation/layout admission shares seal exclusion: a sealed
parent admits no pending or new start/create/release. An OS start already admitted
before seal remains cleanup work; it must not run outside that retained parent.

## Close before child binding

The existing public selectors, mutation replay, two-phase seal/observe projection
and error contract stay unchanged. `scope_sealed` references the parent
`scope_bound` event. Close can seal and positively close that exact generation
without `scope_native_bound` or `scope_child_bound`. Proof concerns the whole
parent writer scope, not a guessed child or successful native creation.

For lost service-start/readiness/layout replies after parent binding, preserve
uncertain provisioning and held ownership. No repeat start/create, search/adopt
possible pane or retrospective child binding is permitted. Close authenticates
the recorded parent and installed fixed service ownership. It stops the service
and all baseline/server/descendant processes in that parent. With no recorded
native binding, current inspection may establish cleanup membership only: it
cannot create launch provenance or authorize worker release. Foreign or replaced
parent, service placement outside it, conflicting incarnation, pending activation
that could later populate it, denied inspection or incomplete stop stays
unverifiable. An uncertain service creation outcome is not inferred absent.

`scope_closed_no_writers` payload is exactly `{scope_generation,
scope_binding_event_id, seal_event_id, boot_id, slice_invocation_id,
cgroup_identity, populated: 0}`. Service/native/child lineage, when present, is
resolved from its canonical events; the positive event requires verified
recursive empty retained parent, sealed admission and no pending activation or
new incarnation. The service invocation is not a mandatory fabricated proof
field. Restarts reconstruct all committed stages and revalidate that same parent.
Missing child/native stages are historical facts, not evidence corruption.

If parent creation/start outcome is unknown and no exact parent binding can be
positively established, observation/close returns `evidence_unavailable`; no
null generation or no-writer proof is minted. Keep the intent and slot held.
Inspect only the original reserved activation lineage; if original exact parent
is established, commit the parent stage without repeating start, then close.
An absent/replaced parent or unprovable origin cannot be repaired by adopting a
current same-name scope, treating inactivity as absence or authorizing reuse.

## Pre-release abort and safe reuse

9c2 extends the existing `abort_launch` owner, not consumer finish. Current
LaunchLifecycle abort already accepts bounded failure evidence and chooses a
failed transition/reconciliation for positively proved pre-release exit, but
`owned` requires in-memory launch observations and its positive predicate needs
a child handle. Those requirements cannot prove or recover an unbound launch.
The current general AttemptStateMachine permits reserved→running only; this
amendment explicitly requires a guarded protected-launch abort admission for
reserved→failed, not a synthetic running/process_start or a globally unchecked
transition. Uncertain→failed remains the existing reconciliation route.

Public `abort_launch` params remain exactly `{mapping_id, assignment_id,
attempt_id, launch_ticket, failure_evidence, failure_digest, expected_generation}`
with non-null mutation ID, no transfer. `failure_evidence` is a UTF-8 JSON string
(maximum 16,384 bytes), digest SHA-256 over those exact bytes, with closed
scope-abort schema `{kind: "protected_scope_before_release",
scope_generation, scope_binding_event_id, seal_event_id, proof_id}`. These are
selectors, never caller proof. Existing exact-child abort evidence remains a
distinct evidence kind; it cannot satisfy whole-scope resource closure.

The recorded live launcher incarnation or mapped live recovery supervisor may
call; kernel peer/project/ticket checks apply. This branch reconstructs ownership
from canonical reservation and lineage after restart without demanding a
nonexistent child handle. Under slot-before-existing lifecycle/journal exclusion
and expected-generation CAS, the owner resolves and independently verifies:

- exact original parent lineage, seal and canonical closed_no_writers proof;
- no `release_launch` authority mutation anywhere in this attempt, no issued or
  potentially_executed projection, and no admission after seal;
- every service request canonically succeeded or failed-settled with verified
  imported provenance, and all registered inboxes canonically reconciled with
  verified signed evidence. Empty sets are permitted; unresolved effects are not.

Only then commit existing transition from reserved to failed (using this guarded
protected-abort admission), running to failed for a bound-but-unreleased launch,
or existing failed reconciliation from uncertain. Reason is
`protected_scope_closed_before_release`. Owner-authored `abort_observation` is
exactly `{kind: "protected_scope_before_release", release: "not_issued",
scope_generation, scope_binding_event_id, seal_event_id, proof_id}`. Persist
failure bytes under existing evidence/imports/launch-failure ref and return the
existing bounded launch projection with phase failed, failure_digest/ref,
abort_observation and required_action null; no absent process_binding is invented.

The normal canonical terminal/reservation release-before-reuse path then releases
this failed attempt/slot, under the same slot exclusion and recorded exact old
generation. A crash before release reconstructs the committed failed proof and
resumes that release, not a launch. The scope owner must adapt that release
reader to accept this guarded canonical abort lineage as well as genuine-child
terminal lineage. Release does not discard historical proof or retire the parent
before its failed transition and release are durable. The next attempt starts
wholly new lineage; old proof cannot authorize it. This release integration is
9c2 scope, not an outstanding unspecified API or a duplicate xz9 finish handler.

Same mutation ID returns the original committed reply after current identity/
visibility and exact-param checks, without another transition, stop or release.
Fresh mutation uses current CAS and revalidates proof plus effects/inboxes;
terminal contradictory abort conflicts. Malformed schema/digest is invalid_input;
wrong peer/project/ticket unauthorized; unknown attempt missing; stale CAS,
wrong lineage or already issued launch conflict; missing/corrupt/unverifiable
proof or unsettled effects/inboxes evidence_unavailable. A refusal preserves
current uncertainty/ownership and never cancels effects by assertion. Lost
parent origin still has no proof and remains held. Lost readiness/layout inside
a known bound parent can close and abort through this path without adopting or
retrying creation. No worker success/result or child identity is manufactured.

## Verification map (required future execution)

- Crash/lost parent-start reply before parent binding: exact original inspection
  or held evidence_unavailable; no new start, invented binding or slot reuse.
- Parent committed, lost native start/readiness: seal/stop baseline and any
  server/descendants, two-phase exact empty proof without native/child event.
- Native committed, lost layout reply: no pane search/create/release; whole-parent
  cleanup can succeed while child binding remains absent.
- Genuine child stage: all 09j original reply/gate checks still required; surviving
  sibling/descendant prevents positive proof after original child exits.
- Seal racing start/create, authority restart between every stage, manager
  activation pending, replaced parent/service and inaccessible evidence: preserve
  uncertainty and prohibit later admission or unrelated stop.
- Same-ID replay retains original reply; fresh close records current proof only
  after revalidation. Positive cleanup plus separate effects/inbox settlement
  enables canonical release and automatic fresh slot reuse; old proof refuses.

- Guarded abort: reserved, bound-unreleased and uncertain launch histories; exact
  role/ticket/CAS, absent child handles after restart, replay and crash before
  reservation release. One failed transition and fresh slot reuse follow verified
  cleanup; issued launch, forged selectors, unresolved service/inbox evidence and
  wrong/absent parent proof all refuse. General reserved transitions stay guarded.

- Unit graph: reject parent Wants/Requires/Upholds, transitive activation and
  enabled/trigger/drop-in alternatives; parent start produces no service/native
  process before canonical binding. Verify service starts afterward in the same
  parent and parent survives child stop/authority restart until proof/release.
