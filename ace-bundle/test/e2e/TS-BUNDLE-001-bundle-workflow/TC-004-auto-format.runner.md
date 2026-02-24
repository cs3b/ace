# Goal 4 — Auto-Format Threshold

## Goal

Test the auto-format behavior: small content (under 500 lines) should output directly to stdout, while large content (over 500 lines) should be saved to a cache file. Test with both a small preset and the large-test preset.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/small.stdout`, `.stderr`, `.exit` — small preset output (expect direct content)
- `results/tc/04/large.stdout`, `.stderr`, `.exit` — large preset output (expect cache file reference)

## Constraints

- The sandbox has `small-test` preset (few lines) and `large-test` preset (600+ lines).
- Using what you learned from Goal 1, invoke ace-bundle for each.
- All artifacts must come from real tool execution, not fabricated.
