# Goal 4 - Update Docs Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/04/update.stdout`, `.stderr`, and `.exit` exist.
2. `results/tc/04/update.exit` is `0`.
3. `results/tc/04/before.md` and `results/tc/04/after.md` both exist.
4. The before/after snapshots differ and indicate metadata update effects (for example refreshed `last-updated` or added inferred frontmatter fields).
5. `results/tc/04/update.stdout` includes update-summary indicators such as processed/updated document counts.

## Verdict

- **PASS**: Update command succeeds and captured before/after evidence proves CLI-driven metadata updates.
- **FAIL**: Missing artifacts, command failure, or no observable metadata change evidence.
