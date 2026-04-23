# Goal 1 — Workflow Lifecycle

## Goal

Execute the public lifecycle journey end-to-end using documented `ace-assign` commands:
create assignment, complete current step, fail next step, add one recovery step,
retry failed step, and finish the assignment.

## Workspace

Save output to `results/tc/01/`.

## Constraints

- Create the assignment with:
  - `ace-assign create --yaml <path-to-lifecycle-job>`
  - use whichever fixture path exists first:
    - `ace-assign/test/e2e/TS-ASSIGN-001-core-workflow/fixtures/lifecycle/job.yaml`
    - `fixtures/lifecycle/job.yaml`
    - `lifecycle/job.yaml`
- Verify assignment directories and step files exist (`assignment.yaml`, `steps/`, `reports/`).
- Prove user-visible lifecycle transitions via `ace-assign status` snapshots and command outputs:
  - initial paused state and next-step identity,
  - step advancement after first finish,
  - stalled queue after failure,
  - retry insertion,
  - terminal completion.
- Add one recovery step using the public YAML add path:
  - `ace-assign add --yaml <path-to-add-fix-step.yaml> --assignment "<assignment-id>"`
  - use whichever fixture path exists first:
    - `ace-assign/test/e2e/TS-ASSIGN-001-core-workflow/fixtures/lifecycle/add-fix-step.yaml`
    - `fixtures/lifecycle/add-fix-step.yaml`
    - `lifecycle/add-fix-step.yaml`
- Persist the created assignment id to `results/tc/01/assignment-id.txt` and pass
  `--assignment "<assignment-id>"` on every subsequent `status`, `step`, `start`,
  `finish`, `fail`, `add`, and `retry` command in this goal.
- The recovery YAML must use the public `steps[].name` field. If the fixture copy
  is invalid, correct it before rerunning `ace-assign add`.
- The retry command must use the public positional step-ref form:
  `ace-assign retry 020 --assignment "<assignment-id>"`.
- Complete remaining runnable steps and capture finish outputs.
- Use explicit `start` before each `finish` or `fail` transition that requires an
  active step; do not rely on create/add/retry implicitly activating future work.
- After retry succeeds, explicitly `start` the retry step before finishing it, then
  explicitly `start` the final verify step before the terminal finish.
- Final state must show an all-terminal queue with no active step.

## Evidence Guidance

- Prefer end-state artifacts (status snapshots, reports, assignment tree evidence).
- Keep debug captures (`stdout`, `stderr`, `.exit`) as secondary fallback.
- Artifact naming can be consistent but does not need rigid fixture-specific choreography.
