# Goal 3 — Protocol Navigation Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) as fallback.

1. **WFI list executes** — `results/tc/03/nav-wfi.exit` is `0`, and `results/tc/03/nav-wfi.stdout` contains `wfi://` entries (at least 5 lines).
2. **Guide list executes** — `results/tc/03/nav-guide.exit` is `0`, and output contains `guide://` entries (at least 1 line).
3. **Sources list executes** — `results/tc/03/nav-sources.exit` is `0`.
4. **Sources output is valid** — `results/tc/03/nav-sources.stdout` includes at least one local or workspace source path.
5. **Project bundle renders** — `results/tc/03/bundle-project.exit` is `0`, and `results/tc/03/bundle-project.stdout` is non-empty.
6. **Cross-command consistency** — each command has captured `stdout` and `exit` artifacts and all invocations succeeded with exit `0`.

## Verdict

- **PASS**: All four protocol navigation commands execute successfully with non-empty, protocol-relevant output and cross-command evidence is present.
- **FAIL**: Any command exits non-zero or output indicates no protocol data.

Report: `PASS` or `FAIL` with evidence (exit values, counts, key snippets).
