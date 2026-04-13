# Goal 2 — Fork Context

## Goal

Test ace-assign fork context handling: create an assignment with mixed regular and fork-context steps, verify regular steps show raw instructions while fork steps show structured fork instructions. Complete all steps through to assignment completion.

## Workspace

Save all output to `results/tc/02/`. Required artifact:
- `results/tc/02/` — fork-context execution evidence

## Constraints

- Create assignment from `fork/steps/8pny9s-job.yml`.
- Verify fork context parsed into step files (implement and document have `context: fork`; prepare and verify do not).
- Capture regular status (`status.regular.*`) while 010 is active; it should show raw "Instructions:" content.
- Finish 010 with `fork/prepare-report.md`, then capture fork step status (`status.fork.*`) while 020 is active.
- Fork step evidence should include structured sections from instructions (for example "Onboard", "Work", "Report").
- Complete all 4 steps using fixture reports (`fork/implement-report.md`, `fork/verify-report.md`, `fork/document-report.md`), verifying transitions between regular and fork contexts.
- Capture a regular transition snapshot after finishing 020 (`status.back-to-regular.*`).
- Final status capture (`status.final.*`) shows terminal completion with all 4 steps done.
- All artifacts must come from real tool execution.
