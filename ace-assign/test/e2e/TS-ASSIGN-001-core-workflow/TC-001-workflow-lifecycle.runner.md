# Goal 1 — Workflow Lifecycle

## Goal

Test the full ace-assign workflow lifecycle: create an assignment from `lifecycle/job.yaml`, verify directory structure and step files, display status, complete steps with reports, handle a failure (queue stall), add a dynamic step, retry the failed step, and complete the workflow.

## Workspace

Save all output to `results/tc/01/`. Required artifact:
- `results/tc/01/` — workflow lifecycle execution evidence

## Constraints

- Create assignment from whichever fixture path exists first:
  - `lifecycle/job.yaml`
  - `fixtures/lifecycle/job.yaml`
- Keep this assignment active when issuing positional finish commands; for cross-assignment targeting use `--assignment` without positional step number.
- After creation, verify assignment.yaml, steps/, reports/ directories exist.
- Verify 3 step files (010-analyze, 020-implement, 030-verify) with .st.md extension.
- First step should be in_progress with skill field and array instructions.
- Complete analyze step with `lifecycle/report.md`, verify step 010 marked done and 020 advances.
- Mark 020 as failed via `ace-assign fail -m "..."`, verify queue stalls.
- Verify report is rejected on stalled queue.
- Add dynamic step "fix-issue" with explicit inline instructions (do not use preset step lookup). Use:
  - `ace-assign add fix-issue --instructions "Fix the stalled implementation issue" --assignment "<assignment-id>"`
- Complete the injected step with `lifecycle/fix-report.md`.
- Retry failed step 020 (should NOT change current step).
- Complete verify step with `lifecycle/verify-report.md`, then complete retry step with `lifecycle/implement-report.md`, and capture each finish command exit/status output.
- Final status must show no active step and an all-done terminal queue (for example "All steps complete!" or "Assignment completed!").
- All artifacts must come from real tool execution.
