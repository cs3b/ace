# Goal 4 — Output Routing (Default + Override)

## Goal

Validate user-visible output routing behavior in one consolidated flow:
- default routing behavior for smaller vs larger bundle payloads
- explicit override behavior for `--output stdio` and `--output cache`

## Workspace

Save all output to `results/tc/04/`. Run exactly these four commands and capture each to the named artifacts:

1. `ace-bundle .ace/bundle/presets/small-test.md` → `results/tc/04/small.stdout`, `.stderr`, `.exit`
2. `ace-bundle .ace/bundle/presets/large-test.md` → `results/tc/04/large.stdout`, `.stderr`, `.exit`
3. `ace-bundle .ace/bundle/presets/large-test.md --output stdio` → `results/tc/04/large-to-stdio.stdout`, `.stderr`, `.exit`
4. `ace-bundle .ace/bundle/presets/small-test.md --output cache` → `results/tc/04/small-to-cache.stdout`, `.stderr`, `.exit`

## Constraints

- The sandbox has `small-test` and `large-test` presets at `.ace/bundle/presets/`.
- Use positional file paths (not `--file`) so default routing behavior is exercised.
- Assert routing only through user-visible outputs/artifacts, not internal threshold implementation details.
- Run exactly the four commands above. Do not add extra test cases.
- All artifacts must come from real tool execution, not fabricated.
