# Independent whole 9c2 specification readiness review

Reviewed exact head `fda55dcdfe33a2b75d0a6aab38114e2b18597926` in the proposal worktree, including specification-readiness-candidate.md, full task, usage, scope-owner proposal, native readiness report, local-writer boundary, retained design research, current authority/kernel/native contracts and adjacent xz9 consumer settlement requirements.

**Verdict: REQUEST CHANGES for one concrete service-seal recovery contract gap.** This is a whole-task specification-readiness verdict, not an objection that installed tests have not yet run. Keep draft / needs_review until the gap is resolved and independently re-reviewed.

## Finding: define settlement of requests sealed before dispatch

Target: local-writer-boundary-proposal.md:158–167 and specification-readiness-candidate.md external-effects row.

The seal blocks new request/claim/begin_dispatch effect admission and explicitly preserves completion of previously dispatched work. Terminal consumers nevertheless require every request to be succeeded or failed-settled. The adjacent protected-authority-contract.md:131–133 permits complete_no_effect only from the exact recorded executor with claim_binding and a canonical challenge bound to that claim. It does not provide an unclaimed request's settlement identity.

Concrete sequence: a service request is canonically recorded, then close seals the attempt before an executor claims it. It is not previously dispatched and has no executor/claim_binding. Finish/stop must reject its requested state. The specified complete_no_effect route cannot be used yet, while the seal's treatment of a fresh recovery claim is not defined. An implementer must choose whether to allow a special settlement-only claim or to have the canonical owner settle positively never-dispatched requests directly. Those choices change mutation authorization/state behavior and cannot be left as an implicit implementation inference.

Required repair: specify which existing owner/operation settles an unclaimed request after seal, its exact authorization and canonical no-dispatch evidence, and ensure it grants no effect permission. Define the equivalent path for an already claimed but never-dispatched request and lost begin/final-authorization outcomes; the latter require existing fresh no-effect evidence rather than guessed cancellation. Preserve completion of actually admitted effects. Explicitly state that the existing final fresh receiver authorization read (protected-authority-contract.md:127, the effect-admission linearization point) checks the seal, so begin permission before seal cannot silently authorize a new effect afterward. This uses the existing service owner/journal and does not need another ledger or broker.

This is a bounded specification repair. It does not require executing native tests or proving installed enforcement before promotion.

## Contracts that pass readiness review

The dedicated worker server, persistent overseer and bounded-service role split are the stated engineering baseline; the optional unanswered preference question is not an approval gate. OS owner, narrow permissions, supported Linux capability profile and unsupported refusal are explicit. Lack of current installed authorization does not constitute an undefined mechanism.

Fixed per-slot interprocess exclusion, ordering before assignment/journal exclusion, complete canonical reservation inspection and restart reconstruction prohibit cross-assignment simultaneous ownership without another store. The binding generation is chain-local and full project/assignment/attempt/slot/manager context supplies identity, so equal integer generations across assignments are harmless. Provisioning/binding/seal/positive event payloads, exact public params/projections and unbound/unknown/unverifiable refusal states are defined.

Native connected-peer checks before writes, no repinning, descriptor exclusivity, bounded same-User ACL consequences, fresh workspace baseline and the 09j fresh child gate are coherent requirements. Retained parent slice identity, canonical seal before stop, recursive empty observation, historical replay and release-before-reuse preserve uncertainty rather than guessing absence. The declared local resource set, immutable ancestor boundary, private harness/auth/session/cache/temp and provider routing form a usable specified profile. Remote effects, receiver targets and inboxes remain independent of local cgroup emptiness.

ADR-024 replacement removes obsolete v1 at delivery. Generic ACE versus Lab installer responsibilities are defined. The large standalone slice has concrete success criteria and failure/native verification coverage. Future implementation and permitted installed acceptance remain required deliverables, not prerequisite evidence for specification readiness.

No probes, native/security experiments, tests, implementation, source/spec mutations or delegation were performed. The 09j automatic-filter restriction remains in force. Only this independent review artifact was written.

## Repair rereview — 1122ddf7be3d90a7339a87209c665a8f1d3eab19

**Updated verdict: APPROVE whole 9c2 specification readiness at this exact head.** The earlier REQUEST CHANGES verdict above remains historical evidence. The repair closes its concrete contract gap; no remaining implementation-behavior, interface, owner, ordering or supported-platform decision was identified. Task status was not changed by this reviewer.

Read the complete eight-file delta against fda55dcdfe33a2b75d0a6aab38114e2b18597926, including all sealed-service-settlement-contract.md and the normative adjacent family amendment. Rechecked ServiceEvidence's actual canonical executor/claim/policy/challenge requirements. Approval applies to specification completeness, not delivered implementation or installed native proof.

The requested-before-claim sequence now has a precise selected route: a live fixed installed executor calls claim_service_settlement with closed params and expected generation. Under canonical exclusion/CAS the owner checks pre-seal immutable request lineage, verifies no claim/dispatch history, binds an owner-generated ticket/claim identity, records uncertain/settlement_only and a durable challenge. It neither consumes an effect grant nor permits conversion to dispatch. The recovery policy digest is explicitly defined; workers and supervisors cannot choose the executor, target or asserted no-effect result.

Already claimed work retains its executor, ticket, claim binding, policy digest and real phase. Recovery adds a failed/uncertain anchor when needed and obtains a challenge without rewriting dispatch history. Terminal requests retain verified outcome and do not reopen. Replay retains original projection/challenge; stale challenges need a fresh mutation. Errors, current generation/CAS retry checks and refusal ownership are specified.

The protected complete_no_effect wiring has closed transfer parameters and required mutation ID, while recorded-completion CAS resolves current generation. Existing ServiceEvidence/Coordinator/canonical import remains the owner. Settlement-only history does not waive fresh target/handler termination/no-writer evidence; uncertain or lost begin/final-read outcomes are not canceled by assertion. Claimed, dispatched and terminal cases are enumerated. This is attributable recovery rather than direct unclaimed cancellation or a second effect journal.

Every fresh service_authorization, including the final receiver read, now checks seal under the same lifecycle exclusion as close. Seal-first refuses even after begin permission; final-read-first admits an in-flight effect whose outcome still settles after seal. The family contract is amended consistently. Completion remains permitted after revocation/lease expiry/dead worker without restoring invocation rights. The repair's service/request/lifecycle locking is consistent with the whole candidate's slot-before-assignment/journal ordering for manager/release transitions; it introduces no reverse slot acquisition or separate owner.

The new recovery API and evidence wiring are explicitly 9c2 deliverables, referenced from the task bundle, owner responsibility, usage and family contract. They are not a hidden promise in umbrella prose or a circular dependency on consumer terminal delivery. Existing xz9 consumers still independently enforce service settlement/inbox reconciliation plus local scope proof at terminal CAS.

All previously passing whole-task contracts remain in force: fixed per-slot interprocess exclusion and canonical reconstruction, full chain-local generation identity, exact scope event/resource binding, explicit unsupported/refusal states, fresh original-child origin, native descriptor/peer protection, retained parent/seal/empty proof, independent effects, and safe release-before-reuse. Optional preference silence supplies no approval and creates no gate for the stated baseline. ADR-024 replacement removes v1.

Implementation must still satisfy success criteria and permitted installed acceptance, including effective OS authorization, native/ACL/FD/readiness, namespace/resource/provider enforcement, real descendants, restart, races and continuous reuse. Their absence at specification review is not a promotion blocker. No probes, tests, implementation/source/spec edits or additional agents were used; the 09j filter limit remains preserved.
