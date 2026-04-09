# Goal 3 — Preset Composition

## Goal

Test multi-level preset inheritance via dry-run. Run ace-review with the level_3 preset (which inherits level_2 → level_1) in --dry-run mode. Also test code-pr (which inherits from code) to verify model settings cascade through the chain.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/level3.stdout`, `.stderr`, `.exit` — level_3 preset dry-run
- `results/tc/03/code-pr.stdout`, `.stderr`, `.exit` — code-pr preset dry-run

## Constraints

- Use --dry-run to test preset resolution without making real API calls.
- Use explicit local subject input for both commands to avoid empty-subject failures:
  - `--subject "files:fixtures/**/*.rb"`
- Using what you learned from Goal 1, invoke ace-review with preset and dry-run flags.
- All artifacts must come from real tool execution, not fabricated.
