# Remaining protected consumers — normative specification candidate

2026-10-05; source review of main 6a80a387c. xz9.0 owns this consumer
implementation. Status stays draft / needs_review true for independent review.
9c2 has whole-spec approval at 1122ddf7be3d90a7339a87209c665a8f1d3eab19,
pending / needs_review false; its implementation depends on unfinished 09j.
No native tests, source implementation or installed acceptance occurred here.

## One owner and closed framing

Use the existing version-1 Authority Server envelope, deployment mapping,
kernel peer authentication, Router, LaunchLifecycle assignment resolver,
JournalMutation and lifecycle exclusion. No alternate controller/ref/cache owner.
All params below are exact key sets, unknown keys invalid_input. IDs use the
existing JournalMutation::ID bounds; digests are lowercase SHA256; generations
are nonnegative integers. mutation_id uses the existing strict nonnull mutation
ID for all three operations. No body except reconcile_inbox. Params cannot
select actor, principal, PID/birth, paths, signing keys, config, executable,
Inbox object, force, dry_run or generation mode. Server errors are invalid_input,
unauthorized, missing, conflict or evidence_unavailable as in the family contract.
Public data stays within the existing 16 KiB response bound; reason values are
fixed sanitized codes below. A full response cannot truncate evidence into a
false settled assertion; bounds failure refuses without mutation.

| Operation | Exact params | Exact data projection |
| --- | --- | --- |
| recover | mapping_id, assignment_id, attempt_id, expected_generation | attempt_id, state, decision, reason, generation, journal_commit |
| bind_inbox | mapping_id, assignment_id, attempt_id, expected_generation, event_id, inbox_context_id | event_id, attempt_id, inbox_context_id, registration, generation, journal_commit |
| reconcile_inbox | mapping_id, assignment_id, attempt_id, expected_generation, event_id, inbox_context_id, expected_registration, receipt_sha256, signature_sha256, transfer | event_id, attempt_id, inbox_context_id, registration, state, receipt_ref, signature_ref, generation, journal_commit |

registration and expected_registration are exactly
{event_id, attempt_id, payload_sha256, receipt_key_sha256}; their IDs and digests
obey the bounds above. Neither caller registration nor returned refs grant
permission: resolve and compare canonical original registration independently.
receipt_ref/signature_ref are canonical {artifact_id, ref, sha256, bytes}, never
absolute paths; only returned refs whose bytes/provenance verified may be exposed.
Existing transport.replayed wraps the original committed projection. Fresh same-ID
changed params/body digests conflicts. expected_generation compares the existing
attempt-local authority_generation, computed by JournalMutation from canonical
events filtered to this exact attempt_id. Existing authority status supplies that
value; it is not an assignment-wide, candidate, inbox claim or scope generation.
Reply generation is this same attempt-local mutation generation. Each fresh CAS
retry rereads state/bindings/provenance without changing the existing generation
owner or introducing another counter.
An exact replay authenticates current mapped principal/visibility and revalidates
retained canonical evidence outside JournalMutation's skipped callback, then
returns original data/generation/commit without another observation/native effect.
No retry upgrades an old reply; query existing status/9c2 observe for current
truth and use a fresh mutation with current generation when necessary.

## recover: exact attempt, no implicit resume

Only the exact live recorded launcher or current live deployment-mapped recovery
supervisor may call, with the same identity/incarnation checks as finish/9c2.
An old launcher UID alone is insufficient. The owner resolves exactly the mapped
assignment/attempt from canonical qjl, including missing disposable cache, and
uses AttemptCoordinator recovery_snapshot / AttemptReconciler observations as
the existing semantic owners. Existing resume is assignment-wide: do not call it
blindly. Scope its mutation plan to this attempt under the existing assignment
exclusion/CAS; never adopt, observe, transition or release siblings implicitly.
There is no separate recover-preview or caller dry_run flag: canonical existing
status and observe_execution_scope are read-only and manufacture no proof.

state is the current existing attempt state; decision is exactly adopt,
reconcile-required or restart-required. reason is exactly live_owner,
unresolved_effect, unresolved_inbox, launch_unbound, scope_unverifiable,
attempt_uncertain, checkpoint_unavailable or terminal_attempt. Check unresolved
effect/inbox before liveness, and uncertainty before adoption. Only a running
exact bound/issued live original owner with intact checkpoint/canonical evidence
and no unresolved independent work can adopt. Terminal attempt yields
restart-required/terminal_attempt; it cannot reopen or start a new attempt.
Reserved/unbound, uncertain, dead/replaced/unreadable scope or missing checkpoint
returns reconcile-required with the corresponding reason and retains ownership.
Unknown attempt is missing, corrupt canonical state is evidence_unavailable.

Fresh recovery atomically records the existing recovery_observation and, for a
running nonadoptable attempt, its legal uncertain transition, plus mutation reply
in one existing qjl CAS. Terminal/reserved/already uncertain inspection may record
an observation/reply but no fabricated process_start or terminal transition.
Recovery never itself grants stopped, succeeded or failed terminality from PID,
pane, timeout or local cache. Normal result finish and xz9.2 stop own their
separate terminal admissions using real 9c2 proof and independent settlement.
Replay revalidates retained observation chain, scope/result/accepted effect/inbox
references where used; a current worker need not survive for recovery replay.
Crash before CAS leaves prior ownership; after CAS reconstruct projection from
journal, with no duplicated adoption/native work or local journal fallback.

## Fixed inbox context and peer role

The existing source-controlled deployment resolver gains a services-project
inbox_contexts map keyed by bounded context ID. Entries select only installed
Herdr Inbox configuration: private deliveries root, trusted receipt public key,
pinned native endpoint and supervisor UID allowlist from existing project supervisor_uids and exact
launcher principal. They do not contain a peer-selectable executable/module
or key. The existing Herdr Inbox.from_config/constructor remains the client and
signature/key owner; validate roots/config/key/native endpoint under existing
protected ancestry rules at startup and every operation. Context ID alone is no
authority; project/mapping must select it and binding records retain that exact
context with its registration. Private roots remain private. Installation of
these fixed contexts is existing gad.8 responsibility; source resolver/wiring is
xz9.0. Missing context refuses, no cwd/env/global Herdr-config fallback.

Server's existing roles do not include signer. Reconciliation admits the existing
mapped supervisor/launcher trusted coordinator role only; signing is independent
cryptographic provenance verified by the fixed Herdr receipt key. No new signer transport role,
extra OS account or observer string is accepted as API authority. CanonicalEvidence
already assigns descriptor role signer for kind inbox; retain that evidence
purpose role, which does not confer Server peer-role authority. A standalone
signer may produce bytes out of band but cannot directly call this API by claiming
that role. The mapped supervisor submits those bytes; canonical provenance records
its authenticated UID/role and exact signed key/registration binding. Worker,
reviewer and executor cannot reconcile through those roles.

## bind_inbox: close admission before scope seal

Only the exact live active bound/issued mapped worker may bind; resolve its
existing worker actor from accepted origin, never authority actor or payload.
Under canonical lifecycle exclusion, resolve the fixed Inbox and obtain status
for the exact event, requiring attempt/registration identity and pinned key match.
Persist the immutable context+registration with existing inbox_binding semantics
and the sanitized reply atomically in canonical qjl. Same context/event with
identical retained registration is idempotent only after live/current checks;
changed context/registration conflicts. No mutable filesystem receipt authority.

Every fresh binding rechecks the original-generation 9c2 seal under the same
exclusion as close. Seal wins first: conflict, no new binding. Bind wins first:
closure/finish/stop must inspect that registration and cannot hide pending work.
Read/settlement of already bound inboxes stays permitted after seal. Worker-exited
or terminal same-ID bind replay refuses evidence_unavailable, as submit_result
replay does; it cannot use historic worker credentials to obtain current access.
No recorded registration means no invented empty-inbox proof; all actual fixed
context registrations and unattributable records relevant to the attempt must
be included in recovery, never ignored because cache/record vanished.

## reconcile_inbox: bounded signed bytes and canonical reader

Operation selects one source-owned inbox_proof transfer purpose: exactly two
parts, signed UTF-8 receipt JSON first (nonempty, at most 16 KiB), detached
signature second (nonempty, at most 16 KiB), at most 32 KiB total. Reuse Transfer's
strict parts/bytes/sha256 framing with this fixed purpose and ordering. Control
header still has the 16 KiB bound. Digests recomputed from exact raw parts must
match receipt_sha256/signature_sha256. No receipt embedded in params, optional
parts, artifact paths, reordered body, trailing bytes or absent write-EOF.
This is xz9.0-owned codec/Router/Server wiring, not a caller-chosen generic purpose.

Compare expected_registration to canonical inbox_binding and current Inbox status,
then invoke the existing Inbox.reconcile under its existing event lock with
that exact registration, parsed receipt, signed_bytes and signature. Herdr owns
claim generation/native binding, pinned key, signed-byte equality, consumed or
superseded proof, observer/evidence and optional replacement_target semantics;
the protected route cannot reinterpret or widen that signed receipt. Parsed
observer is an attestation, never authenticated API identity. Existing proof
refusal maps to evidence_unavailable, retains unresolved consumer ownership and
creates no accepted qjl proof. The original Herdr receipt format is the authority,
not another invented version. Superseded/queued outcome alone is not consumption
or terminal cleanup; existing current delivery state remains independent.

Import both exact verified raw parts through CanonicalEvidence, kind inbox,
existing canonical descriptor role signer (CanonicalEvidence::ROLES), same full project/assignment/attempt/
context/event/registration/claim-generation/native binding/key/receipt+signature
digests as binding_digest. request_id_or_event_id is event_id; the descriptor candidate_generation_or_claim_generation is the
verified claim_generation; the public reply generation remains the attempt-local
authority_generation. Owner-generated immutable descriptors and blobs,
inbox_reconciliation consumer event and sanitized mutation reply share one qjl
commit. xz9.0 wires this complete context into CanonicalEvidence readers,
recovery_inboxes, finish/stop and existing authorized inbox evidence_fetch; no
partial-provenance fetch becomes accepted. Never retain/trust local receipt_ref
or mtime as protected evidence. Temporary private materialization only if the
existing coordinator requires paths; remove it after verified import/refusal.

Herdr and qjl cannot share one Git CAS. Hold the existing assignment exclusion
before Herdr event lock as in current coordinator. If Herdr accepts then qjl
commit fails/crashes, preserve ownership and retry the exact proof: Herdr's
expected-registration verified replay accepts its retained identical receipt;
qjl revalidates retained native/key/receipt state then imports once. Changed proof
conflicts; a concurrent changed claim/native binding refuses. Never roll Herdr
back or declare terminal based solely on its accepted response. After qjl commit
before reply, canonical exact mutation replay verifies both blobs/descriptors and
Herdr accepted lineage without a new delivery, claim or transition. If retention
cannot verify the signed native outcome now, refuse evidence_unavailable rather
than returning success from a cache. Reconciliation remains possible after worker
exit/seal/revocation of effect grant; current supervisor project visibility still
required and no new effect authority is granted.

## Full composition and ownership

Preserve AuthorityComposition's fail-closed REQUIRED_ENDCAP guard. xz9.0 supplies
finish/recover/bind_inbox/reconcile_inbox and their coordinator/public driver
routing, inbox transfer/context/canonical readers. xz9.3 supplies submit_result/
evidence_fetch. 9c2 supplies observe/close execution scope, scope/seal guards,
claim_service_settlement and complete_no_effect through the existing service
owner. Full services startup must require all those capabilities plus existing
service_authorization; guard cannot be weakened/removed to claim availability.
Integration of owner handlers is source-controlled Router composition, never a
second implementation, YAML handler or alternate authority/journal. xz9.2 owns
prompt/stop extensions and their downstream consumer routing; qk0 owns its CLI.
Actual installed multi-user/native service/receipt/inbox/finish/recovery and
Linux/macOS supported claims remain family acceptance requirements. No current
source completeness or installed acceptance is inferred from this document.

## Fixed construction schema candidate

The missing exact context/construction decision is now specified in
[0-execute-one-protected-cross-user/fixed-inbox-context-amendment.md](0-execute-one-protected-cross-user/fixed-inbox-context-amendment.md).
This candidate requires independent review; it supersedes the earlier context
shorthand only after acceptance. No executable context/reconcile implementation
or installed readiness follows from the framing-only source.
