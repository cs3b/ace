# Goal 4 — Watch Recovers After Interruption Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/04/`.
3. Use debug evidence only as fallback.

1. **Assignment created** — `create.exit` is `0` and `assignment-id.txt` contains a non-empty assignment ID.
2. **Scoped baseline exists** — `status-before.stdout` exists and shows subtree-focused status for `@010` before recovery runs.
3. **Recovery command captured** — `watch-recover.stdout`, `watch-recover.stderr`, and `watch-recover.exit` all exist.
4. **Recovery surfaced from assignment state** — `watch-recover.stdout` includes explicit recovery language for the watched scope (for example `Recovering watched scope` or equivalent assignment-state recovery wording).
5. **Scoped boundary preserved** — the captured recovery/watch output and `status-after.stdout` do not show later parent siblings being watched as part of this scoped recovery case.
6. **Post-recovery state is coherent** — `status-after.stdout` reflects forward progress or scoped terminal state for `@010`.

## Verdict

- **PASS**: The retained suite proves scoped watcher recovery after interruption with raw captures.
- **FAIL**: Missing artifacts, no assignment-state recovery evidence, or widened scope beyond `@010`.

Report: `PASS` or `FAIL` with evidence from `status-before.stdout`, `watch-recover.stdout`, and `status-after.stdout`.
