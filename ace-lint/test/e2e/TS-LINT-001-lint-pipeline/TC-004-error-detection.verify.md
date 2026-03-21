# Goal 4 — Error Detection Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Artifacts exist** — Files exist in `results/tc/04/` including exit code and pending.md copy.
2. **Non-zero exit code** — The captured exit code is non-zero (syntax errors are fatal).
3. **pending.md exists** — A pending.md copy exists with a "Lint: Pending Issues" header.
4. **Checkbox format** — pending.md contains checkbox-format issues (`- [ ]` lines).
5. **File section headers** — pending.md contains section headers with issue counts (e.g., `## filename (N issues)`).

## Verdict

- **PASS**: Non-zero exit code, pending.md exists with proper header, checkbox format, and file section headers.
- **FAIL**: Zero exit code, missing pending.md, or wrong format.

Report: `PASS` or `FAIL` with evidence (exit code, pending.md header, checkbox format sample).
