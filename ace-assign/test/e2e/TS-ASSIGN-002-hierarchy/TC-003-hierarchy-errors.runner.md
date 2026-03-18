# Goal 3 — Hierarchy Errors

## Goal

Test error handling for hierarchy operations: (1) attempt to finish a parent step by number after child injection has made it pending rather than active, (2) attempt `add --after` with an invalid step number — verify error showing available steps.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/create.stdout`, `.exit` — assignment creation
- `results/tc/03/add-children.stdout` — child step addition
- `results/tc/03/advance-parent.stdout`, `.stderr`, `.exit` — attempt to advance parent
- `results/tc/03/invalid-after.stdout`, `.stderr`, `.exit` — invalid --after reference

## Constraints

### Error 1: Advance Parent with Incomplete Children
- Create assignment from `fixtures/errors/jobs/8qbyjf-job.yml`.
- Add two children under parent 010 (`add --after 010 --child`).
- Attempt to finish the parent explicitly with `ace-assign finish 010 --message fixtures/errors/parent-report.md`.
- Verify: non-zero exit code, error message explains that step `010` is `pending` and cannot be finished because only `in_progress` steps can be completed.

### Error 2: Invalid --after Reference
- Using the same assignment, attempt `ace-assign add test-step --after 999 -i "Test instructions"`.
- Verify: non-zero exit code, error message mentions "not found", error shows available step numbers (010, 020).

- All artifacts must come from real tool execution.
