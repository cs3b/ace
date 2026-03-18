# Goal 2 — Workflow Lifecycle

## Goal

Test the full ace-assign workflow lifecycle: create an assignment from `fixtures/lifecycle/job.yaml`, verify directory structure and step files, display status, complete steps with reports, handle a failure (queue stall), add a dynamic step, retry the failed step, and complete the workflow.

## Workspace

Save all output to `results/tc/02/`. Capture evidence at each stage:
- `results/tc/02/create.stdout`, `.exit` — assignment creation
- `results/tc/02/structure.stdout` — directory structure listing
- `results/tc/02/status-initial.stdout` — initial status
- `results/tc/02/report-analyze.stdout`, `.exit` — first step completion
- `results/tc/02/fail-implement.stdout`, `.exit` — failure handling
- `results/tc/02/status-stalled.stdout` — stalled queue status
- `results/tc/02/add-dynamic.stdout`, `.exit` — dynamic step addition
- `results/tc/02/retry.stdout`, `.exit` — retry mechanics
- `results/tc/02/status-final.stdout` — final completion status

## Constraints

- Create assignment from `fixtures/lifecycle/job.yaml`.
- After creation, verify assignment.yaml, steps/, reports/ directories exist.
- Verify 3 step files (010-analyze, 020-implement, 030-verify) with .st.md extension.
- First step should be in_progress with skill field and array instructions.
- Complete analyze step with `fixtures/lifecycle/report.md`, verify step 010 marked done and 020 advances.
- Mark 020 as failed via `ace-assign fail -m "..."`, verify queue stalls.
- Verify report is rejected on stalled queue.
- Add dynamic step "fix-issue" (auto-activates on stalled queue), complete it.
- Retry failed step 020 (should NOT change current step).
- Complete verify step, then complete retry step, verify assignment completion.
- All artifacts must come from real tool execution.
