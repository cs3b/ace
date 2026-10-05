# Resolve second-commander proposals with a sixteen-hour veto window: draft usage

Target interfaces, not claims of implementation.

## Scenario 1: Propose an exact release

```text
ace-hitl proposal create proposal-0123456789abcdef01234567 --assignment A --attempt ATT --project ace --file release-proposal.json
```

Expected: Kapitan gets context/options/recommendation and deadline; publish is authorized after explicit approval or 16h of verified silence.

## Scenario 2: Change scope before execution

```text
ace-hitl proposal revise PROPOSAL --file changed-proposal.json
```

Expected: Old revision becomes superseded; the changed operation waits a fresh 16h after acknowledged delivery.

## Immutable second-commander proposals

`ace-hitl proposal create proposal-0123456789abcdef01234567 --assignment ID --attempt ID --project ID --file proposal.json`
returns immutable proposal/revision/request IDs in awaiting-delivery state. The sole Hermes
polling actor publishes the full precise proposal and records confirmed submission before
HITL persists delivered_at and a deadline exactly sixteen hours later. Failed or uncertain
submission cannot arm the window. A Telegram Reply `approve [rationale]`, `veto [rationale]`
or `clarify [rationale]` applies only to the correlated immutable revision; other replies
stop automatic approval and require revision. Missing rationale remains absent.

The JSON proposal requires operation, target (`resource` and optional `artifact_digest`),
candidate_head, input_digest, context, options, recommendation and prerequisites; rationale
is optional. Contents are bounded and non-secret. Input digest uses the canonical service
input digest. Candidate head is separate from base head and the evidence journal commit.
Every precisely presented operation is eligible for sixteen-hour silence, including
publishing, deployment and access/privilege expansion. Fixed service scope, current head,
independently executed review/tests, bound running attempt and operation-specific OTP gates
still apply at execution. Proposal authorization never supplies credentials or runs a callback.

`ace-hitl proposal show ID --format json` shows decision, deadline, actual Assign claim/outcome
and a bounded history page; continue with `--history-after HISTORY_NEXT`.
`ace-hitl proposal history --project ID --query TEXT` retrieves relevant prior decisions;
continue with `--after NEXT`. Project visibility and exact requester identity gate history.
`ace-hitl proposal revise ID --file changed.json` supersedes the prior decision and creates a
new request with a fresh full window after acknowledgement. An unresolved claimed effect
must be reconciled before revision; known successful or proven no-effect settlement can be
followed by a new revision. Interrupted revision creation can retry the exact same file.

Set ACE_HITL_SOCKET and ACE_HITL_PROJECT for the living overseer. It calls
`ace-hitl proposal resolve-due --project PROJECT` on start/status/watch ticks.
The authenticated proposer queues an idempotent reconciliation wake in the
canonical Assign proposal; the command returns `queued-for-transport`, never an
approval claim. The existing installed Hermes `serve` loop polls Telegram under
its own configured transport UID and reconciles queued deadlines after polling.
No proposer subprocess opens transport configuration or impersonates transport.
Hermes holds its ingress lock across checkpoint and HITL decision transition;
unknown health/backlog defers resolution. Failed ticks remain visible while
watch/status continues. Production `--now` is rejected.

Creation requires an explicit stable ID (`proposal-` followed by 24 lowercase
hex digits). Persist that ID before invocation and retry the exact same ID,
assignment, attempt, caller and document after failure or a lost reply. Changed
binding/content is refused. Assign commits the immutable prepared lifecycle
request first; exact retry or the transport pending scan materializes it after
restart. No pending lifecycle orphan exists before canonical commit. Concurrent
materialization creates once and preserves current delivered/answered state.

Unresolved earlier same-request ingress blocks later approval delivery. Exact
reply sequence/content/time deduplication uses canonical decision history;
unseen lower sequence is applied, and changed duplicate content is refused.
History grows in the existing canonical event chain, while public responses use
bounded pages. Hermes metadata never stores message bodies.

The immutable authorization reference is the revision ID, passed to `ace-lab service request`.
Assign atomically checks the canonical proposal under its sole journal claim lock/CAS;
a forged prefix/YAML string or changed operation/target/head/input/caller cannot authorize.
A late veto before claim denies execution. After claim it records stop_requested without
rewriting performed effects; the service rechecks it before safely stoppable invocation.
An uncertain claim remains uncertain on restart and is never automatically dispatched again.
Canonical sanitized decision history shares the qjl evidence ref; no parallel executor or
execution ledger exists in HITL. This source workflow is not installed/native/Telegram or
multi-UID acceptance proof.

### Proposal admission configuration

The protected HITL service reads proposer admission from the same trusted grants
policy as transport and project authorization. For example:

```yaml
hitl:
  service_uid: 1200
  transport_uids: [1201]
  proposal_uids: [1202]
authorization:
  principals:
    "1201":
      projects: [ace]
    "1202":
      projects: [ace]
```

`proposal_uids` admits authenticated kernel peers to create and revise proposals
only for their configured projects. Transport admission alone cannot create a
proposal; proposer admission cannot acknowledge delivery, fabricate ingress, or
resolve silence. Missing role or project admission refuses the operation,
including direct library calls. This is a source configuration contract;
installed deployment adoption remains part of gad.8 acceptance.
