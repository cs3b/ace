# Goal 3 - Stubbed-tools deterministic success path

## Goal

Run the CLI with minimal provider stubs in an isolated PATH and capture deterministic success-path behavior.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/stubbed-tools.stdout`, `.stderr`, `.exit` from:
  - `RUBY_BIN="$(command -v ruby)" && env PATH="$PWD/tc03-stubs:/usr/bin:/bin" "$RUBY_BIN" ./ace-llm-providers-cli/exe/ace-llm-providers-cli-check`

Preparation:
- Create `tc03-stubs` and keep it isolated to this test case.
- Create executable provider stubs in `tc03-stubs` before invocation:
  - `agy`: supports `--help` with exit `0`
  - `claude`: supports `--version` and prints a Claude-like version line
  - `codex`: supports `--version` and `--help` with exit `0`
  - `opencode`: supports `--version` and prints a version line
  - `codex-oss`: supports `--version` and prints a `codex`-containing version line
- Keep stubs minimal; avoid emulating broader provider behavior.

## Constraints

- Keep stub logic minimal and deterministic.
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
