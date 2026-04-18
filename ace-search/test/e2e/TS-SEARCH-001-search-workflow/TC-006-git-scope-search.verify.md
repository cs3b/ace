# Goal 6 -- Git-Scoped Search Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
   Accept equivalent runner captures under `ace-search/results/tc/{NN}/` when the
   package suite mirrors artifacts there.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/06/` or `ace-search/results/tc/06/` contains tracked-scope command captures.
2. Exit code is captured.
3. Output/stderr evidence reflects tracked-file scoped execution with clear user-facing behavior.
4. Evidence cites `tracked-search.stdout`/`tracked-search.stderr` and `tracked-search.exit`.

## Verdict

- **PASS**: Git-scoped search behavior is evidenced with tracked-scope command artifacts.
- **FAIL**: No tracked-scope outcome evidence or missing command artifacts.
