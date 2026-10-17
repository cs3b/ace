# Public worker submission and Inbox reconciliation — readiness candidate

2026-10-08. Specification only; independent review pending. xz9.0 owns public
command/workflow adoption. Existing xz9.3 owns the unchanged canonical result and
fetch validators; xza.3 owns Inbox context admission/key lifetime. This adds no
wire operation, permission ledger or task umbrella. The independently approved
three-command checkpoint 11f8342dd is delivered separately.

## Public selection and inputs

All three commands reuse ProtectedAssignmentContext and its exhaustive current
and retained installed-participant classification. A protected participant,
mapping hint or supplied protected selector selects protected mode. Empty
selectors refuse. There is no local fallback following selection or refusal.
Mapping, assignment and attempt are explicit and must agree with original hints.
Mutation IDs and the original expected authority generation are caller supplied,
never generated/refreshed on retry. Candidate generation is separate: candidate submission supplies the nonnegative
CURRENT generation (zero before first candidate); review/result select the returned
positive admitted generation. IDs/digests retain their existing owner bounds.

* `ace-assign submit-candidate --mapping M --assignment A --attempt T --head H
  --candidate-generation C --expected-generation G --mutation U --bundle FILE`:
  FILE supplies exactly one candidate Git bundle, at most 64 MiB. The existing
  Client uses purpose candidate and Endcap/CandidateTransfer performs canonical
  admission. No caller path crosses the wire. This worker workflow uses the live
  original worker; it does not impersonate the launcher. H is an exact existing
  SHA-1 head. Producing a valid bundle remains explicit work before submission;
  this command does not execute Git against an arbitrary path or infer acceptance
  from the captured queue. Success prints the unchanged submit_candidate data
  projection, including admitted candidate identity/generation/commit.
* `ace-assign submit-result --mapping M --assignment A --attempt T --head H
  --candidate-generation C --expected-generation G --mutation U --receipt FILE
  [--artifact FILE ...]`: receipt first, repeated artifact files in declared
  receipt order, using existing receipt_artifacts transfer. Receipt is 1..16 KiB,
  at most 16 artifacts, each at most 64 KiB, at most 256 KiB artifact aggregate.
  Artifact count, ordered SHA256 and declared receipt identity must match before
  sending. Failed empty artifacts are permitted; succeeded empty artifacts refuse.
  Local paths provide bytes only, never canonical artifact references or authority.
  Output is the existing sanitized submit_result data, including result_id,
  original/uploaded/normalized receipt digests and canonical artifact references.
* `ace-assign inbox-reconcile --mapping M --assignment A --attempt T --event E
  --inbox-context I --expected-generation G --mutation U --registration FILE
  --receipt FILE --signature FILE`: registration is closed
  {event_id,attempt_id,payload_sha256,receipt_key_sha256}, persisted from successful
  inbox-bind output, at most 16 KiB. Receipt/signature are the existing two ordered
  inbox_proof parts, each nonempty and at most 16 KiB. Digests are computed from
  exact raw bytes. Expected registration is compared by the original canonical
  owner, not trusted from the file. Output is the unchanged reconcile_inbox data.
  Existing ordinary inbox-reconcile receipt/.sig behavior remains only when
  protected selection is absent; explicit signature is required in protected mode.

Local input reads must be bounded regular-file reads with NOFOLLOW/NONBLOCK,
validated UTF-8 closed JSON through the existing strict decoder where JSON is
needed, and held identity/byte equality through transfer preparation. Unknown,
duplicate, malformed numeric or unsupported receipt fields refuse before send.
No receipt producer, successful verdict, signer identity or process birth is
invented by the CLI. Existing authority validators remain the acceptance owners.
Each command makes one existing Client call with its unchanged absolute 30-second
budget; no retry loop. A lost reply is unavailable/uncertain with original
selectors retained. Existing typed command-boundary classification gives nonzero
exit without a backtrace; it never rewrites a transport failure into success.

## Original worker workflow and continuation

PreparedInput.drive_prompt must name these commands and original selectors for
execution by the actual prepared worker/provider descendant while its lineage is
live. PreparedWorker still requires captured queue completion, but completion
alone never submits or accepts candidate/result. The worker explicitly prepares
and submits candidate bytes, obtains real independent review through the existing
review owner, and submits a real execution receipt/artifacts for that exact
candidate. Supervisor finish remains separate and requires accepted review,
canonical result, no-writer proof and settled independent work.

Persist original command arguments and exact ordered files before the first call.
Same mutation changed parameters or bytes refuses; an exact accepted retry uses
those inputs unchanged and the existing immutable replay. No generation refresh.
Worker submission after exit/terminal/replaced birth refuses. Corrections require
new canonical candidate generation and fresh review. After worker exit/lost reply,
authorized supervisor/owning launcher uses existing attempt_status and evidence
owners to discover retained result; discovery neither resubmits nor grants finish.
Inbox reconciliation runs as existing mapped supervisor or exact original launcher,
not worker/reviewer/executor or a caller-asserted signer. It remains available after
seal/worker exit under original key/context/native proof. Queued/superseded reply
is not consumption or settled terminal work.

## Generation handoff, review consumer and receipt producer

For a **new** operation, obtain generation from the existing bodyless
`attempt_status` request `{assignment_id:A,attempt_id:T,
result_candidate_generation:null}` under the actual permitted original worker or
supervisor. Its `authority_generation` is the expected authority CAS generation;
`result_candidate_generation` is a separate candidate selector. Persist this
response with the complete next command arguments and byte inputs before sending.
For candidate submission C is the expected current candidate generation: use
result_candidate_generation when present, otherwise zero for proved absence.
Endcap compares C to current and returns candidate_generation C+1. Use the returned
positive value for review/result, never calculate acceptance from a local queue. A successful
mutation returns `generation` and `journal_commit`; its generation can seed the
immediately following new operation only when no other operation intervened.
Intervening independent review changes generation, so result submission must make
a new read and persist its `authority_generation` before its **first** submission.
A stale CAS refuses; caller may deliberately prepare a new operation/mutation after
reading current state. An exact retry preserves its originally persisted G, never
refreshes G under the same U. This rule does not forbid reads between distinct
successful operations. Inbox reconciliation likewise uses current authority status
for its first new mutation; it never substitutes signed claim generation for G.

`PreparedInput.drive_prompt` identifies the installed project and mapping and
instructs the actual worker to hand the accepted candidate tuple to an independent
installed reviewer. The worker cannot invoke review as that principal. The actual
existing reviewer consumer is:

```
ace-overseer review --project P --agent M --assignment A --attempt T \
  --head H --candidate-generation C --expected-generation G \
  --mutation REVIEW_REQUEST --accept-mutation REVIEW_ACCEPT
```

This invokes `ProtectedReview.call`: original reviewer credentials ->
`request_review` -> retained original Driver -> `assign_review` ->
`export_candidate` -> maintained independent reviewer -> `accept_review`.
Its persisted request/assignment/acceptance files preserve exact inputs. Acceptance
uses the **first request reply generation**, not embedded historical assignment
generation; a concurrent mutation refuses rather than refreshes acceptance.
Success requires returned `state:accepted` and its canonical `acceptance` selectors.
Lost request/acceptance is inspected with the same consumer's `--status` and
original request mutation, never rerun blindly. The worker's subsequent status read
selects its accepted candidate and authority generation; supervisor finish still
independently revalidates the actual accepted review at the terminal prefix.

The result receipt producer is the existing
`Ace::Assign::Models::ExecutionReceipt` plus the existing `ReceiptVerifier` acceptance
owner, not captured queue status or the CLI serializer. The actual worker workflow
constructs `ExecutionReceipt.new(assignment_id:A,attempt_id:T,project_id:P,
scope:S,operation:OP,producer:{actor:WORKER_ACTOR,role:"worker",runtime:"herdr"},
head:H,verdict:V,artifacts:ORDERED_PATH_SHA_PAIRS,checks:EXECUTED_CHECKS,
recorded_at:Time.now.utc)` and writes `JSON.generate(receipt.to_h)` with the exact
ordered artifact bytes. P/S/WORKER_ACTOR come from original admitted prepared input
and installed mapping; H is the accepted tested candidate. OP/V/checks and
artifacts describe actual executed work; no default successful verdict, invented
check, campaign or queue-completion conversion. This existing model computes the
receipt digest; submit-result only transmits its already produced bytes. The new
maintained workflow instructions must give this concrete owner construction and
explicit submission argv, and the controlled composition test must use the same
model against real executed fixture checks/artifact bytes. No standalone receipt
success producer is claimed already delivered.

## Required controlled composition evidence

1. Actual original prepared worker command -> real Client/Server -> candidate
   admission -> independent canonical review -> real receipt/result -> supervisor
   finish. Inject only OS/provider/native boundaries; no seeded accepted result or
   queue-as-result shortcut. Keep candidate producer and receipt producer explicit.
2. Succeeded nonempty and failed empty result; wrong producer/head/candidate,
   malformed/duplicate JSON, reordered/corrupt/extra artifact, stale generation,
   changed-byte same ID, lost reply/exact retry, foreign/replaced/exited worker.
3. Actual bind reply saved as registration -> supervisor CLI signed proof -> real
   Inbox context/reconciliation/import/status. Prove original key/native binding,
   queued versus consumed, seal/worker exit, lost Herdr-to-Git confirmation/exact
   replay, wrong registration/context/signature, trailing/extra transfer refusal.
4. Registered parser tests for explicit empty selectors and unsupported installed
   participants, no local coordinator construction, classified authority/transport
   failures, no automatic resend. Ordinary command behavior remains independently
   covered. These cases do not claim physical cleanup or installed/native acceptance.

No source implementation or task metadata promotion is part of this candidate.

## Independent readiness verdict

Program reviewer independently approved this candidate for implementation on
2026-10-08. Inspected sources: LaunchLifecycle#status merges Endcap#result_status
authority_generation; ProtectedReview acceptance uses first request reply
generation; ExecutionReceipt.new fields match this producer construction. This is
readiness only. All controlled full source composition gates above remain unchecked.
