# Route scoped role services with verifiable execution receipts

## Quick start

The caller needs an active managed `ace-assign` attempt, a configured Lab
service with the named operation, a deployment-owned exact authorization
reference, and structured JSON input. The caller keeps its own OS identity;
no executor credential is returned.

```json
{"target":{"resource":"release/1.2.3","artifact_digest":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},"arguments":{"version":"1.2.3"}}
```

Save this as `release.json`, then preview the exact scope:

```sh
ace-lab service request --project ace --assignment A --attempt ATT \
  --operation publish --input release.json --authorization DECISION \
  --request-id REQUEST --dry-run
```

Expected: one JSON `status: ok` document with `outcome: accepted`,
`dry_run: true`, the selected service ID, target and candidate head. No claim,
lease or effect occurs.

## Scenario 1: Execute an authorized request

```sh
ace-lab service request --project ace --assignment A --attempt ATT \
  --operation publish --input release.json --authorization DECISION \
  --request-id REQUEST
```

Expected: `succeeded` with a non-secret receipt when the executor confirms
the external outcome. The request claim precedes dispatch in the separate
assignment evidence ref; the journal commit does not change the candidate
head. A second invocation with the same ID and binding returns the stored
outcome without another dispatch. A changed binding is a `conflict` error.

## Scenario 2: Recover an uncertain request

```sh
ace-lab service status --request REQUEST --format json
```

Expected after a lost executor receipt: `outcome: uncertain` with the request
ID and exact operation. Do not submit another request ID for the same effect.
The executor or external system must provide attributable completion evidence
before reconciliation. Local assignment cache loss does not erase the record.

## Scenario 3: Refuse forged scope and stale authority

A caller-supplied role or executor identity grants nothing. The OS identity,
managed attempt, project, candidate head, input digest and target must match
the trusted authorization reference. Expired authorization or executor lease,
stale service binding, wrong project or changed candidate head refuses before
effect. Rejections for a valid managed attempt are recorded in the assignment
evidence ref. An environment `review-approval` operation never counts as an
independent code-review verdict.

## Reference

`ace-lab service request --help` and `ace-lab service status --help` list all
options. The complete input, policy, transport, error and recovery contract is
in `ace-lab/docs/usage.md`. Domain operation handlers and installed OS
identity proofs are owned by lab-config task `8wl.t.gad.b`.
