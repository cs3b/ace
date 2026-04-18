# Goal 4 — Task-Scoped Processing Path

## Goal

Run setup and process via the public `--task` path to prove task-scoped prompt resolution and archive
lifecycle behavior in a realistic task context.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `task-create.stdout`, `task-create.stderr`, `task-create.exit` from `ace-task create`
- `task-id.txt` containing the created task ID used for this goal when extraction is straightforward
- `task-setup.stdout`, `task-setup.stderr`, `task-setup.exit` from `ace-prompt-prep setup --task <task-id>`
- `task-process.stdout`, `task-process.stderr`, `task-process.exit` from `ace-prompt-prep process --task <task-id>`
- `task-workspace-tree.txt` showing `.ace-local/prompt-prep/prompts/<task-id>` contents
- `task-output.md` containing processed output for evidence review
- `task-archive-list.txt` listing archive directory files for task scope
- `task-previous-link.txt` showing `_previous.md` symlink target for task scope

## Constraints

- Use only public CLI commands (`ace-task create`, `setup --task`, `process --task`) for this flow.
- Extract the created task ID from `ace-task create` output and reuse exactly that value for all task-scoped commands.
- Persist `task-create.stdout`, `.stderr`, and `.exit` before starting `setup --task`.
- If you also write `task-id.txt`, its value must match the task ID shown in `task-create.stdout`.
- Ensure the task prompt content contains marker token `TASK_SCOPE_CHECKPOINT` before processing.
- Validate task-scope behavior using captured filesystem and output artifacts, not assumptions.
