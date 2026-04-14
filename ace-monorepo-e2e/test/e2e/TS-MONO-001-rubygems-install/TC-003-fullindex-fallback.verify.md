# Goal 3 — Full-Index Fallback Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Core artifacts captured** — `results/tc/03/fullindex.exit`, `results/tc/03/fullindex.stdout`, and `results/tc/03/bundle-env.stdout` all exist.
2. **Install path isolation** — `results/tc/03/bundle-env.stdout` includes the sandbox Gemfile path and does not indicate `/home/mc/ace/Gemfile`.
3. **Install command result** — `results/tc/03/fullindex.exit` is numeric.
4. **Version check artifact exists** — `results/tc/03/version-check.exit` and `results/tc/03/version-check.stdout` exist when the install path reaches the post-install validation step.
5. **Success evidence** — If exit code is `0`:
   - `results/tc/03/bundle-list.stdout` exists and mentions at least one `ace-*` gem.
   - `results/tc/03/version-check.exit` is either `0`, or non-zero with explicit remote lookup / propagation evidence in `version-check.stdout` or `version-check.stderr`.
   - A non-zero version check is supporting evidence only; it does not fail the scenario if the isolated full-index install itself succeeded and installed the expected `ace-*` gems.
6. **Failure evidence** — If exit code is non-zero, `fullindex.stdout` should contain error details.

## Verdict

- **PASS**: All required artifacts are captured and evidence is consistent with the exit code, isolated install path, and installed `ace-*` gems. Remote propagation lag recorded by the freshness check is acceptable supporting evidence.
- **FAIL**: Missing artifacts, missing isolation evidence, missing installed gems after a successful install, or missing error detail on failure.

Report: `PASS` or `FAIL` with evidence (exit code value, key output snippets).
