# Goal 3 — Display and Audit Trail

## Goal

Verify status displays tree structure with hierarchy indicators, and audit trail metadata is correctly populated for child injection, sibling injection, renumbering, and dynamic adds.

## Workspace

Save all output to `results/tc/03/`. Required artifact:
- `results/tc/03/` — display and audit-trail evidence

## Constraints

### Tree Display
- Create assignment from `display/job-tree.yaml`.
- Add children: a-subtask-1 and a-subtask-2 under 010, b-subtask-1 under 020.
- Capture status output as `status-tree.*`. Verify all 5 steps displayed.
- Verify hierarchical display indicators (tree characters: pipe, tee, elbow) and nested step numbers (010.01, 010.02, 020.01).

### Audit Trail
- Clean cache, create assignment from `display/job-tree.yaml`.
- Step files are markdown files under `"$CACHE_BASE/<assignment-id>/steps/"` with `.st.md` extension (not `.yaml`).
- Derive `<assignment-id>` from real command output and include it in your audit evidence notes.
- For metadata checks, read the concrete step files by number prefix, e.g.:
  - child: `010.01-*.st.md`
  - injected sibling: `010.02-*.st.md` immediately after sibling injection
  - renumbered target: `010.03-*.st.md` after renumbering
- Artifact mapping is strict and must not be swapped:
  - `child-of-metadata.stdout` must contain metadata from `010.01-*.st.md`
  - `injected-after-metadata.stdout` must contain metadata from `010.02-*.st.md` after sibling injection
  - `renumbered-metadata.stdout` must contain metadata from `010.03-*.st.md` after renumbering, with at least stable fields (`name`, `status`, `added_by`) and numbering evidence aligned with status snapshots
  - `dynamic-metadata.stdout` must contain metadata from dynamic step file and include `added_by: dynamic`
- Capture renumbered metadata before marking parent done / adding dynamic step. Do not overwrite `renumbered-metadata.stdout` afterward.
- Add child under 010 (`add --after 010 --child`). Verify `added_by: child_of:010` and `parent: "010"`.
- Add another child, then inject sibling after first child. Verify `added_by: injected_after:010.01`.
- Verify renumbering occurred via status snapshots and updated file numbering.
- Mark parent done, then add dynamic step using plain add (NO `--after`, NO `--child`):
  - `ace-assign add "dynamic-step" --assignment "<assignment-id>"`
  - This step must create a top-level dynamic step (e.g., `011-*.st.md`) with `added_by: dynamic`.
- If `--after` is used for this step, the step is injection (`added_by: injected_after:*`) and does not satisfy dynamic audit.
- If expected metadata is missing, first verify file path/extension/assignment-id correctness before concluding failure.
- Capture all four metadata artifacts. Missing any of them is a test failure.
- All artifacts must come from real tool execution.
