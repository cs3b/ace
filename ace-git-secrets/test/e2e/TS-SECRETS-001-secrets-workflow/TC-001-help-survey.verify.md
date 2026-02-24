# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **File exists** — At least one file exists in `results/tc/01/`.
2. **Substantive content** — The file contains more than 5 lines of non-empty text.
3. **Mentions subcommands** — The content references at least two of: scan, rewrite-history, revoke.
4. **Observations present** — The content includes at least one observation about the tool's interface.

## Verdict

- **PASS**: File exists with substantive observations about ace-git-secrets' interface.
- **FAIL**: File missing, empty, or lacks mention of key subcommands.

Report: `PASS` or `FAIL` with evidence.
