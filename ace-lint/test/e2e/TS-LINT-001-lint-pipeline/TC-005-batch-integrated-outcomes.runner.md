# Goal 5 — Batch Integrated Outcomes

## Goal

Run `ace-lint --fix` on a batch of three files: valid.rb, a copy of style_issues.rb, and syntax_error.rb. Verify integrated final outcomes are correctly categorized into passed, fixed, and failed arrays.

## Workspace

Save all output to `results/tc/05/`. Capture:
- The batch command's stdout, stderr, and exit code
- The exact lint command contract used for this goal
- The emitted report directory path for this goal
- Copies of report.json, ok.md, fixed.md, and pending.md from that exact emitted report directory when present
- Evidence of each file's categorization (passed/fixed/failed)

## Constraints

- Copy style_issues.rb to a working file (e.g., fixable.rb) before running.
- The sandbox fixture files are available at `valid.rb`, `style_issues.rb`, and `syntax_error.rb` in the sandbox root. Do not prefix them with `fixtures/`.
- Scenario setup already installs deterministic validator shims into the sandbox runtime PATH; use the provided environment as-is.
- This goal covers integrated batch outcomes only; `--no-report` is validated in Goal 8.
- Persist the report directory emitted by the command and copy report artifacts from that directory only, so categorization evidence comes from one batch run.
- All artifacts must come from real tool execution, not fabricated.
