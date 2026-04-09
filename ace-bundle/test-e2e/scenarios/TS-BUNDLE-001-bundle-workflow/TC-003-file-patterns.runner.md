# Goal 3 — File Pattern Matching

## Goal

Using the `comprehensive-review` preset, verify that file glob patterns correctly include matching files and exclude non-matching files. Check that src/ files and README.md are included, while test/ files are excluded.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/pattern-output.stdout`, `.stderr`, `.exit` — full preset output

Optional capture:
- `results/tc/03/analysis.md` — summary of which files were included/excluded

## Constraints

- The sandbox has src/main.js, src/utils.js, README.md, and test/main.test.js.
- Using what you learned from Goal 1, invoke ace-bundle. The preset patterns are `*.md`, `package.json`, `src/**/*.js`.
- All artifacts must come from real tool execution, not fabricated.
