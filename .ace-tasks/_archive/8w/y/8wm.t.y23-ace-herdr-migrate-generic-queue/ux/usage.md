# Deliver durable agent inbox messages once across recovery: draft usage

Enqueue, status, deliver, and receipt-file reconciliation run in the current implementation. The native clients expose submission but no queryable consumption or eviction outcome; an operator or supervisor must supply an observed native outcome in the receipt file.

## Scenario 1: Enqueue without duplicate delivery

```text
ace-herdr inbox enqueue --event EVENT --attempt ATT --ref ref.json --file prompt.txt
```

Expected: Same identity/digest returns existing record; different payload for EVENT fails.

## Scenario 2: Inspect interrupted delivery

```text
ace-herdr inbox status --event EVENT --format json
```

Expected: Shows bound identity and uncertain state; no automatic resend.

## Scenario 3: Reconcile with authoritative proof

```text
ace-herdr inbox reconcile --event EVENT --receipt proof.json
```

Expected: The command checks the trusted detached signature, exact event, attempt, claim generation, digest, and full target binding. The receipt must name an operator or supervisor and contain a native outcome observation and reference. A missing, unsigned, or mismatched receipt returns `state: uncertain` plus `reconciliation_refusal`; it never replays the message. A matching `consumed` observation records `completed`. A matching `superseded` observation returns the record to `queued` for one new claim. See `ace-herdr/docs/usage.md#durable-agent-inbox` for the key setup and receipt shape.
