# Goal 5 — Output Override

## Goal

Test that explicit `--output` flags override the auto-format behavior. Force the large preset to stdio with `--output stdio`, and force the small preset to cache with `--output cache`.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/large-to-stdio.stdout`, `.stderr`, `.exit` — large preset forced to stdio
- `results/tc/05/small-to-cache.stdout`, `.stderr`, `.exit` — small preset forced to cache

## Constraints

- Using what you learned from Goal 1, invoke ace-bundle with the appropriate --output flag.
- All artifacts must come from real tool execution, not fabricated.
