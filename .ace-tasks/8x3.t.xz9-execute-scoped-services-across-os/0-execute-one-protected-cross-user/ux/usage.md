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

Retry the exact mutation ID with its exact original parameters after response loss. Its generation and journal commit identify that accepted mutation, while the returned service state may reflect a later canonical completion. Query authoritative service status for the current attempt generation before a subsequent service mutation. An identical existing request under a new mutation ID still requires the current expected generation and creates no second service claim. A `created` or `retained` claim is not invocation permission; the receiver invokes only after a fresh successful begin-dispatch permission, never after a replay.


### Executor checks current authorization

After obtaining a fresh successful begin-dispatch response, the recorded executor sends `service_authorization` with the exact request/claim/candidate/input binding and original bounded input bytes. It reloads the installed Lab operation, compares its source-owned operation digest, and compares the returned policy digest with the immutable canonical claim projection. It obtains a final fresh authority read immediately before invoking once; that successful read is the admission point. The receiver never reconstructs the authority-private proposal journal. Neither this read nor a created/retained claim grants invocation permission.

If policy, lease or a canonical proposal changes after claiming, the authorization read refuses; the receiver invokes nothing and retains uncertainty after any issued begin permission. A successful read from an earlier call cannot be cached to bypass that refusal. Changes after the final admission point do not retroactively cancel an admitted effect; a local operation mismatch still prevents invocation.

If begin or authorization reply is lost, the receiver reports uncertainty without invoking or obtaining a second permission. An executor that already observed an outcome can still complete the exact recorded request after revocation or lease expiry; completion does not require this effect-admission read.


An executor reporting the exact observed outcome sends `complete_service` with its immutable request/claim/candidate and receipt/artifact binding, without an expected generation or generation-mode flag. The owner resolves current completion generation on each CAS retry, so an interleaved mutation cannot force a revoked executor to obtain a broad status read. Status itself still refuses absent/revoked current project visibility for every role. This records truth only; no new effect permission is created.


# Protected result and terminal admission — draft usage

API surface: agent/client API. These examples use the existing version 1
Server envelope; project_id and deployment mapping are fixed installed values.
The family protected-authority-contract.md amendment defines exact types,
permissions, bounds, response fields and error codes.

## Submit a worker result, then finish after cleanup

The exact live mapped worker sends operation submit_result, mutation_id result-1,
params `{mapping_id, assignment_id, attempt_id, expected_generation,
candidate_generation, head, receipt_sha256, transfer}` and receipt_artifacts
bytes (normal receipt first; ordered declared artifact bytes follow). Success
returns result_id, original/upload/normalized digests, ordered canonical artifact
references, verdict, generation and journal_commit. It leaves the attempt active.
After worker exit and positive original launch containment cleanup, the exact
launcher or mapped supervisor sends operation finish, mutation_id finish-1,
params `{mapping_id, assignment_id, attempt_id, expected_generation,
candidate_generation, head, result_id}` without a body. Success returns terminal
state and accepted receipt_digest with canonical generation/commit. A worker
finish is unauthorized. Pending effect/inbox/cleanup is evidence_unavailable and
ownership remains held. Failed receipt with no artifacts still uploads its one
receipt part and cannot assert no effect.

## Fetch one authorized retained artifact

A permitted peer sends operation evidence_fetch, mutation_id null,
params `{mapping_id, assignment_id, attempt_id, kind, purpose_id, artifact_id}`.
Success returns exact canonical descriptor, current generation/read commit and
one artifacts part matching descriptor bytes/SHA256. Worker can fetch only its
own result bytes; raw review/observation fetch by worker is unauthorized. Current
project revocation denies retained evidence. No receipt part or filesystem path
is supplied on this read.

## Retry after a lost reply

Retry the identical submit_result or finish envelope with the original mutation
ID. The original canonical reply returns with transport.replayed true and no
second import/terminal release. Changing content under that ID conflicts; sending
a fresh result ID for the same candidate or fresh finish ID after terminality
conflicts. Missing canonical provenance/blob returns evidence_unavailable even
if a disposable local cache still contains an earlier successful response.

Full usage will be completed during child implementation. This draft does not
claim full service composition startup or installed cross-user acceptance.
