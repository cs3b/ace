# Goal 2 — Model Selection Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains command captures including at least one `*.stdout`,
   one `*.stderr`, and one `*.exit` file.
2. Exit code evidence is explicit and numeric in `*.exit`.
3. Evidence in `*.stdout`/`*.stderr` shows either:
   - model-selection success (for example JSON output content), or
   - explicit provider auth/config failure tied to the Goal 2 command.
4. If Goal 2 fails before inference, `*.stderr` must still reference the Goal 2
   target (`openai` / `gpt-4o-mini`) so model routing intent is observable.
5. Output format behavior (`json`) is reflected in artifact content when the
   command succeeds.

## Verdict

- **PASS**: Model-selection behavior is demonstrably captured, including
  explicit early-failure evidence for the Goal 2 model target.
- **FAIL**: No evidence of routing/format handling for the Goal 2 command.
