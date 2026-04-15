# Goal 2 — Fork-Run Delegated Subtree Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/02/`.
3. Use debug evidence only as fallback.

1. **Assignment created** — create command succeeded and assignment ID exists.
2. **Scoped subtree visibility** — scoped status for `@020` shows subtree-focused steps.
3. **Fork-run attempted** — fork-run command evidence is present.
4. **Outcome validity** — either:
   - subtree completion evidence is present, OR
   - explicit provider/tool-unavailable error is captured.
5. **State integrity after attempt** — post-attempt status evidence is coherent and does not show unrelated silent mutations.

## Verdict

- **PASS**: Fork-run scoped delegation path was exercised and produced a valid, user-visible outcome with coherent post-state.
- **FAIL**: Scoped behavior not demonstrated, fork-run attempt missing, or post-state evidence is inconsistent/corrupt.

Report: `PASS` or `FAIL` with evidence (scoped/unscoped status and fork-run output).
