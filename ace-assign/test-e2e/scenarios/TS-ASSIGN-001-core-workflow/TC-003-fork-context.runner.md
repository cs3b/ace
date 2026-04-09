# Goal 3 — Fork Context

## Goal

Test ace-assign fork context handling: create an assignment with mixed regular and fork-context steps, verify regular steps show raw instructions while fork steps show Task tool format with working directory and assignment ID. Complete all steps through to assignment completion.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/create.stdout`, `.exit` — assignment creation
- `results/tc/03/status-regular.stdout` — regular step (prepare) status
- `results/tc/03/status-fork.stdout` — fork step (implement) status with Task tool format
- `results/tc/03/status-back-to-regular.stdout` — transition back to regular step (verify)
- `results/tc/03/status-second-fork.stdout` — second fork step (document)
- `results/tc/03/status-final.stdout` — assignment completion

## Constraints

- Create assignment from `fixtures/fork/job.yaml`.
- Verify fork context parsed into step files (implement and document have `context: fork`; prepare and verify do not).
- Regular step status shows raw "Instructions:" header, not Task tool format.
- Fork step status shows "Context: fork", "forked context", "Task tool" mention.
- Fork prompt includes "Working directory:", "Assignment:", "Prompt for forked agent".
- Prompt contains step content sections (Onboard, Work, Report).
- Complete all 4 steps using fixture reports, verify transitions between regular and fork contexts.
- Final status shows "Assignment completed!" with all 4 steps done.
- All artifacts must come from real tool execution.
