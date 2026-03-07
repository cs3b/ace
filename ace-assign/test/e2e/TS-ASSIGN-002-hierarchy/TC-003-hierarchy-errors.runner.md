# Goal 3 — Hierarchy Errors

## Goal

Test error handling for hierarchy operations: (1) attempt to advance a parent phase with incomplete children — verify error listing incomplete children, (2) attempt `add --after` with an invalid phase number — verify error showing available phases.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/create.stdout`, `.exit` — assignment creation
- `results/tc/03/add-children.stdout` — child phase addition
- `results/tc/03/advance-parent.stdout`, `.stderr`, `.exit` — attempt to advance parent
- `results/tc/03/invalid-after.stdout`, `.stderr`, `.exit` — invalid --after reference

## Constraints

### Error 1: Advance Parent with Incomplete Children
- Create assignment from `fixtures/errors/job.yaml`.
- Add two children under parent 010 (`add --after 010 --child`).
- Attempt to complete parent with `ace-assign finish --message fixtures/errors/parent-report.md`.
- Verify: non-zero exit code, error message mentions "incomplete children", error lists child phase numbers (010.01, 010.02).

### Error 2: Invalid --after Reference
- Using the same assignment, attempt `ace-assign add test-step --after 999 -i "Test instructions"`.
- Verify: non-zero exit code, error message mentions "not found", error shows available phase numbers (010, 020).

- All artifacts must come from real tool execution.
