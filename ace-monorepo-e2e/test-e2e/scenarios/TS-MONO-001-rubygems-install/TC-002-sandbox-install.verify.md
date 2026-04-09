# Goal 2 — Normal Bundle Install Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Core artifacts captured** — `results/tc/02/install.exit`, `results/tc/02/install.stdout`, and `results/tc/02/bundle-env.stdout` all exist.
2. **Install path isolation** — `results/tc/02/bundle-env.stdout` includes the sandbox Gemfile path (contains `BUNDLE_GEMFILE=$PWD/Gemfile` or current path) and does not indicate use of `/home/mc/ace/Gemfile`.
3. **Install command result** — `results/tc/02/install.exit` is numeric.
4. **Version freshness check exists** — `results/tc/02/version-check.exit` and `results/tc/02/version-check.stdout` exist.
5. **Success evidence** — If install exits `0`:
   - `results/tc/02/bundle-list.stdout` exists and mentions at least one `ace-*` gem.
   - `results/tc/02/version-check.exit` is `0`.
   - `results/tc/02/version-check.stdout` reports all `ace-*` entries as current (lines indicating `OK`).
6. **Failure evidence** — If install exits non-zero, `install.stdout` contains error details (resolution failure, dependency conflict, or missing sources).

## Verdict

- **PASS**: All required artifacts are captured and evidence is consistent with the exit code and version freshness check.
- **FAIL**: Missing artifacts, unresolved stale versions, missing isolation evidence, or missing error detail on failure.

Report: `PASS` or `FAIL` with evidence (exit code value, key output snippets).
