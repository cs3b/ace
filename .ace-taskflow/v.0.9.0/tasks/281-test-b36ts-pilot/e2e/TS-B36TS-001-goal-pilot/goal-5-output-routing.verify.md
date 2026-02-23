# Goal 5 — Output Routing Verification

## Injected Context

The verifier receives the `goal/` directory tree and access to the sandbox path.

## Expectations

1. **Files exist** — At least 2 mode pairs (stdout + stderr files) exist in `goal/5/`.
2. **Quiet mode stdout** — In the quietest mode, stdout contains only the primary output (a base36 token) with no extra decoration or logging.
3. **Quiet mode stderr** — In the quietest mode, stderr is empty or minimal.
4. **Verbose/default mode** — In a more verbose mode, stderr contains additional content (logging, metadata, or decoration) beyond what the quiet mode produces.
5. **Stream separation** — Stdout never contains log/debug content; stderr never contains the primary token output.

## Verdict

- **PASS**: At least 2 mode pairs present. Quiet mode shows clean stdout with minimal stderr. Verbose mode shows additional stderr content. Streams are correctly separated.
- **FAIL**: Fewer than 2 mode pairs, streams are mixed, or quiet mode contains unexpected extra output.

Report: `PASS` or `FAIL` with evidence (file contents or relevant snippets from each mode).
