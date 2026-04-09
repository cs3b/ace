# Goal 3 - Per-source output directory behavior

## Goal

Verify `--source-scope per-source` writes one output path per input in input order.

## Workspace

Save artifacts to `results/tc/03/`.

Actions:
1. Create `results/tc/03/a.md` and `results/tc/03/b.md` with simple headings.
2. Create output directory `results/tc/03/exports/`.
3. Run:
   `ace-compressor results/tc/03/b.md results/tc/03/a.md --mode exact --source-scope per-source --output results/tc/03/exports/`
4. Capture stdout/stderr/exit to:
   - `results/tc/03/per-source.stdout`
   - `results/tc/03/per-source.stderr`
   - `results/tc/03/per-source.exit`
5. Record export directory listing to `results/tc/03/exports.ls`.

## Constraints

- Do not use library imports.
- Keep all writes under `results/tc/03/`.
