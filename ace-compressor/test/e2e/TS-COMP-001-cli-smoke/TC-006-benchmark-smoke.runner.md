# Goal 6 - Benchmark smoke

## Goal

Verify the documented `benchmark` command runs for all public modes and returns machine-readable output.

## Workspace

Save artifacts to `results/tc/06/`.

Actions:
1. Create `results/tc/06/input.md` with:
   - one heading
   - one short paragraph
2. Run:
   `ace-compressor benchmark results/tc/06/input.md --modes exact,compact,agent --format json`
3. Capture stdout/stderr/exit to:
   - `results/tc/06/benchmark.stdout`
   - `results/tc/06/benchmark.stderr`
   - `results/tc/06/benchmark.exit`

## Constraints

- Do not use library imports.
- Keep all writes under `results/tc/06/`.
