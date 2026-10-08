# Observe correlated Codex consumption through native API — draft usage

## Positive scenario

A protected supervisor can correlate one Codex inbox delivery to genuine native consumption and expose sanitized verifiable observation without changing the event.

The source provider now uses the selected app-server correlation contract;
the argv queue path is removed. Installed acceptance still belongs to
lab-config:8wl.t.gad.2 and is not established by local socket fixtures.

The fixed context API exposes `observe_context(operation_id, key_generation,
event_id, attempt_id, claim_generation)` under `observe_to_sign` admission.
It selects the stored submission itself and queries the same authenticated
runtime. A completed exact client/digest/turn/item returns a sanitized candidate
observation. Missing history returns uncertainty. Wrong peer, stale generation,
changed record/key/admission or runtime association refuses. The original
ingress deadline covers record locks and the native query. The API never signs,
settles, resends or deletes; import/signer integration remains incomplete.

## Refusal scenario

Wrong peer or stale/missing exact binding returns a classified refusal/uncertainty, invokes no retry and grants no signing authority.

## Acceptance

Retain sanitized real add/read/turn evidence and exact installed version/source for idle and busy queues, duplicate identical text and restart.
