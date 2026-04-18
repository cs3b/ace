# Goal 1 - Status Dashboard Real State Verification

## Injected Context

The verifier receives the `results/` directory tree and sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm task state changed on disk from pending to done for at least one created task.
2. Confirm status/list captures exist under `results/tc/01/`.
3. Use runner observations to map refs when needed.
4. Use stderr/exit fallback only when necessary.

1. `status-before.exit` and `status-after.exit` are `0`.
2. `create-pending.exit`, `create-done-candidate.exit`, and `mark-done.exit` are `0`.
3. `list-pending.exit` and `list-done.exit` are `0`.
4. `status-after.stdout` reflects changed state compared to `status-before.stdout` (for example done count increases or recently done includes created task).

## Verdict

- **PASS**: Real task state transitions are visible in status/list output and command runs succeed.
- **FAIL**: Commands fail or status/list output does not reflect the created state transitions.
