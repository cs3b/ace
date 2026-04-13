# CLAUDE.md

Agent guidance for this repository.

## Command Types

- Slash commands such as `/as-task-work` run inside the chat tool.
- `ace-*` commands run in the terminal.

## ACE CLI Output Handling

- Run `ace-*` commands directly.
- Do not use pipes, redirects, or shell post-processors on `ace-*` commands.
- If an `ace-*` command prints a file path, read that file directly.

## Local Artifacts

- Use `.ace-local/` for project-local ACE artifacts.
- Use `/tmp/` for disposable temporary files.

## Testing

- Prefer `ace-test` and `ace-test-suite` over raw `bundle exec` test commands when those targets exist.
