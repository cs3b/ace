# Goal 3 — Display and Audit Trail

## Goal

Verify hierarchy display (`status --mode full`) and audit metadata for child,
injected-sibling, renumbered, and dynamic step mutations.

## Workspace

Save output to `results/tc/03/`.

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
