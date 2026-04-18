# Goal 3 — Full-Index Fallback Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Core fallback artifacts captured** — `results/tc/03/fullindex.exit`, `results/tc/03/fullindex.stdout`, and `results/tc/03/fullindex.stderr` all exist.
2. **Install command result is valid** — `results/tc/03/fullindex.exit` is numeric.
3. **Fallback command contract is explicit** — `results/tc/03/install-command.txt` exists and includes `bundle install --full-index`.
4. **Success evidence (impact-first)** — If fallback exit is `0`:
   - `results/tc/03/installed-ace-gems.txt` exists and includes at least one `ace-*` entry.
   - `results/tc/03/Gemfile.lock` exists and contains at least one `ace-` gem dependency.
5. **Failure evidence** — If fallback exit is non-zero:
   - `results/tc/03/install-summary.txt` exists.
   - `results/tc/03/fullindex.stdout` or `results/tc/03/fullindex.stderr` contains actionable error details.

## Verdict

- **PASS**: Required artifacts exist and evidence is consistent with fallback install outcome and installed gem end state.
- **FAIL**: Missing/invalid exit evidence, missing fallback command evidence, missing success end-state proof, or missing actionable failure details.

Report: `PASS` or `FAIL` with evidence (exit code value, key output snippets).
