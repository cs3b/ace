# Goal 3 — Display and Audit Trail

## Goal

Verify hierarchy display (`status --mode full`) and audit metadata for child,
injected-sibling, renumbered, and dynamic step mutations.

## Workspace

Save output to `results/tc/03/`.

Required captures:
- `results/tc/03/create-tree.stdout`, `results/tc/03/create-tree.stderr`, `results/tc/03/create-tree.exit`
- `results/tc/03/status-tree-full.stdout`, `results/tc/03/status-tree-full.stderr`, `results/tc/03/status-tree-full.exit`
- `results/tc/03/create-audit.stdout`, `results/tc/03/create-audit.stderr`, `results/tc/03/create-audit.exit`
- `results/tc/03/add-audit-child.stdout`, `results/tc/03/add-audit-child.stderr`, `results/tc/03/add-audit-child.exit`
- `results/tc/03/status-audit-child-full.stdout`, `results/tc/03/status-audit-child-full.stderr`, `results/tc/03/status-audit-child-full.exit`
- `results/tc/03/add-audit-sibling.stdout`, `results/tc/03/add-audit-sibling.stderr`, `results/tc/03/add-audit-sibling.exit`
- `results/tc/03/status-audit-sibling-full.stdout`, `results/tc/03/status-audit-sibling-full.stderr`, `results/tc/03/status-audit-sibling-full.exit`
- `results/tc/03/add-audit-top.stdout`, `results/tc/03/add-audit-top.stderr`, `results/tc/03/add-audit-top.exit`
- `results/tc/03/status-audit-final-full.stdout`, `results/tc/03/status-audit-final-full.stderr`, `results/tc/03/status-audit-final-full.exit`
- `results/tc/03/step-files/` (optional)

## Constraints

### Tree Display
- Create assignment with `ace-assign create --yaml ./fixtures/display/job-tree.yaml`.
- Use `add --yaml` for all step insertions in this goal.
- Add children under `010` and `020`, then capture `ace-assign status --mode full`.
- Evidence must show nested numbering and hierarchy structure.

### Audit Trail
- Create a fresh assignment and perform:
  - child insertion,
  - sibling injection after child,
  - top-level dynamic add (no `--after`, no `--child`).
- Capture status snapshots that show numbering and mutation outcomes.
- Prefer CLI-visible evidence first (`status --mode full`, `step`, command output).
- If needed, copy representative step files into `results/tc/03/step-files/` as fallback evidence for metadata fields like `added_by` and `parent`.

## Evidence Guidance

- Primary oracle: user-visible CLI output/state.
- Fallback oracle: copied canonical step files when metadata is not fully exposed by CLI output.
