# Goal 2 — Task Creation Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) as fallback.

1. **Create command executed successfully** — `results/tc/02/create.exit` is numeric and `0`.
2. **Task spec is captured** — `results/tc/02/spec-path.txt` exists and is a path to a `.s.md` file.
3. **Show works for created task** — `results/tc/02/show.exit` is numeric and `0`.
4. **Cross-check ID consistency** — `results/tc/02/task-id.txt` value appears in `results/tc/02/show.stdout`.
5. **Task details preserved** — `results/tc/02/show.stdout` contains "webhook" or "retry" and either "exponential" or "backoff".
6. **Task structure evidence** — `results/tc/02/tree.stdout` lists at least one `.ace-tasks` `.s.md` file.

## Verdict

- **PASS**: Task create/show flow succeeds and evidence is internally consistent.
- **FAIL**: Missing artifacts, non-zero create/show exit, missing spec path, or output inconsistency.

Report: `PASS` or `FAIL` with evidence (artifact file names and key snippets).
