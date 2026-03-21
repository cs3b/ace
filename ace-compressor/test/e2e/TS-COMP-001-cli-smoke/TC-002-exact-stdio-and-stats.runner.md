# Goal 2 - Exact mode stdio and stats smoke

## Goal

Create a markdown source file, run exact mode in `stdio` and `stats` formats, and capture outputs.

## Workspace

Save artifacts to `results/tc/02/`.

Actions:
1. Create `results/tc/02/input.md` with a heading and one summary sentence.
2. Run `ace-compressor results/tc/02/input.md --mode exact --format stdio` and capture:
   - `results/tc/02/exact-stdio.stdout`
   - `results/tc/02/exact-stdio.stderr`
   - `results/tc/02/exact-stdio.exit`
3. Run `ace-compressor results/tc/02/input.md --mode exact --format stats` and capture:
   - `results/tc/02/exact-stats.stdout`
   - `results/tc/02/exact-stats.stderr`
   - `results/tc/02/exact-stats.exit`

## Constraints

- Do not use library imports.
- Keep all writes under `results/tc/02/`.
