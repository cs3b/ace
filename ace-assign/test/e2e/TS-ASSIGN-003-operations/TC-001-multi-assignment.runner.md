# Goal 1 — Multi-Assignment Operator Flow

## Goal

Validate public multi-assignment operations: create two assignments, list them,
switch selection, and use explicit `--assignment` targeting without mutating
selection unexpectedly.

## Workspace

Save output to `results/tc/01/`.

## Constraints

- Create two assignments from:
  - `fixtures/multi/job-a.yaml`
  - `fixtures/multi/job-b.yaml`
- Capture both assignment IDs.
- Verify `ace-assign list --all` shows both assignments.
- Select assignment A and show status via active-context call.
- Query assignment B via explicit `--assignment <id>` and verify that explicit targeting does not silently change selected assignment.
- Clear selection and verify explicit targeting still works for both IDs.
- All artifacts must come from real tool execution.
