# Goal 5 -- Fresh Setup Contract Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) as fallback.

1. **Setup commands succeed** -- `results/tc/05/config-init.exit` and `results/tc/05/handbook-sync.exit` are `0`.
2. **Provider discovery output is captured** -- `results/tc/05/list-providers.exit` is `0`, and `results/tc/05/list-providers.stdout` is non-empty with provider/status style content.
3. **Doctor output is actionable** -- `results/tc/05/config-doctor.exit` is `0`, and `results/tc/05/config-doctor.stdout` is non-empty.
4. **`.ace-local/` ignore evidence exists** -- `results/tc/05/gitignore.snapshot` exists and either:
   - `results/tc/05/ace-local-ignore-hits.txt` contains `^.ace-local/$` hit(s), or
   - snapshot already includes `.ace-local/` ignore semantics.
5. **Codex alias model sanity evidence exists** -- `results/tc/05/codex-files.txt` exists; if it contains files, `results/tc/05/codex-mini-hits.txt` has no `gpt-5-mini` matches.
6. **Summary artifact exists** -- `results/tc/05/setup-summary.txt` contains all four recorded exits.

## Verdict

- **PASS**: Setup path artifacts are present, diagnostics are captured, and no Codex alias references `gpt-5-mini`.
- **FAIL**: Missing artifacts, non-zero setup command exits, or alias sanity check violation.

Report: `PASS` or `FAIL` with evidence (artifact file names and key snippets).
