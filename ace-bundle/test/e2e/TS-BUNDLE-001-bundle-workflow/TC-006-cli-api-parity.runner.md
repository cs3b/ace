# Goal 6 — CLI-API Parity

## Goal

Verify that the CLI (ace-bundle command) and Ruby API (Ace::Bundle.load_file) produce identical output for the same input. Also verify both handle errors consistently for nonexistent files.

## Workspace

Save all output to `results/tc/06/`. Capture:
- `results/tc/06/cli-valid.stdout`, `.exit` — CLI output for test-context.md
- `results/tc/06/api-valid.stdout`, `.exit` — API output for test-context.md
- `results/tc/06/comparison.md` — whether outputs match
- `results/tc/06/cli-error.stdout`, `.stderr`, `.exit` — CLI output for nonexistent file
- `results/tc/06/api-error.stdout`, `.stderr`, `.exit` — API output for nonexistent file

## Constraints

- The sandbox has `test-context.md` as the test input file.
- For API output, use: `ruby -r ace/bundle -e 'result = Ace::Bundle.load_file("test-context.md"); puts result.content'`
- All artifacts must come from real tool execution, not fabricated.
