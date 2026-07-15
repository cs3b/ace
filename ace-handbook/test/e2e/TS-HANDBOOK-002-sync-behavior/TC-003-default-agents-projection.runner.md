# Goal 3 - Default agents projection includes legacy workflow skills

## Goal

Run the default sync and capture evidence that the neutral `agents` provider receives common workflow skills from the
legacy full-provider target set even when no provider integration gems are installed.

## Workspace

Save artifacts to `results/tc/03/`.

Create an isolated bundle under `results/tc/03/runtime/` from
`ace-handbook/test/e2e/TS-HANDBOOK-002-sync-behavior/fixtures/agents-only/Gemfile`. Set its `GEM_HOME`, `GEM_PATH`,
`BUNDLE_PATH`, and `BUNDLE_BIN` to directories under that runtime root, and use the dedicated sandbox Ruby from
`ACE_E2E_SANDBOX_RUBY_ROOT`. This bundle must contain the local `ace-handbook` and `ace-git-commit` packages plus their
dependencies, without any `ace-handbook-integration-*` gems.

Copy the fixture `project/` directory to `results/tc/03/project/`, initialize it as the command working directory, and
run the generated `ace-handbook` binstub directly with the isolated bundle environment.

Capture:

- `results/tc/03/sync-agents.stdout`, `.stderr`, `.exit` from `ace-handbook sync`
- `results/tc/03/status-agents.stdout`, `.stderr`, `.exit` from `ace-handbook status`
- `results/tc/03/status-codex.stdout`, `.stderr`, `.exit` from `ace-handbook status --provider codex`

## Constraints

- Use only declared scenario tools.
- Do not use the outer monorepo bundle for the three captured `ace-handbook` commands.
- Do not install any `ace-handbook-integration-*` gems in the isolated bundle.
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
