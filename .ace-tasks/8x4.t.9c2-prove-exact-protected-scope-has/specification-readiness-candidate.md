# Whole 9c2 specification readiness candidate

2026-10-05; based on main 8b01f992b and the integrated independent draft reviews.
Task remains draft/needs_review until independent whole-task readiness verdict.
This document selects no installed capability and claims no implementation/tests.

## Selected engineering contract

Dedicated per-attempt worker Herdr in a reusable fixed systemd slot, separate
persistent overseer and bounded canonical services for host capabilities are the
engineering default within the requested program. The optional earlier preference
question may steer this default; silence is not approval and is not a permission
gate. No current behavior contract depends on a further Captain answer.

| Contract | Owner and definition |
| --- | --- |
| Platform | Linux system systemd with reviewed v257 semantics/equivalence, unified cgroup v2, pidfd/birth, Yama=2, POSIX ACLs and effective namespace/security restrictions; otherwise refuse. No macOS/Windows/PID-group fallback. |
| OS ownership | Existing system manager owns slice/service/cgroup and installed namespace. Existing Assign authority receives only exact installed slice/service StartUnit/StopUnit permission. Worker/public callers receive none. |
| Deployment | Closed authorities/v2 map and immutable unit/boundary manifests; replace/remove obsolete v1 under ADR-024. Generic ACE validates contracts, Lab-config installs domain-specific units/accounts/artifacts/routes/auth inputs. |
| Admission | Existing LaunchLifecycle reserves before activation, records exact provisioning lineage, verifies complete fresh generation/readiness/boundary and preserves 09j's fresh original-child gate before release. |
| Native | Fixed same-User unprivileged readiness/ACL action; authority independently checks genuine kernel peer against MainPID/birth/InvocationID before each write. FD leakage/in-process injection forbidden. Replacement/handoff refuses; never repin. |
| Local resources | Exact resource_identities for scratch checkout/Git metadata, harness state/output/cache/temp and native runtime roots, protected by immutable ancestor permissions and mount/FD/socket/route boundaries. Canonical candidate_root is separate authority quarantine. |
| Seal/closure | Canonical irreversible old-generation admission seal precedes systemd StopUnit; retained parent cgroup identity plus recursive populated=0 and boundary revalidation produce private positive proof. |
| External effects | Seal serializes with new service request/effect-claim/begin_dispatch and final fresh receiver authorization. Settlement-only recovery claims/challenges permit unclaimed requests to reach verified no-effect through the same owner; admitted effects still settle. Terminal consumers independently require verified service settlement/inbox reconciliation; cgroup emptiness cancels no remote operation. |
| Interfaces | Existing Authority framing: read-only observe_execution_scope, mutation close_execution_scope, closed params/results/refusal behavior in scope-owner-proposal.md, sealed-service-settlement-contract.md and usage examples (including recovery-only service calls). No new CLI, root argv or caller-supplied proof. |
| Restart/reuse | Reconstruct canonical lineage and reopen exact same-boot retained scope, otherwise hold uncertainty. Historical proof cannot authorize a new generation. Fresh slot reuse only after positive old closure and canonical release. |

## Coordination and private event precision

9c2 extends the existing authority lifecycle exclusion with one fixed per-slot
interprocess lock under installed authority-owned state_root, acquired before
canonical slot inspection or manager transition. This is coordination, not a
second journal/store/controller. Unit names and lock paths are resolved only from
the map. No arbitrary worker-selected lock or slot is accepted. Acquire/revalidate
slot exclusion before existing assignment/journal mutation exclusion, consistently
for begin/close/release; consumers must not invert the order. Hold it while
inspecting complete canonical attempt reservations and issuing any bounded manager
transition. A crash releases the lock but leaves canonical reservations/seals
held; restart reconstructs them before allowing a new begin. Unknown, conflicting
or unreadable registrations/bindings refuse. No stale PID/lock-file content proves
slot availability. A second authority process cannot admit the same slot from
an independent assignment chain while its reservation remains held.

Private canonical event names and payloads are:

* scope_provisioning: {slot_id, deployment_digest, reservation_generation},
  in the existing exact assignment/attempt/mapping chain before OS activation.
* scope_bound: the exact generation record in scope-owner-proposal.md,
  including resource_identities and original_process_binding, verified before
  payload release. scope_generation equals this event's canonical journal
  generation; context plus manager/kernel identities, never the integer alone,
  identifies a generation. No global slot counter or second allocation store.
* scope_sealed: {scope_generation, scope_binding_event_id}, canonically committed
  with the close mutation's original running projection before OS stop.
* scope_closed_no_writers: the exact positive payload already specified in the
  proposal, referring to binding/seal IDs and populated=0. Its event ID is proof_id.

These are new required registered private observations, not claimed existing
event types. Existing reservation, mutation replay, commit/generation, terminal
and receipt envelopes remain the owners. Workers cannot upload event assertions.
The provisioning record has no guessed PID/socket/workspace. A lost start reply
inspects that held intent and exact installed slot; it cannot mint scope_bound
from an unrelated running server. scope_bound requires the gated original child,
and release checks the same generation after its commit. A missing native binding
before release is refusal/held provisioning, never a partial running proof.

A known bound attempt whose current identities cannot be verified returns
unverifiable/inspect_exact_scope. A sealed empty generation without canonical
positive proof returns unverifiable/close_scope. Running returns running/close_scope;
verified positive canonical closure returns closed_no_writers with proof_id and
null required_action. A reserved/unbound attempt lacks the required generation
and returns evidence_unavailable, rather than a fabricated null binding. Unknown
attempt returns missing. The two-phase mutation/replay behavior remains unchanged.

## Review and acceptance boundary

The prior fda55 whole-task review requested the concrete seal-recovery repair;
sealed-service-settlement-contract.md now defines that behavior and closed API.
That historical REQUEST CHANGES verdict is retained, not rewritten as approval.
This frozen revision is submitted for rereview. No undefined interface, ownership,
platform or behavior choice remains for this
engineering baseline. Whole-task independent readiness review should assess the
coherent contract and identify any concrete counterexample or missing rule.
Promotion is not performed by this drafting lane.

Future implementation must satisfy all task SCs, source/schema/installer checks
and executed permitted installed evidence: real descendant/native membership,
no uncontrolled local writers, exact permissions/ACL/FD/namespace/provider startup,
seal/receiver race and lost-reply behavior, original-child release, retained parent
restart and safe continuous slot reuse. Tests may falsify feasibility; failure
holds ownership and requires a real corrected mechanism, never an intentional
stopgap. Those are acceptance obligations, not proof already supplied or vague
specification blockers. No native probes, host changes, Yama/auth changes or
filter retries are authorized by this document. 09j's recorded restriction stays
in force. Existing xz9.0/xz9.2 consumer delivery remains separately owned.
