# Goal 2 — Fork Context Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
Fallback tolerance:
- If `results/tc/02/` is entirely absent, treat this goal as **inconclusive-pass** and rely on captured fork-context evidence from other test cases in the same run.
1. **Assignment created** — `create.exit` contains `0`.
2. **Regular step status** — `status.regular.stdout` (or `status.01.stdout` fallback) stays status-only and does not include raw instruction text.
3. **Regular step instructions** — `step.regular.stdout` shows the raw regular step content ("Load project context").
4. **Fork step display** — `step.fork.stdout` captured after `finish.010` shows structured fork instruction sections (for example "Onboard", "Work", "Report").
5. **Context transitions** — Prefer `status.back-to-regular.stdout` captured after `finish.020`; it should show the queue returned to step `030`. `step.back-to-regular.stdout` should show the raw regular instructions for the verify step.
6. **Workflow completion** — `status.final.stdout` or `finish.040.final.stdout` shows completion with all 4 steps done.

## Verdict

- **PASS**: `status` stays status-only, `step` returns the correct regular/fork instructions, post-020 evidence proves the queue returned to regular step `030`, and workflow completes.
- **FAIL**: Status still carries raw instructions, fork-step structured instructions are absent from `step`, transition artifacts are missing or contradictory, or workflow is incomplete.

Report: `PASS` or `FAIL` with evidence (content snippets from status captures).
