# Goal 3 — Fork Context Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Assignment created** — `create.exit` contains `0`.
2. **Regular status captured** — `status-regular.stdout` captures the active regular step and includes raw instructions.
3. **Fork-phase status captured** — `status-fork.stdout` captures the later phase of the assignment and includes the active-step instructions for that phase. If fork-specific presentation is present, it should be internally consistent, but it is not required for pass.
4. **Transition evidence** — Additional transition snapshots are optional and not required for pass.
5. **Workflow completion** — `status-final.stdout` shows "Assignment completed!" with all 4 steps done.

## Verdict

- **PASS**: The scenario captures regular and later-phase status output and the assignment completes successfully.
- **FAIL**: Status captures are missing or the workflow does not complete.

Report: `PASS` or `FAIL` with evidence (content snippets from status captures).
