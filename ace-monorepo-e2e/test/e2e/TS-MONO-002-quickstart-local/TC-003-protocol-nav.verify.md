# Goal 3 — Protocol Navigation Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Workflow list resolves** — `results/tc/03/nav-wfi.exit` is `0` and `nav-wfi.stdout` lists at least 5 workflow entries with `wfi://` protocol references.
2. **Guide list resolves** — `results/tc/03/nav-guide.stdout` lists at least 1 guide entry.
3. **Bundle project loads** — `results/tc/03/bundle-project.exit` is `0` and `bundle-project.stdout` is non-empty (contains project context or a cache path).
4. **Sources available** — `results/tc/03/nav-sources.stdout` lists at least 1 registered source.

## Verdict

- **PASS**: All protocol commands execute successfully, lists are populated, bundle produces output.
- **FAIL**: Any command fails (non-zero exit), or lists are empty.

Report: `PASS` or `FAIL` with evidence.
