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
   assignment/attempt. Verify both origins and reviewer checkout at one current
   canonical prefix. Independence requires a different actual agent process
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
6. Merge resolves canonical accepted review and executed fixed-service test
   receipts at admission and immediately before any Forge write. Compare caller
   references with owner projections. Ordinary worker checks alone do not prove
   service execution; candidate-bound service receipts are the execution owner.
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
| Source checks/review before admission and Forge effect | High | Merge plus real accepted lifecycle/service receipts, controlled Forge |
| Public retained request/download | High | Lab assignment client focused tests |
| Two real workers, independent review, serial merges | High | Later installed acceptance; not claimed by host fixtures |

Use bin/ace-test; final source gate requires fresh configured Pi verdict. Root
integration owns the broad suite after coordinated slices. No task is marked done.
