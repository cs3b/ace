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

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/small.stdout`, `.stderr`, `.exit` — small preset output (expect direct content)
- `results/tc/04/large.stdout`, `.stderr`, `.exit` — large preset output (expect cache file reference)
- `results/tc/04/large-to-stdio.stdout`, `.stderr`, `.exit` — large preset forced to stdio
- `results/tc/04/small-to-cache.stdout`, `.stderr`, `.exit` — small preset forced to cache

## Constraints

- The sandbox has `small-test` preset (few lines) and `large-test` preset (600+ lines).
- Using what you learned from Goal 1, invoke ace-bundle for both threshold and override checks.
- All artifacts must come from real tool execution, not fabricated.
