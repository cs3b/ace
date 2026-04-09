# Goal 4 — Output Routing (Threshold + Override)

## Goal

Validate output routing in one consolidated flow:
- Auto-format threshold behavior:
  - small content (under 500 lines) routes to stdio
  - large content (over 500 lines) routes to cache
- Explicit override behavior:
  - `--output stdio` forces large content to stdio
  - `--output cache` forces small content to cache

## Workspace

Save all output to `results/tc/04/`. Run exactly these four commands and capture each to the named artifacts:

1. `ace-bundle .ace/bundle/presets/small-test.md` → `results/tc/04/small.stdout`, `.stderr`, `.exit`
2. `ace-bundle .ace/bundle/presets/large-test.md` → `results/tc/04/large.stdout`, `.stderr`, `.exit`
3. `ace-bundle .ace/bundle/presets/large-test.md --output stdio` → `results/tc/04/large-to-stdio.stdout`, `.stderr`, `.exit`
4. `ace-bundle .ace/bundle/presets/small-test.md --output cache` → `results/tc/04/small-to-cache.stdout`, `.stderr`, `.exit`

## Constraints

- The sandbox has `small-test` (few lines) and `large-test` (600+ lines) at `.ace/bundle/presets/`.
- Load via positional file path (not `--file` flag) so that auto-format threshold routing applies.
- Run exactly the four commands above. Do not add additional test cases.
- All artifacts must come from real tool execution, not fabricated.
