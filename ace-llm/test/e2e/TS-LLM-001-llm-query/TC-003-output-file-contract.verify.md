# Goal 3 — Output File Contract Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/03/` contains command captures including at least one `*.stdout`,
   one `*.stderr`, and one `*.exit` file.
2. Exit code evidence is explicit and numeric in `*.exit`.
3. If the command succeeds (`*.exit` is `0`), `results/tc/03/response.md` exists,
   is non-empty, and capture output references the requested output path.
4. If the command fails, `*.stderr` must show explicit provider auth/config or
   provider-unavailable evidence tied to Goal 3 command intent.

## Verdict

- **PASS**: Output-file behavior is observable through either successful output
  persistence evidence or explicit provider/auth failure evidence.
- **FAIL**: No reliable evidence for output persistence semantics or command intent.
