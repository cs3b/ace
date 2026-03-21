# Goal 5 — Cross-Protocol Inference Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Capture set exists** — `results/tc/05/` contains stdout/stderr/exit captures for the wfi:// resolution.
2. **Zero exit code** — The resolution succeeded (exit code `0`).
3. **Correct extension resolved** — The stdout contains a path ending in `.wf.md`, proving the wfi:// protocol uses its own shorthand extension for inference.
4. **Protocol-specific shorthand** — The resolved path must be protocol-appropriate shorthand (`.wf.md`) and must not suggest guide shorthand output (`.g.md`).
5. **Consistent behavior** — The inference behavior is consistent with guide:// in shape (shorthand extension found without explicit extension in the request).

## Verdict

- **PASS**: wfi:// resolution succeeded with `.wf.md`, protocol-specific shorthand behavior is clear, and captures are complete.
- **FAIL**: Resolution failed, wrong/ambiguous extension evidence, or captures missing.

Report: `PASS` or `FAIL` with evidence (resolved path from stdout file).
