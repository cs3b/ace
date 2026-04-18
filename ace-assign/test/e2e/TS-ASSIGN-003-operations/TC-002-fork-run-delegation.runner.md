# Goal 2 — Fork-Run Delegated Subtree

## Goal

Exercise scoped fork delegation with `ace-assign fork-run --assignment <id>@<root>`
and verify user-visible subtree behavior.

## Workspace

Save output to `results/tc/02/`.

## Constraints

- Create assignment from `fixtures/fork/job.yaml` and capture assignment ID.
- Capture baseline unscoped status and scoped subtree status for `@020`.
- Run `ace-assign fork-run --assignment "<id>@020"` and capture output.
- After command returns, capture scoped and unscoped status again.
- Acceptable outcomes:
  - subtree reached terminal completion, OR
  - command reported explicit provider/tool unavailability while preserving assignment integrity.
- In both outcomes, evidence must show scoped targeting behavior and no silent mutation outside intended scope.
- All artifacts must come from real tool execution.
