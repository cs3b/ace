# Goal 3 — Fork Context Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Assignment created** — `create.exit` contains `0`.
2. **Regular step display** — `status-regular.stdout` shows raw "Instructions:" header, mentions instruction content ("Load project context"), does NOT mention "Task tool".
3. **Fork step display** — `status-fork.stdout` shows "Context: fork", mentions "forked context" or "Task tool", includes "Working directory:", "Assignment:", and "Prompt for forked agent". Step content sections (Onboard, Work, Report) present.
4. **Context transitions** — `status-back-to-regular.stdout` shows verify as current with raw instructions, no "Task tool" or "Context:" for regular step. `status-second-fork.stdout` shows document as fork context with correct instructions.
5. **Workflow completion** — `status-final.stdout` shows "Assignment completed!" with all 4 steps done.

## Verdict

- **PASS**: Regular steps show raw instructions, fork steps show Task tool format, transitions work correctly, workflow completes.
- **FAIL**: Context display incorrect, missing Task tool format for fork steps, or workflow incomplete.

Report: `PASS` or `FAIL` with evidence (content snippets from status captures).
