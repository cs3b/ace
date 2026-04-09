# Goal 4 - Compact refusal contract for rule-heavy input

## Goal

Verify compact mode refusal semantics for rule-heavy content with explicit guidance to retry exact mode.

## Workspace

Save artifacts to `results/tc/04/`.

Actions:
1. Create `results/tc/04/rules.md` with **exactly** this content (copy verbatim, no changes):

```markdown
# Policy Decisions

All workflows must be self-contained.

## Impact

Agents should never load external templates.

Commands must include explicit evidence on failure.

Outputs required for every run shall be saved locally.

- Only allow approved file paths
- Users must not bypass validation
```

2. Run `ace-compressor results/tc/04/rules.md --mode compact --format stdio`.
3. Capture stdout/stderr/exit to:
   - `results/tc/04/compact.stdout`
   - `results/tc/04/compact.stderr`
   - `results/tc/04/compact.exit`

## Constraints

- Do not treat non-zero exit as runner failure; capture evidence and continue.
- Keep all writes under `results/tc/04/`.
