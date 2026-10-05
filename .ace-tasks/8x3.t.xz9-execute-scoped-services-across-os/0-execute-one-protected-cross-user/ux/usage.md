# Execute one protected cross-user fixture effect — draft usage

## Positive scenario

An authenticated launcher originates a managed attempt in the protected assignment owner; an independent reviewer approves the authority snapshot; the worker requests one fixed fixture effect under another OS user and obtains the canonical durable receipt.

Authority reserve/bind/import/review/request/completion APIs and ace-lab service serve use the companion contract. Include existing protected assignment driver/coordinator integration in this slice: no manually seeded journal shortcut.

## Refusal scenario

Wrong peer or stale/missing exact binding returns a classified refusal/uncertainty, invokes no retry and grants no signing authority.

## Acceptance

Create a registered candidate under launcher authority, accept independent current-snapshot review, run public service request/status and inspect protected qjl evidence.


## Authority command scopes

Full-service deployment uses `ace-lab authority serve --authority ID`; it composes one Assign authority server, 09j launch origin and Endcap with the same Lab-owned policy validator used by service execution. `ace-assign authority serve --authority ID` supplies standalone launch-only scope. Installed composition must match the command; the project never has parallel authority endpoints or journals. A full-service configuration refuses a launch-only command instead of accepting an incomplete server. Commands and actual installed proof remain implementation deliverables; this readiness amendment performs no deployment.

An owning worker submits business result bytes as canonical `result` / `worker` imports. The authority derives that attribution from the exact authenticated native attempt/process; a receipt actor string cannot grant it. Submission does not self-approve completion. The mapped launcher/supervisor admits finish after independent review and outstanding effect/inbox/process checks.

### Bounded receipt transfer

Review, result and service-completion clients send one receipt JSON part (at most 16 KiB), followed by up to sixteen ordered evidence parts. Each evidence part is at most 64 KiB; the evidence allowance is 256 KiB, separate from the receipt allowance. The fixed lifecycle operation selects `receipt_artifacts`; callers cannot select a transfer purpose. The control header carries the receipt SHA-256 and strict descriptor, never receipt contents or a filesystem path. Authority acceptance requires exact receipt identity, declared artifact order/digests, full body and write-EOF before mutation. An upload failure leaves the request uncertain or refused; it grants no effect permission.

Service admission transfers the original structured input as one fixed `service_input` part (up to 64 KiB). The authority uses the same Lab input/policy validator as the authenticated receiver, independently recomputes digest and target and rejects mismatches before claiming. Those original values are not journaled. Fresh dispatch requires resupplying that exact input and passing current policy, lease, peer and candidate checks. Installed receiver endpoint and private staging come from the project’s fixed `service_receivers` map; callers select neither paths nor executables.

Retry the exact mutation ID with its exact original parameters after response loss. Its generation and journal commit identify that accepted mutation, while the returned service state may reflect a later canonical completion. Query authoritative attempt status for the current generation before a subsequent mutation. An identical existing request under a new mutation ID still requires the current expected generation and creates no second service claim. A `created` or `retained` claim is not invocation permission; the receiver invokes only after a fresh successful begin-dispatch permission, never after a replay.
