# Protected steering consumer contract

Captain selected original-attempt-terminal submission on 2026-10-07.
The accepted 9c2 specification supplies the scope mechanism; 9c2 source is still
required, while 09j source is delivered. Native installed proof belongs to gad.2. Existing
xz9.0 composition and independent service/inbox settlement remain dependencies.

Use version-1 Authority framing and existing mapped exact live launcher or
trusted mapped supervisor, current project visibility, canonical exclusion/CAS
and Router. No worker, reviewer, executor, signer claim or caller-selected native
endpoint. Exact params for stop_attempt are {mapping_id, assignment_id,
attempt_id, expected_generation}; nonnull strict mutation_id, no transfer.
expected_generation and reply generation use existing attempt-local
authority_generation from canonical events/status, not assignment-wide, candidate,
inbox claim or scope generation.
Prompt uses the same exact four control params as stop, a required mutation_id,
and one version-1 TransferCodec `prompt_text` part. Limits are 16,384 total bytes,
one part, and 16,384 bytes per part; the normal 16,384-byte control-header limit
is unchanged. The part must be nonblank valid UTF-8. Its declared length and
SHA-256 must match actual bytes. Raw text is absent from params, journal, replies
and logs; the owner binds its digest/length with caller/action/attempt/original
generation in canonical mutation identity. Upload EOF is a write-half-close so
the same connection can return its bounded reply. The body is ephemeral and any
private transfer spool is removed on all completion/failure paths. No recovery
can reconstruct a prompt from the journal or resend an issued mutation.

The native method is the guarded extension of existing `agent.prompt` without
`wait`: exact opaque native terminal ID plus text and expected_origin as defined by the
normative guarded design. Capability absence is a preissuance refusal. The
mapped driver uses the pinned authenticated server and captured original actor;
only full text-plus-Enter acknowledgement for that origin admits `submitted`.
Definite preadmission zero-byte errors are refusals. Partial writes, unknown
errors, mismatched/lost acknowledgement and postadmission death remain uncertain.
Native error strings cannot supply retry authority. Existing authority replies
retain canonical mutation identity, generation, journal commit and attributable
evidence; they never echo text. Same mutation retry reauthenticates and returns
its retained outcome without another native request.

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

The existing unguarded CLI and RuntimeAdapter send paths are not protected
prompt handlers. N1 in the canonical task owns the native extension across all
existing native layers; N2 owns ACE integration against its frozen reviewed
revision. xza retains consumption ownership and qk0 retains user-facing CLI
ownership. Source readiness is distinct from implementation and gad.2 acceptance.
