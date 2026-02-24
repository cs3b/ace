# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **File exists** — At least one file exists in `results/tc/01/`.
2. **Substantive content** — The file contains more than 5 lines of non-empty text (not boilerplate or placeholder).
3. **Mentions protocols** — The content references specific protocols the tool supports (e.g., guide://, wfi://, or similar protocol URIs).
4. **Observations present** — The content includes at least one observation, note, or assessment about the tool's help output (not just a raw copy-paste of `--help`).

## Verdict

- **PASS**: All expectations met. File exists with substantive observations about the tool's help interface including protocol references.
- **FAIL**: File missing, empty, boilerplate-only, or lacks any mention of tool protocols/flags.

Report: `PASS` or `FAIL` with evidence (quote relevant lines or note their absence).
