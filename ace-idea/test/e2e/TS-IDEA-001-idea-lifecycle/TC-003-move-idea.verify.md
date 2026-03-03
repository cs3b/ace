# Goal 3 — Move Idea Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `.ace-ideas/_next/` directory exists and contains the idea file (filesystem relocation confirmed).
2. The idea file no longer exists at its original root path under `.ace-ideas/` (not duplicated).
3. `ace-idea update` exit code is `0` and `stdout` includes `Idea updated:` with the ID and `next` folder reference.
4. `ace-idea list --in next` includes the moved idea.

## Verdict

- **PASS**: Idea file physically relocated to `_next/`, absent from root, and listing confirms new location.
- **FAIL**: File not relocated, found in both locations, or command failed.
