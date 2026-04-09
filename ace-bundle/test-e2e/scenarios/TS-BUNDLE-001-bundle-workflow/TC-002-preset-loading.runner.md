# Goal 2 — Preset Loading

## Goal

Load two presets using ace-bundle: (1) a section-based preset `comprehensive-review` that includes files, commands, and content sections, and (2) a simple preset `security-scanning` with top-level commands and files. Capture both outputs and verify they contain expected content.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/section-preset.stdout`, `.stderr`, `.exit` — output from the section preset
- `results/tc/02/simple-preset.stdout`, `.stderr`, `.exit` — output from the simple preset

## Constraints

- Using what you learned from Goal 1, invoke ace-bundle for each preset.
- The sandbox has presets at `.ace/bundle/presets/comprehensive-review.md` and `.ace/bundle/presets/security-scanning.md`.
- All artifacts must come from real tool execution, not fabricated.
