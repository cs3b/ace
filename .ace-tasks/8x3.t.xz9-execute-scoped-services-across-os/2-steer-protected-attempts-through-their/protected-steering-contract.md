# Protected steering consumer amendment — specification candidate

xz9.2 remains draft / needs_review true. Whole 9c2 specification approval
1122ddf7be3d90a7339a87209c665a8f1d3eab19 supplies the selected scope mechanism;
implementation/native proof and unfinished 09j remain prerequisites. Existing
xz9.0 composition and independent service/inbox settlement remain dependencies.

Use version-1 Authority framing and existing mapped exact live launcher or
trusted mapped supervisor, current project visibility, canonical exclusion/CAS
and Router. No worker, reviewer, executor, signer claim or caller-selected native
endpoint. Exact params for stop_attempt are {mapping_id, assignment_id,
attempt_id, expected_generation}; nonnull strict mutation_id, no transfer.
expected_generation and reply generation use existing attempt-local
authority_generation from canonical events/status, not assignment-wide, candidate,
inbox claim or scope generation.
Prompt's desired params add text (nonblank UTF-8 <=16 KiB) but its native method/
acknowledgement and bounded transfer framing remain the concrete review question
in the task; no positive prompt implementation readiness is claimed. The total
16 KiB control header cannot contain a full 16 KiB prompt plus envelope: final
prompt framing must use a fixed bounded body or lower the exact text bound in
that review, never silently widen Server limits. This question includes transport
framing and canonical driver observation, not permission to invoke a generic CLI.

Stop delegates scope sealing/termination exclusively to 9c2 close_execution_scope;
it does not duplicate pane.close/kill or manufacture no-writer proof. Serialize
stop with existing lifecycle owner and translate its intent into the same exact
scope close mutation. First stop/close seals and durably records issued intent
before its owner requests stop; positive closure requires 9c2's later fresh close
and proof. One owner records canonical replies; do not perform nested unrelated
journal mutations or reverse slot/lifecycle lock ordering. Fresh stop may resume
idempotent exact-generation 9c2 cleanup per its contract, never act on a new slot
incarnation. stop is not finish and supplies no result/review approval.

Exact success data for stop is {attempt_id, state, proof_id, required_action,
generation, journal_commit}; state is uncertain or stopped. proof_id is null
unless exact accepted 9c2 closed_no_writers proof verifies; required_action is
exactly reconcile_scope, settle_services, reconcile_inbox or null. Scope unresolved
takes precedence, then unsettled services, then unresolved inbox. Even with local
proof, every original request must be verified succeeded/failed-settled through
existing service owner, including sealed unclaimed requests via 9c2 settlement
identity/challenge/no-effect gate, and every inbox must be currently verified by
xz9.0 canonical consumer. No remote target is canceled by local scope emptiness.
Outstanding work yields uncertain and retains reservation/worktree/slot. No new
effect or inbox registration after seal. No success or forced prune follows.

Positive stopped admission requires still-active exact attempt, real retained
scope proof/incarnation/seal and all independent settlement, revalidated on every
CAS retry under existing exclusion. Its legal stopped transition, proof reference
and reply commit atomically in qjl. 9c2 release happens only after terminal CAS;
crash leaves the retained closed slot until exact release-before-reuse. No stopped
receipt is invented where existing coordinator transition is the owner.

Exact same-ID retry reauthenticates current mapped principal/visibility, verifies
canonical intent/proof/settlement/terminal chain and returns original reply without
resending destructive control or upgrading uncertain to stopped. A fresh current-
generation mutation follows observed closure/settlement for final admission.
Historical terminal replay after slot reuse reads original retained evidence,
never touches new scope. Fresh terminal stop conflicts; changed same-ID parameters conflict;
malformed schema invalid_input, wrong peer unauthorized, absent attempt missing,
stale generation/binding conflict, corrupt/missing proof evidence_unavailable.
Unsupported scope capability refuses, not a synthetic stopped outcome.

Prompt research evidence: HerdrExecutor.agent_prompt executes agent prompt CLI;
RuntimeAdapter.send chooses agent_prompt only after an agent probe and otherwise
pane_run/send_text. ProtectedNativeControl supplies authenticated pinned protocol
request/create/observe/terminate but no typed protected prompt. Generic request
is not a closed prompt contract. Selecting it without actual native method/
params/ack/error evidence would invent required behavior. This existing task must
resolve that source/protocol question before readiness approval. Keep issuance
before one native write, no raw prompt journal/log persistence, no replay send,
no automatic resend on busy/stall/lost reply and submission != consumption.
xza retains consumption ownership and qk0 retains user-facing CLI ownership.
