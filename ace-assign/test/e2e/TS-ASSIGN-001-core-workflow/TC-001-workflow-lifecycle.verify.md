# Goal 1 — Workflow Lifecycle Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Assignment created** — Accept `create.exit` or `create.actual.exit` as `0`. Matching stdout mentions assignment info and first step.
2. **Structure correct** — The evidence set under `results/tc/01/` shows assignment creation plus status/report transitions proving assignment directories and step files were created.
3. **Step completion** — Analyze completion is evidenced either by successful `finish.010.exit`/`finish-010.exit` OR by subsequent status/output proving 010 transitioned to done and queue advanced after a valid finish command path.
4. **Failure handling** — Implement failure evidence (`fail.020.exit` or `fail-020.exit`) is `0`; stalled/failed queue behavior is captured by status artifacts and rejected finish evidence (`finish.stalled.exit` or `finish-rejected.exit`).
5. **Dynamic step** — Dynamic step add evidence (`add.fix.exit` or `add-fix.exit`) is `0`, and status output shows injected recovery step activation.
6. **Lifecycle completions executed** — Completion evidence for remaining runnable steps is present and successful (`finish.030.exit` and either `finish.011.exit` or `finish.031.exit` are `0`).
7. **Retry mechanics** — Retry command evidence (`retry-020.exit`) is `0`, and post-retry status evidence shows retry insertion without invalid queue regression.
8. **Workflow completion** — `status.final.stdout` or `status-final.stdout` shows an explicit terminal completion message (for example "All steps complete!" or "Assignment completed!") with all steps terminal.

## Verdict

- **PASS**: All lifecycle stages produce expected artifacts — creation, completion, failure, dynamic add, retry, and final completion.
- **FAIL**: Any lifecycle stage missing evidence or producing wrong state.

Report: `PASS` or `FAIL` with evidence (exit codes, state transitions, file citations).
