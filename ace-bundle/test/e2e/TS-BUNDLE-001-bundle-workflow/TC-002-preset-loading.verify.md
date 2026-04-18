# Goal 2 — Preset Loading and File Pattern Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Both capture sets exist** — `results/tc/02/` contains stdout/exit captures for both section and simple presets.
2. **Both exit codes zero** — both preset runs succeeded.
3. **Section preset includes expected content** — `section-preset.stdout` contains representative file/command content (for example README text and command output).
4. **File-pattern behavior is user-visible and correct** — matched files from the preset are present. Root-level markdown such as `test-context.md` is allowed because the section preset includes `*.md`. For the simple preset, files matched by `**/*.js` and `package*.json` are allowed, including `test/main.test.js`; unrelated markdown content should remain absent unless explicitly included by documented patterns.
5. **Simple preset content present** — `simple-preset.stdout` contains expected command/output evidence.

## Verdict

- **PASS**: Both presets load successfully with expected content and pattern behavior evidence.
- **FAIL**: Missing artifacts, non-zero exits, or content/pattern expectations not met.

Report: `PASS` or `FAIL` with evidence (exit codes, content snippets, included/excluded observations).
