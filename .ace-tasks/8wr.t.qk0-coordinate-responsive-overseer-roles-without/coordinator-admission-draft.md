# Coordinator admission and responsiveness — proposed contract

Draft repair for qk0; requires independent readiness review together with the complete task. This document does not promote qk0 or add a dependency to xz9.2.

## Protected project capacity

Use the existing deployment's `launch_mappings`, each mapping's `project_id`, and its unique `execution_scope.slot_id` as the configured protected execution pool. Capacity is the number of provisioned slots for that project; there is no second mutable counter or independently configurable overseer limit that claims stronger authority than Assign. A deployment with one slot admits at most one protected attempt. Changing capacity is a domain deployment/maintenance operation, not a runtime flag that bypasses reservations.

The overseer may select only an authorized mapping exposed by the project topology. A caller with visibility to only part of the pool must not report that subset as the complete project's capacity. No available mapping means unavailable or no authorized capacity, not permission to create an unregistered worker. An explicit unavailable `--agent` selection is not silently replaced. Automatic selection tries authorized candidates in stable ID order; an attributable refusal may advance only before canonical registration/reservation/native effect. Accepted registration fixes mapping/assignment; a later reservation conflict never permits automatic switching. A lost or uncertain reservation response is reconciled using the original identity, never converted into another launch.

The protected stable agent ID equals the literal existing launch mapping ID. Domain topology publishes those IDs; no association table, display/role alias or new mapping enumeration RPC is needed. Complete installed capacity comes from held protected Deployment; visible candidates are its intersection with authorized project topology IDs. Report complete/partial visibility and usable candidates separately. The precise current-credential/role-precedence and restart contract is in `coordinator-source-contract.md`; assignment inventory remains scoped to a selected mapping and is not an admission grant.

Source verification of the discovery gap: `ace-lab` topology is caller-configurable through the ADR-022 cascade, while its fixed authorization file grants project visibility. `InventoryQuery#agents` returns configured agents for an authorized project; `PublicProjection.agent` exposes role/capabilities and only binding kind/state, with no protected launch mapping. Neither a fresh topology binding nor the count of those agents proves installed slot capacity or permission to launch. The implementation must resolve the selected stable agent to a protected deployment mapping and let Assign authenticate the actual peer against that mapping/project. It must reject missing or conflicting associations; it must not infer a mapping from role, pane, display name or array position. Complete pool claims require the protected deployment inventory, not merely a successful topology query. These are consumer acceptance requirements within qk0, not a claim that such a resolver already exists.

Assign remains the admission owner. It verifies the selected mapping and obtains its existing slot exclusion and canonical reservation before any native worker allocation. Two coordinators that select the same slot cannot both launch. Different available slots may execute concurrently. Inventory/status is a projection, never the admission lock. A reserved, running, uncertain, or terminal-but-unreleased attempt occupies its slot until Assign accepts the complete release evidence. Coordinator restart, process disappearance, prompt acknowledgment, and a green review do not free capacity.

Queue entries are existing reviewed tasks/assignments, not preallocated panes, worktrees or another execution journal. When all authorized slots are occupied, report capacity exhaustion with the known assignment references; unknown evidence is reported separately. No busy retry loop. Reconsider on the next existing wake or an explicit request after reconciliation.

The four-active-pane limit is a separate runtime layout bound, not execution authorization. It does not permit exceeding the configured protected pool. A backend that cannot create or verify the requested layout refuses that launch; it must not reuse another attempt's terminal. Empty future tabs are not created. Ordinary local mode retains its existing behavior and does not stand in for protected multi-user admission; a backend lacking the protected owner capability must refuse protected launch.

## Bounded proposal resolution

The existing proposal owner and sixteen-hour policy remain unchanged. qk0 must replace the unbounded `ProposalTick` subprocess wait with a bounded invocation: five-second wall-clock deadline, bounded output of at most 65,536 bytes per stream, and owned-child cleanup using an existing maintained bounded process implementation. Configuration cannot disable the deadline. No retry is performed within the same tick. Timeout, invalid output or unavailable HITL appears as `proposal_resolution.status = deferred`; status collection and the next interaction remain available. It does not grant authorization or execute the proposed effect.

The conversational coordinator delegates long-running work and never waits for implementation/tests/review completion before accepting the next Captain instruction. Proposal ticks are coalesced while one is outstanding; waking does not spawn an unbounded set of overlapping resolvers. A missed tick is revisited on the next existing wake. This does not introduce a new timer service, durable scheduler or proposal ledger.

## Required source checks

- Real canonical reservation races for two coordinators, same slot and distinct slots; no duplicate native allocation.
- Restart and every nonreleased attempt state continue consuming capacity; accepted release makes only its original slot available.
- Explicit unavailable agent, partial topology visibility, unavailable authority, and lost reservation acknowledgment never cause an alternate unauthorized launch.
- Four-pane boundary and unsupported protected backend refuse without orphan allocation; ordinary local mode is tested separately.
- Injected stalled/noisy/malformed proposal resolver reaches the bounded failure path and leaves status usable, preserves proposal ownership, and never grants authorization from a timeout.
- Repeated wakes during a pending tick coalesce; long delegated work does not block Captain steering. Actual installed responsiveness remains a gad.2 check.

Source rationale at `f2475fc31`: `Deployment#validate_execution_slots!` already requires unique slot/service/worker ownership; each project already has one authority owner. `LaunchLifecycle#reserve` and `#ensure_slot_available!` enforce canonical occupancy and release. `ProposalTick#call` currently uses unbounded `Open3.capture3` before `Status` collection. These sources justify reuse of the existing owners; they do not prove the proposed overseer consumer is implemented.

Independent scoped review, wave_n0n: APPROVE capacity/resolver direction, with the explicit topology/visibility readiness requirement recorded above. This is not whole-task promotion or source acceptance.

Independent discovery-gap review, wave_n0n (2026-10-07): APPROVE. Verified InventoryQuery, PublicProjection and fixed-grants/cascade separation against source. No new API, schema or task promotion; no executable behavior changed.
