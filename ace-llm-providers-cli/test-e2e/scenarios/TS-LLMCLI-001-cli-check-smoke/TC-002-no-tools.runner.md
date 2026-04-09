# Goal 2 - No-tools deterministic path

## Goal

Run the CLI with a restricted PATH so provider CLIs are not discoverable and capture failure-path behavior.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/no-tools.stdout`, `.stderr`, `.exit` from:
  - `PATH="$PWD/tools:$PATH" ./ace-llm-providers-cli/exe/ace-llm-providers-cli-check`

Preparation:
- Create `tools/which` shim that returns not-found for provider names and delegates all other lookups:
  - returns exit `1` for `claude`, `codex`, `opencode`, `codex-oss`
  - otherwise executes `/usr/bin/which "$@"`
- Ensure `tools/which` is executable.

## Constraints

- Do not call external provider CLIs directly.
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
