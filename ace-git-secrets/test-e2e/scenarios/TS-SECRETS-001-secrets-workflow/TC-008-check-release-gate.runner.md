# Goal 8 - Check-Release Gate

## Goal

Exercise the release-gate command against known token history and verify both JSON output shape and strict-mode behavior.

## Workspace

Save all output to `results/tc/08/`. Capture:
- `results/tc/08/check-release-json.stdout`, `.stderr`, `.exit` - `check-release --format json` output
- `results/tc/08/check-release-strict.stdout`, `.stderr`, `.exit` - `check-release --strict` output

## Constraints

- Use `ace-git-secrets check-release` only (with option variations above).
- Use the existing fixture history; do not mutate setup outside the scenario contract.
- All artifacts must come from real tool execution, not fabricated.
