# Goal 1 — Basic Query Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains command captures including at least one `*.stdout`,
   one `*.stderr`, and one `*.exit` file.
2. Exit code evidence is explicit and numeric in `*.exit`.
3. Output evidence in `*.stdout`/`*.stderr` shows either:
   - a valid model response, or
   - a clear provider auth/config failure message.
4. Evidence files must correspond to the Goal 1 command execution, not unrelated
   setup commands.

## Verdict

- **PASS**: Artifacts clearly show real execution outcome.
- **FAIL**: Missing captures or ambiguous/no output.
