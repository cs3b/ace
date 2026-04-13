# Goal 4 Verification - Compact refusal contract for rule-heavy input

## Expectation

Compact mode returns exit code `1` for rule-heavy input and emits refusal/guidance records.

## PASS Criteria

- `results/tc/04/compact.exit` is `1`
- `results/tc/04/compact.stdout` includes `H|ContextPack/3|compact`
- `results/tc/04/compact.stdout` includes `POLICY|class=rule-heavy|action=refuse_compact`
- `results/tc/04/compact.stdout` includes `FIDELITY|`
- `results/tc/04/compact.stdout` includes `REFUSAL|`
- `results/tc/04/compact.stdout` includes `GUIDANCE|`
- `results/tc/04/compact.stderr` includes `One or more sources were refused in compact mode`
