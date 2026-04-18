# Goal 2 — Valid Lint End State

## Goal

Lint the `valid.rb` fixture file and verify the final user-visible outcome first: successful run and passing report state. Capture report artifacts as supporting evidence.

## Workspace

Save all output to `results/tc/02/`. Capture:
- The command's stdout, stderr, and exit code
- The generated report directory path and copied `report.json`
- A copy of generated `ok.md` with pass evidence

## Constraints

- Scenario setup copies the fixture tree into the sandbox root, so lint the sandbox-root file `valid.rb`. Do not prefix the path with `fixtures/`.
- Scenario setup already installs deterministic validator shims into the sandbox runtime PATH; use the provided environment as-is. Do not reconfigure validators manually for this goal.
- Do not use `--no-report`.
- Using what you learned from Goal 1, invoke the lint operation. Do not assume syntax beyond what Goal 1 revealed.
- Use the report path from the tool's output to locate generated files. Do not hardcode cache paths.
- All artifacts must come from real tool execution, not fabricated.
