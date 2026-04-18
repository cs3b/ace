# Goal 1 — Workflow Lifecycle Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/01/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Assignment creation** — evidence shows successful create command and assignment identity.
2. **Lifecycle transitions** — evidence shows: first step completion, next-step failure, stalled queue behavior, and recovery-step insertion.
3. **Retry behavior** — evidence shows retry command succeeded and retry step entered queue without corrupting progression.
4. **Completion flow** — evidence shows remaining runnable steps were completed successfully.
5. **Terminal state** — final status evidence shows no active step and no pending work. A retained failed count is allowed when retry history remains in the queue, as long as the assignment is user-visible `completed` and the remaining runnable steps reached terminal completion.

## Verdict

- **PASS**: The lifecycle journey is demonstrated from create to terminal completion with correct user-visible transitions, including retry history that may remain visible in final status.
- **FAIL**: One or more required lifecycle stages lacks evidence or shows contradictory queue behavior.

Report: `PASS` or `FAIL` with evidence (status transitions and command captures).
