# Goal 4 - Compact refusal contract for rule-heavy input

## Goal

Verify compact mode refusal semantics for rule-heavy content with explicit guidance to retry exact mode.

## Workspace

Save artifacts to `results/tc/04/`.

Actions:
1. Create `results/tc/04/rules.md` containing rule-heavy policy language.
2. Run `ace-compressor results/tc/04/rules.md --mode compact --format stdio`.
3. Capture stdout/stderr/exit to:
   - `results/tc/04/compact.stdout`
   - `results/tc/04/compact.stderr`
   - `results/tc/04/compact.exit`

## Constraints

- Do not treat non-zero exit as runner failure; capture evidence and continue.
- Keep all writes under `results/tc/04/`.
