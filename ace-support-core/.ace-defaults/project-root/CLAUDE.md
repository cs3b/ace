# CLAUDE.md

ACE generated this starter guidance from `ace-support-core` defaults.
Customize it for your repository-specific rules and workflows.
Refresh the starter version with `bundle exec ace-config sync ace-support-core --force`.
Run `bundle exec ace-handbook sync` separately when you need to refresh projected skill folders.

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
