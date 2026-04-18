# Goal 2 — Fork Context Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/02/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Assignment created** — `results/tc/02/create.exit` is `0`.
2. **Regular view baseline** — `status-regular.*` and `step-regular.*` exist, both exits are `0`, and they show regular step behavior before fork activation.
3. **Fork view activation** — `finish-010.exit` is `0`, then `status-fork.*` and `step-fork.*` exist, both exits are `0`, and `step-fork.stdout` reflects fork-structured guidance.
4. **Back-to-regular transition** — `finish-020.exit` is `0`, then `status-return.*` and `step-return.*` exist, both exits are `0`, and `step-return.stdout` shows the queue returned to regular step behavior.
5. **Workflow completion** — `finish-030.exit`, `finish-040.exit`, and `status-final.exit` are `0`, and final status evidence shows all workflow steps terminal.

## Verdict

- **PASS**: The named regular, fork, return, and final checkpoints all exist and clearly differentiate the context transitions through completion.
- **FAIL**: Named transition checkpoints are missing/contradictory, or workflow does not complete.

Report: `PASS` or `FAIL` with evidence (transition checkpoints + final status).
