# Goal 5 — Batch Mixed Results

## Goal

Run `ace-lint --fix` on a batch of three files: valid.rb, a copy of style_issues.rb, and syntax_error.rb. Verify the results are correctly categorized into passed, fixed, and failed arrays, and all three markdown files are generated. Also test `--no-report` suppresses all output.

## Workspace

Save all output to `results/tc/05/`. Capture:
- The batch command's stdout, stderr, and exit code
- Copies of report.json, ok.md, fixed.md, and pending.md
- Evidence of each file's categorization (passed/fixed/failed)
- A separate `--no-report` test: stdout, stderr, exit code, plus `cache.before`, `cache.after`, and `cache.diff` proving no new lint cache entries were created

## Constraints

- Copy style_issues.rb to a working file (e.g., fixable.rb) before running.
- Run the batch lint first, then run a separate --no-report test.
- For the `--no-report` sub-run, snapshot `.ace-local/lint` before and after the command and write a diff artifact; an empty diff is valid proof.
- All artifacts must come from real tool execution, not fabricated.
