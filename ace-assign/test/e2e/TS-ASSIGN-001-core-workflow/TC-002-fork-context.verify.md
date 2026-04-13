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
2. **Regular step display** — `status.regular.stdout` (or `status.01.stdout` fallback) shows raw "Instructions:" header with regular step content ("Load project context"), and no fork-only formatting.
3. **Fork step display** — Prefer `status.fork.stdout` captured after `finish.010`. Accept `finish.010.stdout` as authoritative fallback if it shows the queue advanced to step `020` with structured fork instruction sections (for example "Onboard", "Work", "Report").
4. **Context transitions** — Prefer `status.back-to-regular.stdout` captured after `finish.020`; it should show `Current Step: 030 - verify` with raw regular instructions. If that capture is missing or appears stale, accept `finish.020.stdout` as authoritative transition proof when it shows `Advancing to step 030: verify` and raw `Instructions:` for the verify step.
5. **Workflow completion** — `status.final.stdout` or `finish.040.final.stdout` shows "Assignment completed!" with all 4 steps done.

## Verdict

- **PASS**: Regular steps show raw instructions, fork steps show structured fork instructions, post-020 evidence proves the queue returned to regular step `030`, and workflow completes.
- **FAIL**: Fork-step structured instructions are absent, both post-020 transition artifacts are missing or contradictory, or workflow is incomplete.

Report: `PASS` or `FAIL` with evidence (content snippets from status captures).
