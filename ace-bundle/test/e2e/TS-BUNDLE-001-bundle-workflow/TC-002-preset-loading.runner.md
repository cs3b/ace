# Goal 2 — Preset Loading and File Pattern Behavior

## Goal

Load two presets via `ace-bundle` and validate user-visible file-pattern behavior through the section preset output:
- `comprehensive-review` should surface expected included files and command output
- `security-scanning` should load successfully with expected output sections
- preset output should reflect the documented glob patterns only; for example,
  `**/*.js` may legitimately include `test/main.test.js`, while unrelated markdown
  files should remain absent from that preset unless explicitly matched

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/section-preset.stdout`, `.stderr`, `.exit` — output from the section preset
- `results/tc/02/simple-preset.stdout`, `.stderr`, `.exit` — output from the simple preset
- `results/tc/02/pattern-analysis.md` — included/excluded file observations from section preset output

## Constraints

- Using what you learned from Goal 1, invoke `ace-bundle` for each preset.
- The sandbox has presets at `.ace/bundle/presets/comprehensive-review.md` and `.ace/bundle/presets/security-scanning.md`.
- Evaluate pattern behavior from section preset output only; do not invent extra fixture shortcuts or undocumented probes.
- All artifacts must come from real tool execution, not fabricated.
