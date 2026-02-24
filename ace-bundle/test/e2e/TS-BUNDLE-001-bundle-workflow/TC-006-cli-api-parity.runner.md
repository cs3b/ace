# Goal 6 — CLI-API Parity

## Goal

Verify CLI and Ruby API parity for the same input with behavior-level equivalence:
- exit code parity
- error-handling parity
- equivalent interpretation of bundle frontmatter (raw vs rendered output is acceptable when semantically aligned)

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
- For API error case, treat `result.metadata[:error]` as failure and exit non-zero. Example:
  `ruby -r ace/bundle -e 'result = Ace::Bundle.load_file("nonexistent-file.md"); if result.metadata[:error]; warn result.metadata[:error]; exit 1; else puts result.content; end'`
- In `comparison.md`, classify output as:
  - `identical` OR
  - `functionally-equivalent-by-design` (acceptable) when CLI preserves frontmatter while API renders the same bundle sections/content semantics.
- Do not mark parity failure solely due to raw-frontmatter vs rendered-section formatting differences.
- All artifacts must come from real tool execution, not fabricated.
