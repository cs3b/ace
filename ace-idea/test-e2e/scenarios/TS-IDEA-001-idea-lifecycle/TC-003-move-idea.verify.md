# Goal 3 — Move Idea Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. Idea remains under `.ace-ideas/` and does not require a dedicated `_next/` directory.
2. The move result does not leave a duplicate in `_next/` (only the current `.ace-ideas/` path or expected root scope target).
3. `ace-idea update` exit code is `0` and `stdout` includes `Idea updated:` with the ID and `root` scope reference.
4. `ace-idea list --in next` includes the moved idea.

## Verdict

- **PASS**: Idea file physically moved to the expected root path (or unchanged if root is `next`), and listing confirms root-scope visibility.
- **FAIL**: File not relocated, found in both locations, or command failed.
