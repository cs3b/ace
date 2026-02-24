# Goal 2 — Workflow Lifecycle Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Assignment created** — `create.exit` contains `0`. `create.stdout` mentions assignment info and first phase.
2. **Structure correct** — `structure.stdout` shows assignment.yaml, phases/, reports/ directories. Three phase files with .ph.md extension exist.
3. **Phase completion** — `report-analyze.exit` is `0`. Phase 010 marked done (not "completed"), report file at reports/010-analyze.r.md.
4. **Failure handling** — `fail-implement.exit` is `0`. `status-stalled.stdout` shows no current phase (queue stalled). Report rejected on stalled queue.
5. **Dynamic phase** — `add-dynamic.exit` is `0`. Dynamic phase auto-activated with added_by: dynamic.
6. **Retry mechanics** — `retry.exit` is `0`. Retry phase created as pending, does not change current phase.
7. **Workflow completion** — `status-final.stdout` shows "Assignment completed!" with all phases terminal (4 done + 1 failed).

## Verdict

- **PASS**: All lifecycle stages produce expected artifacts — creation, completion, failure, dynamic add, retry, and final completion.
- **FAIL**: Any lifecycle stage missing evidence or producing wrong state.

Report: `PASS` or `FAIL` with evidence (exit codes, state transitions, file citations).
