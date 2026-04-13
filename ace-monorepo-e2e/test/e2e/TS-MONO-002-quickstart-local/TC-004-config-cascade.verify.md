# Goal 4 — Configuration Cascade Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) as fallback.

1. **Config override file exists and is readable** — `results/tc/04/override-path.txt` exists and points to `.ace/git/commit.yml`; `results/tc/04/override-content.txt` contains both `max_subject_length` and `body_wrap`.
2. **Prompt override file exists and is readable** — `results/tc/04/prompt-path.txt` exists and points to `.ace-handbook/prompts/git-commit.system.md`; `results/tc/04/prompt-content.txt` contains `You are a commit message generator`.
3. **Config diff command executes successfully** — `results/tc/04/config-diff.exit` is numeric and `0`; `results/tc/04/config-diff.stdout` is non-empty and contains either explicit override output (`CHANGED`/equivalent) or the current "no example file" message.
4. **Effective resolution is from project config** — `results/tc/04/cascade-resolution.exit` is `0`; stdout contains:
   - a source chain including `.ace/git/commit.yml`
   - `max_subject_length=72`
   - `body_wrap=80`
5. **Cascade summary checks** — `results/tc/04/cascade-check.txt` contains both override artifact paths.

## Verdict

- **PASS**: Both override files are created with expected content and cascade resolution confirms `.ace/git/commit.yml` controls the effective values.
- **FAIL**: Missing files/artifacts, unresolved diff/exit failures, missing source evidence, or missing expected values.

Report: `PASS` or `FAIL` with evidence (artifact file names and key snippets).
