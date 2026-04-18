# Goal 1 — Public Surface Survey

## Goal

Map the retained public surface for this scenario using only `ace-lint --help` and `ace-lint/docs/usage.md`. Summarize the documented CLI flows used by later goals, with explicit references for `--auto-fix`, `--no-report`, `--validators`, and `--doctor`.

## Workspace

Save all output to `results/tc/01/`. Write `public-surface-map.md` that links each later goal to a documented help/docs entry.

## Constraints

- Use only `ace-lint --help` plus `ace-lint/docs/usage.md` for discovery. Do not use hidden recipes.
- Start with `--help` to discover the tool's interface. Do not assume flag names or options.
- Your map should reflect what help/docs actually report, not assumptions.
- **Foundation for later goals**: Your observations here serve as the reference for all subsequent goals. Later goals will build on what you discover — they will not re-run `--help`.
