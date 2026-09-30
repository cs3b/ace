# Goal 1 — Discover Gems Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Gem list exists** — `results/tc/01/gem-list.txt` exists and contains at least 10 gem names (the project has 20+ ACE gems).
2. **All entries are ace-* gems** — Every line in `gem-list.txt` starts with `ace-`.
3. **Count matches** — `results/tc/01/gem-count.txt` contains a number that matches the line count of `gem-list.txt`.
4. **No path directives** — `results/tc/01/path-check.txt` confirms no `path:` references in the Gemfile.
5. **Frozen manifest present** — `results/tc/01/release-manifest.json` exists, parses as a JSON object with `schema_version: 1` and a nonempty `packages` array, and `results/tc/01/manifest-package-count.txt` records the same package count as the manifest's `packages` length.

## Verdict

- **PASS**: Gem list has 10+ ace-* entries, count matches, no path directives found, and the frozen manifest copy is present with a matching package count.
- **FAIL**: Gem list missing/empty, count mismatch, path directives present, or the manifest copy is missing/malformed/mismatched.

Report: `PASS` or `FAIL` with evidence.
