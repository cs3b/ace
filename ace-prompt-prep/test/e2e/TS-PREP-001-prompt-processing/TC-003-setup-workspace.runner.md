# Goal 3 — Setup Initializes Workspace

## Goal

Run the public setup command (`ace-prompt-prep setup`) and capture evidence that the prompt workspace
is initialized from the documented user path.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `setup.stdout`, `setup.stderr`, `setup.exit` from `ace-prompt-prep setup`
- `workspace-tree.txt` showing `.ace-local/prompt-prep/prompts` contents
- `workspace-main-file.txt` containing `.ace-local/prompt-prep/prompts/the-prompt.md` content

## Constraints

- Use only `ace-prompt-prep setup` for initialization; do not fabricate workspace files manually.
- Validate workspace state from captured filesystem artifacts, not assumptions.
- Keep assertions tied to public docs contract (`ace-prompt-prep/docs/usage.md` file layout).
