# Goal 3 — Watch-Driven Sequential Fork Continuation

## Goal

Exercise `ace-assign watch --assignment <id>` on an assignment that contains
multiple sequential fork subtrees followed by inline work, and verify that one
watch invocation advances through the fork steps without requiring manual
re-invocation between them.

## Workspace

Save output to `results/tc/03/`.

## Constraints

- Create assignment from `fixtures/watch/job.yaml` and capture assignment ID.
- Capture baseline status before running `watch`.
- Run `ace-assign watch --assignment "<id>"` and capture output.
- Capture post-watch status after the command returns.
- Acceptable outcome:
  - both sequential fork subtrees are terminal, and
  - the next runnable step is the inline/manual tail step or the assignment is complete.
- All artifacts must come from real tool execution.
