# Goal 3 — Inference Priority and Exact Match

## Goal

Test two behaviors: (1) when multiple extension variants exist for the same base name, verify the shorthand extension wins (highest priority); (2) when an explicit extension is provided, verify it bypasses inference and matches exactly.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/priority.stdout`, `.stderr`, `.exit` — resolving a resource where `.g.md`, `.guide.md`, and `.md` all exist
- `results/tc/03/exact-match.stdout`, `.stderr`, `.exit` — resolving with explicit `.guide.md` extension

## Constraints

- The sandbox fixtures include `multi-ext.g.md`, `multi-ext.guide.md`, and `multi-ext.md` for the priority test.
- For the priority test, resolve `guide://multi-ext` (no extension) — shorthand `.g.md` should win.
- For the exact-match test, resolve `guide://coding-standards.guide.md` (with explicit extension) — should match exactly without inference.
- Using what you learned from Goal 1, invoke ace-nav appropriately. Do not assume syntax beyond what Goal 1 revealed.
- All artifacts must come from real tool execution, not fabricated.
