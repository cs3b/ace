# Goal 2 — Fork Context

## Goal

Test ace-assign fork context handling: create an assignment with mixed regular and fork-context steps, verify regular steps show raw instructions while fork steps show structured fork instructions. Complete all steps through to assignment completion.

## Workspace

Save all output to `results/tc/02/`. Required artifact:
- `results/tc/02/` — fork-context execution evidence

## Constraints

- Create assignment from `fork/steps/8pny9s-job.yml`.
- Verify fork context parsed into step files (implement and document have `context: fork`; prepare and verify do not).
- Capture artifacts in this exact order so each transition is unambiguous:
  1. `status.regular.*` while 010 is active; it should show raw "Instructions:" content.
  2. `finish.010.*` using `fork/prepare-report.md`.
  3. `status.fork.*` immediately after `finish.010`, while 020 is active.
  4. `finish.020.*` using `fork/implement-report.md`.
  5. `status.back-to-regular.*` immediately after `finish.020`, while 030 is active.
  6. `finish.030.*` using `fork/verify-report.md`.
  7. `finish.040.*` using `fork/document-report.md`.
  8. `status.final.*` after all four steps are complete.
- Fork step evidence should include structured sections from instructions (for example "Onboard", "Work", "Report").
- `finish.010.stdout` and `finish.020.stdout` are required transition artifacts, not optional debug output.
- Do not reuse an earlier status capture for `status.fork.*` or `status.back-to-regular.*`; capture each immediately after the named `finish` command.
- Final status capture (`status.final.*`) shows terminal completion with all 4 steps done.
- All artifacts must come from real tool execution.
