# Goal 3 -- Count/List Semantics Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
   Accept equivalent runner captures under `ace-search/results/tc/{NN}/` when the
   package suite mirrors artifacts there.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/03/` or `ace-search/results/tc/03/` contains captures for both commands.
2. Both exit codes are successful.
3. `files-with-matches.stdout` shows file-list semantics.
4. `count.stdout` shows numeric count semantics.
5. Evidence cites both `files-with-matches.*` and `count.*` captures.

## Verdict

- **PASS**: Files-with-matches and count behaviors are both evidenced via user-visible output.
- **FAIL**: Missing list/count evidence or command failure.
