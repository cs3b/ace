# Ordinary candidate, independent review and merge evidence

Source base: 2289bc25c. This is the current implementation contract for ei9.0/.8;
installed acceptance remains open. No deployment, publication or Forge effect is
part of this source slice.

## Existing owners and missing connection

OrdinaryLifecycle accepts registered PreparedWork, actual native starts, progress
and attributable worker results into the sole EvidenceJournal. OrdinaryResults
deliberately cannot accept independent review or external effects. Endcap has
protected candidate/review ingress using CandidateTransfer, ReceiptTransfer and
CanonicalEvidence; its protected launch identities must not be fabricated for
ordinary work. ReceiptVerifier defaults to distinct actors. Installed ordinary
agents share the real account mo; independence must instead resolve accepted
agent process generations and sessions. Fixed merge currently validates reference
shape and HITL authorization without dereferencing canonical review/checks.

## Implementation order and public contract

1. Extend OrdinaryLifecycle with candidate/review operations and a source-owned
   OrdinaryReviewEvidence module, sharing its journal, exclusion, private input
   root and installed native admission. No new store or protected launch shim.
2. Original running worker submits a complete verified candidate bundle.
   Supervisor selects an already registered, genuinely started reviewer
   assignment/attempt. Verify both origins at one current canonical prefix.
   Assign at the reviewer's honestly observed base, then export canonical candidate
   bytes; verify actual candidate checkout and unchanged native binding at accept. Independence requires a different actual agent process
   generation AND native session, not a shell child PID or actor alias.
3. Only that reviewer exports the candidate and submits its original receipt
   plus bounded report bytes. Reuse the canonical receipt/artifact owners. An
   optional source-owned ReceiptVerifier independence verifier preserves its
   strict default for every existing caller.
4. Retain original uploaded receipt bytes and artifacts, bind acceptance to
   candidate generation and both origins, and revalidate source bytes whenever
   consumed. Cancellation/new candidate revokes approval. Replay retains exact
   mutation and transport bytes; current authority/reservation are mandatory.
5. Expose with_scope, origin_at!, candidate_at!, review_at! on that lifecycle to
   the shared fixed-service owner. Hooks accept only the held current CAS prefix
   and its exact events. The other author owns fixed_service_lifecycle,
   fixed_publication_lifecycle and endcap_service_context.
6. Merge resolves canonical accepted review and executed CommandExecution test
   receipts at admission and immediately before any Forge write. Compare caller
   references with owner projections. Ordinary worker checks alone do not prove
   execution. Existing CommandExecution does carry root-witnessed child/exit
   and immutable source head/tree. Add explicit root-policy purpose=test; only
   that command purpose with exact candidate head/tree and exit 0/no signal may
   supply test proof. No inference from argv or generic allowed command success.
7. Public ordinary assignment request retains the existing file API and closed
   registry. Document prepare/start/candidate/tests/review/merge/finish order and
   lost-reply recovery without changing accepted IDs or transport bytes.

## Delivery lifetime

A real delivery attempt remains RUNNING through candidate, tests, review and
merge/service settlement. Only then may its result be adopted/finished. Terminal
coder output can seed a NEW real delivery attempt, never reopen old authority.
Reviewer attempts may finish after acceptance; their immutable accepted review
remains bound to authentic start and submission. Cancellation still revokes it.

## Test responsibility map

| Behavior | Risk | Layer / owner |
|---|---|---|
| Same-account independent agent vs same agent or shell child | High | Lifecycle real Unix/Git; controlled installed native observer only |
| Full bundle export, receipt imports, corrupt/missing bytes | High | CandidateTransfer/CanonicalEvidence through ordinary client |
| Wrong head/project/attempt, missing origin, cancellation | High | Lifecycle CAS integration |
| Lost reply/replay, changed input, lock-wait revocation | High | OrdinaryServer/OrdinaryClient integration |
| Independence callback preserves strict existing default | High | ReceiptVerifier and protected Endcap regressions |
| Source checks/review before admission and Forge effect | High | Merge plus real accepted lifecycle/command receipts, controlled Forge |
| Public retained request/download | High | Lab assignment client focused tests |
| Two real workers, independent review, serial merges | High | Later installed acceptance; not claimed by host fixtures |

Use bin/ace-test; final source gate requires fresh configured Pi verdict. Root
integration owns the broad suite after coordinated slices. No task is marked done.

## Explicit remaining capabilities

This slice accepts direct independent reviews for two fresh candidate generations.
It refuses campaign receipts and does not yet connect accepted-head assessments or
bounded campaigns. That remaining .8 work must reuse the existing ace-review
canonical campaign owner; refusing prior approval after a head move is a current
capability boundary, not a new final policy demanding full review on every SHA.
The dynamic source-selected candidate materialization into a root-owned immutable
command execution view is also pending. Static command fixtures prove the owner
join without authorizing manual per-PR head/path policy edits.
