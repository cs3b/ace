# Goal 6: Synthesis Provider Guard

## Objective
Verify the CLI rejects `--synthesis-provider` when `--synthesis-workflow` is not provided.

## Steps
1. Create source file `results/tc/06/source.md` with sample markdown content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/06/source.md --provider glite --repeat 1 --synthesis-workflow '' --synthesis-provider claude:haiku`
   Save stdout/stderr/exit to `results/tc/06/run.*`.
3. Preserve command output exactly; do not normalize or reinterpret error text.
