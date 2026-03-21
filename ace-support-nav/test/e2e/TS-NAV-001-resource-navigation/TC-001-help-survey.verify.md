# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **File exists** — At least one file exists in `results/tc/01/`.
2. **Substantive content** — The file contains more than 5 lines of non-empty text (not boilerplate or placeholder).
3. **Mentions protocols** — The content references specific protocols the tool supports (e.g., guide://, wfi://, or similar protocol URIs).
4. **Observations present** — The content includes at least one observation, note, or assessment about the tool's help output (not just a raw copy-paste of `--help`).
5. **Sources capture exists** — `results/tc/01/sources.stdout`, `.stderr`, and `.exit` are present.
6. **Sources command succeeded** — `results/tc/01/sources.exit` is `0`.
7. **Sources listing is substantive** — `results/tc/01/sources.stdout` includes `Available sources:` and at least one source alias entry (for example a line containing `@`).

## Verdict

- **PASS**: All expectations met. Help observations are substantive and sources command evidence confirms real listing output.
- **FAIL**: Missing observations/captures, unsuccessful sources command, or missing protocol/source evidence.

Report: `PASS` or `FAIL` with evidence (quote relevant lines or note their absence).
