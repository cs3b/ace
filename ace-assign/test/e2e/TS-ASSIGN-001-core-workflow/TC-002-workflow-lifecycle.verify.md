# Goal 2 — Workflow Lifecycle Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Assignment created** — `create.exit` contains `0`. `create.stdout` mentions assignment info and first step.
2. **Structure correct** — `structure.stdout` shows assignment.yaml, steps/, reports/ directories. Three step files with .st.md extension exist.
3. **Step completion** — `report-analyze.exit` is `0`. Step 010 marked done (not "completed"), report file at reports/010-analyze.r.md.
4. **Failure handling** — `fail-implement.exit` is `0`. `status-stalled.stdout` shows no current step (queue stalled). Report rejected on stalled queue.
5. **Dynamic step** — `add-dynamic.exit` is `0`. Dynamic step auto-activated with added_by: dynamic.
6. **Retry mechanics** — `retry.exit` is `0`. Retry step created as pending, does not change current step.
7. **Workflow completion** — `status-final.stdout` shows "Assignment completed!" with all steps terminal (4 done + 1 failed).

## Verdict

- **PASS**: All lifecycle stages produce expected artifacts — creation, completion, failure, dynamic add, retry, and final completion.
- **FAIL**: Any lifecycle stage missing evidence or producing wrong state.

Report: `PASS` or `FAIL` with evidence (exit codes, state transitions, file citations).
