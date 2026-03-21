# Goal 5 — Error Handling Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **All four capture sets exist** — results/tc/05/ contains captures for circular, missing-ref, nonexistent, and invalid-model.
2. **Dry-run validation failures fail** — `circular.exit`, `missing-ref.exit`, and `nonexistent.exit` are all non-zero.
3. **Invalid-model dry-run prepares successfully** — `invalid-model.exit` is `0` and stdout or stderr indicates a prepared dry-run review session rather than model validation.
4. **Informative messages** — The three validation failures contain relevant error messages (circular dependency, missing reference, preset not found, etc.). The invalid-model capture should make it clear that dry-run preparation completed.
5. **No stack traces** — No Ruby stack traces in any output.

## Verdict

- **PASS**: The three true dry-run validation errors fail with informative messages, the invalid-model dry-run succeeds as prepared-session output, and no case leaks a stack trace.
- **FAIL**: Any validation failure exits 0, the invalid-model dry-run is misclassified, outputs are unhelpful, or a stack trace appears.

Report: `PASS` or `FAIL` with evidence (exit codes and short message snippets).
