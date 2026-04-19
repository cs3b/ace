# Goal 2 - Create, Show, and List Lifecycle Verification

## Injected Context

The verifier receives the `results/` directory tree and sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm the sandbox root `.ace-tasks` contains a new task spec file.
2. Confirm captures for create/list/show exist under `results/tc/02/`.
3. Confirm `results/tc/02/resolved-ref.txt` exists and contains a non-empty short ref.
4. Use runner observations to disambiguate which short ref was shown.
5. Use stderr/exit only as fallback.

1. `create.exit`, `list.exit`, and `show.exit` are all `0`.
2. `create.stdout`, `list.stdout`, and `show.stdout` consistently reference the created task title and a full short ref.
3. `resolved-ref.txt` value appears in `show.stdout`.
4. `task-files-after-create.txt` shows the created task existed as a non-archived `.s.md` task file immediately after creation.

## Verdict

- **PASS**: Task is created, discoverable by list/show, and present on disk.
- **FAIL**: Any command fails, the created task is not discoverable by list/show, or immediate post-create task-file evidence is missing.
