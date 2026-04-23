# Goal 2 — Fork Context

## Goal

Verify user-visible context transitions between regular and fork steps using public
`status`, `step`, and `finish` commands.

## Workspace

Save output to `results/tc/02/`.

Capture these checkpoint artifacts explicitly:
- `results/tc/02/create.stdout`, `.stderr`, `.exit`
- `results/tc/02/status-regular.stdout`, `.stderr`, `.exit`
- `results/tc/02/step-regular.stdout`, `.stderr`, `.exit`
- `results/tc/02/start-010.stdout`, `.stderr`, `.exit`
- `results/tc/02/finish-010.stdout`, `.stderr`, `.exit`
- `results/tc/02/status-fork.stdout`, `.stderr`, `.exit`
- `results/tc/02/step-fork.stdout`, `.stderr`, `.exit`
- `results/tc/02/start-020.stdout`, `.stderr`, `.exit`
- `results/tc/02/finish-020.stdout`, `.stderr`, `.exit`
- `results/tc/02/status-return.stdout`, `.stderr`, `.exit`
- `results/tc/02/step-return.stdout`, `.stderr`, `.exit`
- `results/tc/02/start-030.stdout`, `.stderr`, `.exit`
- `results/tc/02/finish-030.stdout`, `.stderr`, `.exit`
- `results/tc/02/start-040.stdout`, `.stderr`, `.exit`
- `results/tc/02/finish-040.stdout`, `.stderr`, `.exit`
- `results/tc/02/status-final.stdout`, `.stderr`, `.exit`

## Constraints

- Create the assignment with:
  - `ace-assign create --yaml <path-to-fork-job>`
  - use whichever fixture path exists first:
    - `fork/steps/8pny9s-job.yml`
    - `fixtures/fork/steps/8pny9s-job.yml`
- Capture checkpoints that prove the transition model:
  1. Regular step view before any step has started via `status-regular.*` and `step-regular.*`.
  2. Explicitly activate each pending step before finishing it via `start-010.*`, `start-020.*`, `start-030.*`, and `start-040.*`.
  3. Fork step view while paused on the next fork child after finishing the regular onboarding step via `status-fork.*` and `step-fork.*`.
  4. Return-to-regular view while paused on the next regular step after finishing the first fork step via `status-return.*` and `step-return.*`.
  5. Final completion after finishing the remaining started steps via `status-final.*` after `finish-040.*`.
- Verify fork-context parsing is reflected in step behavior (regular instructions vs structured fork guidance).
- Treat `status-regular.*`, `status-fork.*`, and `status-return.*` as paused/next-step checkpoints unless a step was just started.
- All artifacts must come from real tool execution.
