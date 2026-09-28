# Deliver durable agent inbox messages once across recovery: draft usage

Target interfaces; these examples do not claim current implementation.

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
