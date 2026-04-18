# Goal 5 — Multi-Task Worktrees Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Creation artifacts exist** — results/tc/05/ contains stdout/exit for create-888.
2. **Creation succeeds** — create-888.exit is 0.
3. **Created task identity is explicit** — create-888.stdout includes task/worktree identity for task 8pp.t.r8x (for example `Task ID: r8x` and a worktree path).
4. **List captures are diagnostic only** — list-all-tasks.stdout and list-full.stdout exist and are non-empty, but final verdict prioritizes successful creation evidence.

## Verdict

- **PASS**: Second task worktree create command succeeds with explicit task/worktree identity evidence, and list artifacts are captured.
- **FAIL**: Creation fails or created task/worktree identity evidence is missing.

Report: `PASS` or `FAIL` with evidence (exit code, create output, and list captures).
