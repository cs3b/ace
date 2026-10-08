# Observe correlated Codex consumption through native API — draft usage

## Positive scenario

A protected supervisor can correlate one Codex inbox delivery to genuine native consumption and expose sanitized verifiable observation without changing the event.

The source provider now uses the selected app-server correlation contract;
the argv queue path is removed. Installed acceptance still belongs to
lab-config:8wl.t.gad.2 and is not established by local socket fixtures.

The implemented protected source command is:

```bash
bin/ace-herdr inbox observe --project PROJECT --mapping MAPPING --inbox-context CONTEXT --assignment ASSIGNMENT --event EVENT --attempt ATTEMPT --claim-generation 1 --format json
```

Use installed `ace-herdr` outside the source checkout. All selectors and the
positive retained claim generation are explicit. The caller must be the actual
installed principal granted `observe_to_sign`; discovery grants no authority.
The command validates the retained original selection before and after the
native read. Only a valid same-selection candidate permits read-only admission
release. Output is marked `candidate: true`, not an evidence ID or signed proof.
Unknown/invalid replies keep admission; no ordinary ambient fallback, signing,
settling or resend occurs. This remains a partial source implementation pending
authority import/signer and startup/installed acceptance.

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

## Managed prepared worker

The fixed prepared-worker source accepts only a typed, still-held original Codex runtime from installed composition. Its provider resumes the exact published endpoint/thread with the captured drive prompt in the original inherited worker terminal. Headless remote execution, missing terminal, missing runtime, wrong mapping/model, caller flags and ambient session lookup refuse. Terminal exit alone does not complete prepared work: original queue and candidate/result checks still apply. The installed startup factory/runtime handoff and terminal provision remain open source joins; there is no user flag or environment variable to bypass them.
