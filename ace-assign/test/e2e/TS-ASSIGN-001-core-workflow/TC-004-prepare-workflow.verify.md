# Goal 4 — Prepare Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Single-task job generated** — `single-task-job.yml` exists with `session:` and `phases:` keys.
2. **Placeholders resolved** — No `{{...}}` tokens remain in single-task-job.yml. Taskref "001" appears in instructions.
3. **Expected phases/skills** — Single-task job contains work-on-task, create-pr, review-valid-1 phases with ace-task-work, ace-git-create-pr, ace-review-pr skills.
4. **Multi-task job generated** — `multi-task-job.yml` exists with `session:` and `phases:` keys.
5. **Batch structure** — Multi-task job has batch-tasks parent at 010, children 010.01 (work-on-001) and 010.02 (work-on-002).
6. **Review/apply phases** — Multi-task job includes review-valid-1, apply-valid-1, review-fit-1, apply-fit-1, review-shine-1, apply-shine-1.
7. **No unresolved placeholders** — No `{{...}}` tokens in multi-task-job.yml. Both taskrefs 001 and 002 appear.

## Verdict

- **PASS**: Both expansions produce valid job files with resolved placeholders, correct structure, and expected phases/skills.
- **FAIL**: Job files missing, unresolved placeholders, or missing expected phases/skills.

Report: `PASS` or `FAIL` with evidence (file content citations).
