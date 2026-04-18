# Goal 4 — Task-Scoped Processing Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
4. **Task creation evidence exists** — `task-create.*` capture files exist and `task-create.stdout` shows a created task ID.
5. **Task ID is recoverable** — use `task-id.txt` when present; otherwise derive the task ID from `task-create.stdout`.
6. **Primary captures exist** — `task-setup.*` and `task-process.*` capture files exist in `results/tc/04/`.
7. **Zero exit codes** — `task-create.exit`, `task-setup.exit`, and `task-process.exit` are all `0`.
8. **Task ID reuse is proven** — the recovered task ID is reused for the task-scoped workspace and archive evidence, even if setup/process stdout only reports the initialized prompt path.
9. **Task-scoped workspace exists** — `task-workspace-tree.txt` includes prompt workspace evidence with
   a prompt file path (`the-prompt.md` or `prompts/the-prompt.md`).
10. **Task output evidence present** — `task-output.md` is non-empty and includes `TASK_SCOPE_CHECKPOINT`.
11. **Task archive evidence present** — `task-archive-list.txt` shows at least one archive file entry.
12. **Task symlink updated** — `task-previous-link.txt` shows `_previous.md` targeting an archive file.

## Verdict

- **PASS**: Task-scoped setup/process succeeds with coherent task ID, output, archive, and symlink evidence.
- **FAIL**: Missing captures, non-zero exits, missing task marker, or missing archive/symlink evidence.

Report: `PASS` or `FAIL` with evidence (cite filenames and relevant content snippets).
