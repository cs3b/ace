# Goal 2 — Preset Discovery

## Goal

Use ace-review to list all available presets (--list-presets). Verify presets are discovered from both config and filesystem sources. The sandbox has presets: code, code-pr, level_1, level_2, level_3, preset_a, preset_b, broken, test, single, multi, reviewers-test.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/preset-list.stdout`, `.stderr`, `.exit` — the preset listing output

## Constraints

- Using what you learned from Goal 1, invoke the preset listing command.
- All artifacts must come from real tool execution, not fabricated.
