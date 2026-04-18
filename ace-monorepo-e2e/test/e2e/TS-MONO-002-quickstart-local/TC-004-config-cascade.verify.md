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
4. **Public config visibility check passes** — `results/tc/04/config-visibility.exit` is numeric and `0`; stdout is non-empty and references `.ace/git/commit.yml` or changed project-level values.
5. **Public prompt loading check passes** — `results/tc/04/prompt-bundle.exit` is numeric and `0`; `results/tc/04/prompt-bundle.stdout` contains `You are a commit message generator`.
6. **Cascade summary checks** — `results/tc/04/cascade-check.txt` contains both override paths and recorded exit statuses for config visibility and prompt bundle checks.

## Verdict

- **PASS**: Overrides are created with expected content and public CLI checks confirm visibility and prompt resolution.
- **FAIL**: Missing files/artifacts, failed public command checks, or missing expected override evidence.

Report: `PASS` or `FAIL` with evidence (artifact file names and key snippets).
