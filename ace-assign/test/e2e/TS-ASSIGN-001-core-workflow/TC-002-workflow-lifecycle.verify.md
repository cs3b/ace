# Goal 2 — Workflow Lifecycle Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Assignment created** — `create.exit` contains `0`. `create.stdout` mentions assignment info and first step.
2. **Structure correct** — `structure.stdout` exists and shows `assignment.yaml`, `steps/`, `reports/`, and the three `.st.md` step files.
3. **Step completion** — `report-analyze.exit` is `0`. Step 010 marked done (not "completed"), report file at reports/010-analyze.r.md.
4. **Failure handling** — `fail-implement.exit` is `0`. `status-stalled.stdout` shows no current step (queue stalled). Report rejected on stalled queue.
5. **Dynamic-step branch handled explicitly** — If `add-dynamic.exit` is `0`, dynamic-step activation/completion evidence exists. If `add-dynamic.exit` is non-zero because the preset does not define `fix-issue`, the artifacts must still show the retry path was used instead.
6. **Retry mechanics** — `retry.exit` is `0`. A retry step is created and can be started/completed without regressing the stalled original step.
7. **Lifecycle completions executed** — `finish-verify.exit` and `finish-retry.exit` are `0`. If no dynamic step exists, `finish-dynamic.exit` may be non-zero and is not required for pass.
8. **Workflow completion** — `status-final.stdout` shows an explicit terminal completion message (for example "All steps complete!" or "Assignment completed!"), and the queue ends in a terminal state even if the original failed step remains recorded alongside a completed retry.

## Verdict

- **PASS**: All lifecycle stages produce expected artifacts — creation, completion, failure, dynamic add, retry, and final completion.
- **FAIL**: Any lifecycle stage missing evidence or producing wrong state.

Report: `PASS` or `FAIL` with evidence (exit codes, state transitions, file citations).
