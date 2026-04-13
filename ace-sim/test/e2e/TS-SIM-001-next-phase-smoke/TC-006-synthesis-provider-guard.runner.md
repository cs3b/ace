# Goal 6: Synthesis Provider Guard

## Objective
Verify the CLI rejects `--synthesis-provider` when `--synthesis-workflow` is not provided.

## Steps
1. Create source file `results/tc/06/source.md` with sample markdown content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/06/source.md --provider glite --repeat 1 --synthesis-provider claude:haiku`
   Save stdout/stderr/exit to:
   - `results/tc/06/run.stdout`
   - `results/tc/06/run.stderr`
   - `results/tc/06/run.exit`
   Note: `--synthesis-workflow` is intentionally omitted (not passed as empty) to trigger the validation guard that requires it when `--synthesis-provider` is set.
3. Preserve command output exactly; do not normalize or reinterpret error text.
