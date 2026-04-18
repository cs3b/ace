# Goal 2 - No-tools deterministic path

## Goal

Run the CLI with a controlled minimal PATH that exposes Ruby but no provider CLIs, and capture failure-path behavior when provider CLIs are
not discoverable.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/no-tools.stdout`, `.stderr`, `.exit` from:
  - `RUBY_BIN="$(command -v ruby)" && mkdir -p results/tc/02/bin && ln -sf "$RUBY_BIN" results/tc/02/bin/ruby && env -i PATH="$PWD/results/tc/02/bin" HOME="$PWD/results/tc/02/home" ruby ./ace-llm-providers-cli/exe/ace-llm-providers-cli-check`

Preparation:
- Create `results/tc/02/home` before invocation.
- The only PATH shim allowed is the Ruby shim needed to execute the binary under test.
- Do not add any provider stubs for this goal.

## Constraints

- Do not call external provider CLIs directly.
- Do not use helper-command interception (no custom `which` shim).
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
