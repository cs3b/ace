# Goal 3 — Discovery to Listing Workflow

## Goal

Use the public CLI flow discovered in Goal 1 to browse available resources with `ace-nav list` and confirm list output is actionable for later resolve/create operations.

## Workspace

Save all output to `results/tc/03/`.

Capture artifacts:
- `results/tc/03/list.stdout`, `.stderr`, `.exit` — output from `ace-nav list 'wfi://*'`
- `results/tc/03/list-tree.stdout`, `.stderr`, `.exit` — output from `ace-nav list wfi:// --tree`

## Constraints

- Use `ace-nav list` with protocol patterns discovered in Goal 1.
- Persist the canonical generic capture names exactly as listed above; do not replace `list.*` with protocol-specific names such as `workflow-list.*`.
- Focus on user-facing browse utility (non-empty, actionable listings), not internal priority ordering.
- Keep command usage within public help-documented flags and syntax.
- All artifacts must come from real command execution.
