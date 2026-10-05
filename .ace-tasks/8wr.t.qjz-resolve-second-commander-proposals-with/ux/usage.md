# Resolve second-commander proposals with a sixteen-hour veto window: draft usage

Target interfaces, not claims of implementation.

## Scenario 1: Propose an exact release

```text
ace-hitl proposal create --assignment A --attempt ATT --project ace --file release-proposal.json
```

Expected: Kapitan gets context/options/recommendation and deadline; publish is authorized after explicit approval or 16h of verified silence.

## Scenario 2: Change scope before execution

```text
ace-hitl proposal revise PROPOSAL --file changed-proposal.json
```

Expected: Old revision becomes superseded; the changed operation waits a fresh 16h after acknowledged delivery.

## Immutable second-commander proposals

`ace-hitl proposal create --assignment ID --attempt ID --project ID --file proposal.json`
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

Set ACE_HITL_HERMES_CONFIG to the deployed Hermes runtime configuration. The living overseer
calls `ace-hitl proposal resolve-due` on start/status/watch ticks. It enters
`ace-hitl-hermes ingress reconcile --request ID --through DEADLINE --format json` outside
HITL locks. Hermes holds its ingress lock across checkpoint and the HITL decision transition,
so already received replies cannot be skipped. Unknown health/backlog defers resolution.
Production `--now` is rejected; controlled tests inject a trusted fixture clock.

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
