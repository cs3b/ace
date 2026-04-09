# Goal 3 — Hierarchy Errors

## Goal

Test error handling for hierarchy operations using the current CLI contract: (1) attempt to finish with an invalid positional-step plus `--assignment` combination, (2) attempt `add --after` with an invalid step number.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/create.stdout`, `.exit` — assignment creation
- `results/tc/03/add-children.stdout` — child step addition
- `results/tc/03/advance-parent.stdout`, `.stderr`, `.exit` — invalid finish invocation output
- `results/tc/03/invalid-after.stdout`, `.stderr`, `.exit` — invalid --after reference

## Constraints

### Error 1: Invalid finish invocation
- Create assignment from `fixtures/errors/jobs/8qbyjf-job.yml`.
- Add two children under parent 010 (`add --after 010 --child`).
- Attempt to finish with `ace-assign finish --assignment assignment 010`.
- Verify: non-zero exit code, error message explains that positional `STEP` cannot be used together with `--assignment`.

### Error 2: Invalid --after Reference
- Using the same assignment, attempt `ace-assign add "test-step" --assignment assignment --after 999`.
- Verify: non-zero exit code, error message mentions the requested anchor step was not found or otherwise rejected.

- All artifacts must come from real tool execution.
