# Goal 3 - Stubbed-tools deterministic success path

## Goal

Run the CLI with sandbox stub binaries for all providers and capture deterministic success-path behavior.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/stubbed-tools.stdout`, `.stderr`, `.exit` from:
  - `PATH="$PWD/tools:$PATH" ./ace-llm-providers-cli/exe/ace-llm-providers-cli-check`

Preparation:
- Create executable stubs in `tools/` before invocation:
  - `tools/claude` should print a Claude-like version string for `--version`
  - `tools/codex` should exit `0` for `--version` and `--help`
  - `tools/opencode` should print a version for `--version`
  - `tools/codex-oss` should print a `codex`-containing version for `--version`
- Remove or override any no-tools `tools/which` shim so provider stubs are discoverable.

## Constraints

- Keep stub logic minimal and deterministic.
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
