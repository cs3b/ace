# Goal 8 — No-Report Public Contract

## Goal

Validate the public `--no-report` contract: run lint without report generation and prove no report directory artifacts are produced.

## Workspace

Save all output to `results/tc/08/`. Capture:
- Command stdout, stderr, and exit code
- The exact command invocation used for this goal
- A short artifact check showing no report path was emitted and no report artifacts were copied

## Constraints

- Use `ace-lint` on the sandbox-root file `valid.rb` with `--no-report`. Do not prefix the path with `fixtures/`.
- Scenario setup already installs deterministic validator shims into the sandbox runtime PATH; use the provided environment as-is.
- Follow the `--no-report` semantics documented in `ace-lint/docs/usage.md`.
- Persist the exact command contract so the verifier can prove the run actually used `--no-report`.
- Do not infer from assumptions; use actual command output and observed filesystem state.
- All artifacts must come from real tool execution, not fabricated.
