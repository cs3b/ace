# Goal 2 — Task Creation Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Task directory created** — `.ace-tasks/` exists in the sandbox.
2. **Spec file exists** — `results/tc/02/spec-path.txt` contains a path ending in `.s.md`, and that file exists in the sandbox.
3. **Create succeeded** — `results/tc/02/create.exit` contains `0`.
4. **Show works** — `results/tc/02/show.stdout` is non-empty and references the task (mentions "webhook" or "retry" or "backoff").
5. **Tree shows structure** — `results/tc/02/tree.stdout` shows `.ace-tasks/` with at least one subdirectory containing a `.s.md` file.

## Verdict

- **PASS**: Task created successfully, spec file exists, show command displays it.
- **FAIL**: Create failed, spec missing, or show doesn't display the task.

Report: `PASS` or `FAIL` with evidence.
