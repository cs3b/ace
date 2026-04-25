# Goal 3 — Watch Sequential Continuation

## Goal

Exercise the public `ace-assign watch --assignment <id>` path on a retained
operations fixture and capture raw evidence that the watcher advances across
multiple fork roots before stopping at an inline/manual boundary.

## Workspace

Save output to `results/tc/03/`.

## Required Artifacts

- `results/tc/03/create.stdout`, `.stderr`, `.exit`
- `results/tc/03/assignment-id.txt`
- `results/tc/03/status-before.stdout`, `.stderr`, `.exit`
- `results/tc/03/watch.stdout`, `.stderr`, `.exit`
- `results/tc/03/status-after.stdout`, `.stderr`, `.exit`

## Constraints

- Create the assignment from `fixtures/watch/job.yaml`.
- Persist the created assignment ID to `results/tc/03/assignment-id.txt`.
- Capture `ace-assign status --assignment "<id>"` before invoking watch.
- Run `ace-assign watch --assignment "<id>"` and capture the raw command output.
- Capture `ace-assign status --assignment "<id>"` again after watch returns.
- Acceptable completion boundary:
  - the watcher advanced across pending fork roots in order, then
  - stopped cleanly because only inline/manual work remained, OR
  - completed the full assignment if the fixture no longer leaves a manual tail.
- Raw watch output is primary evidence. Do not replace it with paraphrased
  summaries.

## Evidence Expectations

- `watch.stdout` should expose watcher-visible continuation messages such as
  startup, launching next fork roots, waiting/recovery if encountered, and the
  final completion/stop summary.
- `status-before.stdout` should show the assignment still has pending fork work.
- `status-after.stdout` should show that the earlier fork roots are no longer
  pending and that the queue moved forward coherently.
