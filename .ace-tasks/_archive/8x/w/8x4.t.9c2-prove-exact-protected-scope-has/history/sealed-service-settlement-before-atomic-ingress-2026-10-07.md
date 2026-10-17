# Sealed service settlement — normative 9c2 repair

2026-10-05. Resolves the REQUEST CHANGES finding in the independent whole-spec
review of fda55dcdfe33a2b75d0a6aab38114e2b18597926. Task remains draft/needs_review
for rereview. No source, native probes, host changes or tests occurred.

## One owner, settlement-only admission

The existing canonical service owner/journal admits recovery identity and
challenge-bound no-effect completion after scope seal. It does not infer that
all requested work was dispatched, or that all undelivered replies mean no effect.
The selected path is **settlement-only claim admission**, not direct unclaimed
owner cancellation. A request recorded before seal remains terminal-blocking until
verified succeeded or failed-settled. Sealing never drops that request.

Add claim_service_settlement to the existing protected Authority framing. Exact
params are {mapping_id, assignment_id, attempt_id, request_id, head,
candidate_generation, expected_generation}; mutation_id is required, no transfer.
No actor, receiver UID, scope selector, policy/claim binding, target path or
asserted no-effect boolean is accepted. The authority selects the canonical
request and its installed service receiver. The authenticated live executor must
be that fixed receiver UID (full installed peer credentials); if already claimed,
it must also be the exact recorded executor UID. Workers/launchers/supervisors
cannot claim recovery on the executor's behalf.

Under existing service/request/lifecycle exclusion and journal CAS, require exact
canonical project/assignment/attempt/mapping/request/head/candidate bindings and
a recorded scope_sealed for the request's original generation. Use historical
request identity; current policy revocation, lease expiry, dead worker or candidate
advance cannot prohibit recording outcome truth. Corrupt/missing canonical input
or lineage refuses; no request is created after seal. Revalidate on every CAS retry.

For requested-but-unclaimed work, positively inspect the complete canonical
request chain under seal: no executor claim, issued invocation, dispatch_started
or effect-admission outcome exists, and sealed admission rejects every new effect
route. Canonical phase absence is evidence only under these enforced guards,
not a caller statement. Atomically bind the request to the installed executor,
allocate its identity ticket/claim_binding through the existing digest owner,
set state uncertain and dispatch_phase settlement_only, and issue the challenge.
This claim reserves no new effect grant, consumes no fresh invocation authority
and is never convertible to issued/dispatch_started. Its policy_digest is the
existing canonical digest owner's digest of {kind: settlement_only,
request_binding: <full immutable canonical request identity>, seal_event_id};
claim_binding hashes that immutable binding plus the owner-generated ticket ID
as for existing claims. These identify recovery provenance, not effect policy.

For an already claimed request, retain executor/ticket/claim_binding/policy_digest
and its actual dispatch_phase. Never replace an issued/dispatch_started claim with
a fabricated settlement_only history. The same operation issues or returns a
current durable challenge for that binding. If a nonterminal request has no failed/
uncertain event yet, atomically record recovery-uncertain and then issue the
challenge in the canonical chain. Challenge is bound to request/input/claim and
that latest failed/uncertain event digest/generation. A later failure invalidates
it and requires a fresh claim_service_settlement mutation; no old artifact/challenge
is promoted. Already succeeded/failed-settled returns retained terminal state and
no new challenge or claim; it cannot reopen the request.

Response data is exactly {request_id, state, dispatch_ticket_id, claim_binding,
dispatch_phase, reconciliation_challenge, generation, journal_commit}, where
reconciliation_challenge is null only for an already verified terminal request;
otherwise exactly {no_effect_challenge, challenge_generation,
challenge_event_digest}. Exact same mutation-ID/params replay returns that
mutation's original projection/generation/commit; it never issues another claim
or replaces its old challenge. service_status supplies current request truth.
A fresh mutation with current expected_generation obtains a superseding challenge
when required. Changed same-ID params or stale generation conflicts; wrong peer
unauthorized; malformed input invalid_input; absent request missing; unsealed or
mismatched lineage conflict; corrupt/unverifiable provenance evidence_unavailable.
All refusals preserve effect consumption/uncertainty and terminal ownership.

## Existing no-effect completion gate

The settlement-only identity allows the existing complete_no_effect owner gate
to operate; it does not itself reach failed-settled. Wire that existing semantic
gate into the protected Authority boundary as part of 9c2 (it is not claimed to
exist in today's Endcap operation list). Exact params are {mapping_id,
assignment_id, attempt_id, request_id, claim_binding, head, candidate_generation,
reconciliation_challenge, receipt_sha256, transfer}, required mutation_id and one
existing receipt_artifacts transfer. There is no expected_generation or caller
generation-mode selector. The challenge object has the exact fields above.

Use the existing canonical completion/import/ServiceEvidence/Coordinator owner:
exact recorded executor; request/claim/input/receipt/artifact identity; fresh
challenge-bound structured attestation; admitted-after challenge/current failure
lineage; immutable imported bytes and provenance; transition to failed-settled
atomically under current recorded-completion CAS. The owner resolves generation
on each retry, revalidates current challenge and never uses local paths/mtime or
caller booleans as evidence. Unclaimed settlement therefore still has attributable
executor, claim binding and challenge, satisfying the normal no-effect reader.
The executor freshly verifies actual target, handler/process termination and
absence of surviving effect writers. For settlement_only it additionally names
the canonical never-dispatched phase; canonical no-dispatch history alone does
not waive fresh target evidence. If actual no-effect cannot be established, keep
uncertain/failed and hold terminality; record real observed success/failure through
the existing completion owner where appropriate.

Identical receipt/artifact/challenge completion replay returns the original
canonical completion. Wrong peer is unauthorized; malformed framing invalid_input;
unknown request missing; wrong/stale claim/challenge, changed retained bytes or
success/no-effect contradiction conflict; unverified target/evidence, missing
canonical provenance or invalid attestation evidence_unavailable. All refusals
retain uncertainty and grant no effect. Lost completion reply cannot cause another
invocation. Revocation/seal/expired lease/dead worker does not forbid verified
completion truth. Unknown target status never becomes no-effect by timeout.

## Final receiver authorization is seal-aware

The existing service_authorization read remains read-only, with unchanged params
and null mutation ID. **Every fresh read**, including the final read immediately
before invocation, checks original-generation scope_sealed under the same canonical
lifecycle exclusion as close. Sealed or settlement_only requests refuse conflict
before returning authorization. request_service/new effect claim/begin_dispatch
and all lower canonical fresh-effect update paths enforce the same seal.
Retained request/status/replay may report old truth but grant no invocation.

The receiver's final successful fresh authorization read is the effect-admission
linearization point, as in the existing consumer contract. If seal wins first,
no effect is admitted even if begin permission was obtained earlier. If that
read wins first, the effect is already admitted and can still run after seal;
completion/settlement remains mandatory. Seal cannot retroactively cancel it.
The authority read grants no permission without the single fresh positively
received begin permission and installed operation consistency checks. The receiver
must not repeat begin or invoke after an authorization refusal/lost reply.

| State at seal / reply loss | Recovery |
| --- | --- |
| Requested, no claim | claim_service_settlement creates only recovery identity/challenge; fresh complete_no_effect evidence settles. |
| Claimed issued, no begin | Preserve claim; obtain fresh challenge and positive no-effect evidence; no new begin. |
| begin_dispatch committed or reply lost | dispatch_started is uncertain even if receiver believes it did not invoke; preserve claim and require fresh target/termination/no-writer evidence. |
| Final read denied/lost | Receiver invokes nothing from that attempt; canonical/target uncertainty still requires challenge-bound fresh evidence, not guessed cancellation. |
| Final read admitted before seal; effect in flight/outcome reply lost | Preserve admitted effect; accept verified outcome or fresh verified no-effect recovery. No retry invocation and no cgroup-based remote cancellation. |
| Verified terminal service state | Revalidate retained evidence; no new claim/challenge/invocation and no reopening. |

All requests, including newly bound settlement-only ones, must be succeeded or
failed-settled with independently verified evidence before finish/stop terminal
CAS. Scope closed_no_writers remains local proof only. No duplicate ledger,
receiver controller or privileged broker is introduced. This repair defines new
required wiring/guards in the existing generic owner, not completed behavior.
