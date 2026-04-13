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
3. **Fork step display** — Fork-step evidence is present in either `status.fork.stdout` or `finish.010.stdout`; it should include structured fork instruction sections (for example "Onboard", "Work", "Report").
4. **Context transitions** — `status.back-to-regular.stdout` or equivalent status evidence after finishing 020 shows verify as current regular step with raw instructions.
5. **Workflow completion** — `status.final.stdout` or `status-final.stdout` shows "Assignment completed!" with all 4 steps done.

## Verdict

- **PASS**: Regular steps show raw instructions, fork steps show structured fork instructions, transitions work correctly, and workflow completes.
- **FAIL**: Context display incorrect, fork-step structured instructions absent, or workflow incomplete.

Report: `PASS` or `FAIL` with evidence (content snippets from status captures).
