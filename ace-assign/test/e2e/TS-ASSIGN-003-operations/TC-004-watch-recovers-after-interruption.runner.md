# Goal 4 — Watch Recovers After Interruption

## Goal

Exercise the public `ace-assign watch --assignment <id>@<root>` recovery path
after the original fork session context disappears, and capture raw evidence
that recovery comes from assignment state without widening into later siblings.

## Workspace

Save output to `results/tc/04/`.

## Required Artifacts

- `results/tc/04/create.stdout`, `.stderr`, `.exit`
- `results/tc/04/assignment-id.txt`
- `results/tc/04/status-before.stdout`, `.stderr`, `.exit`
- `results/tc/04/watch-recover.stdout`, `.stderr`, `.exit`
- `results/tc/04/status-after.stdout`, `.stderr`, `.exit`

## Constraints

- Create the assignment from `fixtures/watch-recovery/job.yaml`.
- Persist the created assignment ID to `results/tc/04/assignment-id.txt`.
- Prepare the fixture so subtree `010` is the watched recovery scope and its
  assignment state remains non-terminal when watch begins.
- Explicitly activate subtree `010` before invoking watch so the watcher sees an
  active scoped root with nested fork work still pending inside that subtree.
- Simulate stale or disappeared prior session telemetry using the assignment's
  own `.ace-local/assign/<id>/...` metadata before invoking watch.
- Capture scoped status with `ace-assign status --assignment "<id>@010"` before
  invoking the watcher.
- Run `ace-assign watch --assignment "<id>@010"` and capture the raw command output.
- Capture scoped status again with `ace-assign status --assignment "<id>@010"`
  after watch returns.
- The watcher must remain scoped to `@010`; do not accept evidence that widens
  into later parent siblings.

## Evidence Expectations

- `watch-recover.stdout` should show watcher-visible startup for `@010` and a
  recovery message driven from assignment state.
- `watch-recover.stdout` must not rely on callback text alone as completion
  proof.
- `status-after.stdout` should show subtree `010` reached a coherent later
  state (complete or stopped at its inline/manual boundary) without demonstrating
  unrelated later sibling execution.
