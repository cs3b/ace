# Goal 2 — Valid File Lint

## Goal

Lint the `valid.rb` fixture file and verify the tool exits successfully with a well-structured report. Capture the generated report.json and ok.md files as evidence.

## Workspace

Save all output to `results/tc/02/`. Capture:
- The command's stdout, stderr, and exit code
- A copy of the generated report.json
- A copy of the generated ok.md

## Constraints

- Use `ace-lint` to lint `valid.rb` from the fixtures. Do not use --no-report.
- Using what you learned from Goal 1, invoke the lint operation. Do not assume syntax beyond what Goal 1 revealed.
- Use the report path from the tool's output to locate generated files. Do not hardcode cache paths.
- All artifacts must come from real tool execution, not fabricated.
