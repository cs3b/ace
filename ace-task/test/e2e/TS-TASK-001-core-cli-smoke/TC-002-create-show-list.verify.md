# Goal 2 - Create, Show, and List Lifecycle Verification

## Injected Context

The verifier receives the `results/` directory tree and sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm `.ace-tasks` contains a new task spec file.
2. Confirm captures for create/list/show exist under `results/tc/02/`.
3. Use stderr/exit only as fallback.

1. `create.exit`, `list.exit`, and `show.exit` are all `0`.
2. `task-ref.txt` is non-empty and `show.stdout` contains the same ref.
3. `list.stdout` includes the created task title or ref.
4. `task-files.txt` lists at least one `.s.md` file under `.ace-tasks/`.

## Verdict

- **PASS**: Task is created, discoverable by list/show, and present on disk.
- **FAIL**: Any command fails, ref extraction fails, or no task spec exists on disk.
