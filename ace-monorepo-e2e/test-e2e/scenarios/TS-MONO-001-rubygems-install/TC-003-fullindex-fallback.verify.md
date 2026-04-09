# Goal 3 — Full-Index Fallback Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Core artifacts captured** — `results/tc/03/fullindex.exit`, `results/tc/03/fullindex.stdout`, and `results/tc/03/bundle-env-install.stdout` all exist.
2. **Install path isolation** — `results/tc/03/bundle-env-install.stdout` includes the sandbox Gemfile path and does not indicate `/home/mc/ace/Gemfile`.
3. **Install command result** — `results/tc/03/fullindex.exit` is numeric.
4. **Success proof artifacts exist on success** — If `results/tc/03/fullindex.exit` is `0`, then `results/tc/03/bundle-list.exit`, `results/tc/03/bundle-list.stdout`, `results/tc/03/version-check.exit`, and `results/tc/03/version-check.stdout` all exist.
5. **Success evidence** — If exit code is `0`:
   - `results/tc/03/bundle-list.stdout` exists and mentions at least one `ace-*` gem.
   - `results/tc/03/version-check.exit` is `0`.
   - `results/tc/03/version-check.stdout` reports all `ace-*` entries as current (lines indicating `OK`).
6. **Failure evidence** — If exit code is non-zero, `fullindex.stdout` should contain error details.

## Verdict

- **PASS**: Artifacts are consistent with the install outcome; success runs include freshness checks, and failed fallback runs include clear error output.
- **FAIL**: Missing artifacts, unresolved stale versions, missing isolation evidence, or missing error detail on failure.

Report: `PASS` or `FAIL` with evidence (exit code value, key output snippets).
