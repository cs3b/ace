# Goal 2 — Task Creation

## Goal

Follow quick-start section 2 ("Draft a task from the idea") and verify that `ace-task` creates a task spec, returns success, and can be shown by its resolved ID using the current CLI contract.

## Workspace

Save all output to `results/tc/02/`.

## Steps

1. Run task create and capture execution evidence.
2. Enumerate task specs and resolve the newest path into `results/tc/02/spec-path.txt`.
3. Derive the canonical task ID from the created spec path:
   - extract the basename without the trailing `.s.md`
   - then extract only the canonical task ref prefix matching `^[a-z0-9]+\.t\.[a-z0-9]+`
   - for example, from `8r8.t.0ah-implement-webhook-retry-with-exponential-backoff`, write `8r8.t.0ah`
   - write that exact canonical ref to `results/tc/02/task-id.txt`
4. Show the created task with full output capture using that exact task ID:
   - `ace-task show "$task_id" --content`
5. Capture normalized task tree snapshot:
   - `find .ace-tasks -type f -name '*.s.md' | sort > results/tc/02/tree.stdout`

## Constraints

- Use only `ace-task` commands as documented in `docs/quick-start.md`.
- Do not create files manually.
- Keep all output under `results/tc/02/`.
- `task-id.txt` must be the single source of truth for later lookup; do not pass the full slugified filename to `show`.
