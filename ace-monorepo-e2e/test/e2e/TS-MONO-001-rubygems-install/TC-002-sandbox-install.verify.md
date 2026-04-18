# Goal 2 — Normal Bundle Install Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Core install artifacts captured** — `results/tc/02/install.exit`, `results/tc/02/install.stdout`, and `results/tc/02/install.stderr` all exist.
2. **Install command result is valid** — `results/tc/02/install.exit` is numeric.
3. **Command contract is explicit** — `results/tc/02/install-command.txt` exists and includes `bundle install` without `--full-index`.
4. **Success evidence (impact-first)** — If install exit is `0`:
   - either `results/tc/02/installed-ace-gems.txt` exists and includes at least one `ace-*` entry, with `results/tc/02/Gemfile.lock` containing at least one `ace-` gem dependency,
   - or `results/tc/02/install-summary.txt` explicitly explains that post-install bundle-list evidence was incomplete and points to captured `bundle-list.stdout` / `bundle-list.stderr` diagnostics.
5. **Failure evidence** — If install exit is non-zero:
   - `results/tc/02/install-summary.txt` exists.
   - `results/tc/02/install.stdout` or `results/tc/02/install.stderr` contains actionable error details.

## Verdict

- **PASS**: Required artifacts exist and evidence is consistent with normal install outcome and installed gem end state.
- **FAIL**: Missing/invalid exit evidence, missing success end-state proof, or missing actionable failure details.

Report: `PASS` or `FAIL` with evidence (exit code value, key output snippets).
