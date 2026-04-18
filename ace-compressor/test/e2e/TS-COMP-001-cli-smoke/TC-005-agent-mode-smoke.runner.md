# Goal 5 - Agent mode smoke

## Goal

Verify the documented `--mode agent` workflow runs through the packaged CLI and emits agent-mode output.

## Workspace

Save artifacts to `results/tc/05/`.

Actions:
1. Create `results/tc/05/input.md` with:
   - one top-level heading
   - one summary paragraph
   - one small bullet list (3 items)
2. Run `ace-compressor results/tc/05/input.md --mode agent --format stdio`.
3. Capture stdout/stderr/exit to:
   - `results/tc/05/agent.stdout`
   - `results/tc/05/agent.stderr`
   - `results/tc/05/agent.exit`

## Constraints

- Do not use library imports.
- Keep all writes under `results/tc/05/`.
