# Goal 4 — Display and Audit Trail

## Goal

Verify status displays tree structure with hierarchy indicators, and audit trail metadata is correctly populated for child injection, sibling injection, renumbering, and dynamic adds.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/create-tree.stdout`, `.exit` — tree display assignment creation
- `results/tc/04/add-tree-children.stdout` — children added under two parents
- `results/tc/04/status-tree.stdout` — hierarchical status display
- `results/tc/04/create-audit.stdout`, `.exit` — audit trail assignment creation
- `results/tc/04/audit-steps-dir.txt` — resolved steps directory for audit-trail lookups
- `results/tc/04/child-of-metadata.stdout` — child_of audit trail evidence
- `results/tc/04/inject-sibling.stdout` — sibling injection output
- `results/tc/04/assignment-id-audit.txt` — captured assignment ID for audit lookups
- `results/tc/04/injected-after-metadata.stdout` — injected_after audit trail
- `results/tc/04/renumbered-metadata.stdout` — renumbered_from/renumbered_at audit trail
- `results/tc/04/dynamic-metadata.stdout` — dynamic add audit trail

## Constraints

### Tree Display
- Create assignment from `fixtures/display/job-tree.yaml`.
- Add children: a-subtask-1 and a-subtask-2 under 010, b-subtask-1 under 020.
- Capture status output. Verify all 5 steps displayed.
- Verify hierarchical display indicators (tree characters: pipe, tee, elbow) and nested step numbers (010.01, 010.02, 020.01).

### Audit Trail
- Clean cache, create assignment from `fixtures/display/job-audit.yaml`.
- Step files are markdown files under `"$CACHE_BASE/<assignment-id>/steps/"` with `.st.md` extension (not `.yaml`).
- Derive `<assignment-id>` from real command output and/or `results/tc/04/assignment-id-audit.txt` captured during this TC.
- Resolve the audit `steps/` directory once and save it to `audit-steps-dir.txt`; use that exact directory for all metadata reads.
- For metadata checks, read the concrete step files by number prefix, e.g.:
  - child: `010.01-*.st.md`
  - injected sibling: `010.02-*.st.md` immediately after sibling injection
  - renumbered target: `010.03-*.st.md` after renumbering
- Artifact mapping is strict and must not be swapped:
  - `child-of-metadata.stdout` must contain metadata from `010.01-*.st.md`
  - `injected-after-metadata.stdout` must contain metadata from `010.02-*.st.md` after sibling injection
  - `renumbered-metadata.stdout` must contain metadata from `010.03-*.st.md` and include `renumbered_from`/`renumbered_at`
  - `dynamic-metadata.stdout` must contain metadata from dynamic step file (`011-*.st.md` in this fixture flow) and include `added_by: dynamic`
- Capture renumbered metadata before marking parent done / adding dynamic step. Do not overwrite `renumbered-metadata.stdout` afterward.
- Capture real step-file metadata into the named artifacts. Do not use `ace-assign add` stdout as metadata evidence.
- Do not write empty placeholder files. If a metadata lookup fails, stop that lookup with explicit failure output instead of leaving an empty artifact.
- Add child under 010 (`add --after 010 --child`). Verify `added_by: child_of:010` and `parent: "010"`.
- Add another child, then inject sibling after first child. Verify `added_by: injected_after:010.01`.
- Verify the renumbered step capture targets the actual shifted child after sibling injection and has `renumbered_from` and `renumbered_at` (ISO8601 format).
- Mark parent done, then add dynamic step using plain add (NO `--after`, NO `--child`):
  - `ace-assign add "dynamic-step" --assignment "<assignment-id>"`
- This step must create a top-level dynamic step (e.g., `011-*.st.md`) with `added_by: dynamic`.
- If `--after` is used for this step, the step is injection (`added_by: injected_after:*`) and does not satisfy dynamic audit.
- For `dynamic-metadata.stdout`, select the new top-level dynamic step by its real step file and `added_by: dynamic`, not by a guessed path that might be stale after renumbering.
- If expected metadata is missing, first verify file path/extension/assignment-id correctness before concluding failure.
- All artifacts must come from real tool execution.
