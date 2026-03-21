# ACE - Agentic Coding Environment

> CLI tools designed for developers, ready for agents.

![ACE Demo](docs/demo.gif)

## The Problem

Developers and AI agents now work side by side, but most tooling was built for one or the other. GUI-heavy workflows, verbose outputs, and scattered APIs make agent collaboration fragile and slow. ACE closes that gap with deterministic CLI tools and composable workflows that both humans and agents can run the same way.

## Tools

| Tool | What it does |
|------|--------------|
| `ace-review` | Runs multi-model code reviews with configurable presets. |
| `ace-git-commit` | Generates consistent commit messages from your staged changes. |
| `ace-bundle` | Loads project context, workflows, and docs with protocol support. |
| `ace-task` | Manages tasks with spec-first planning and execution flow. |
| `ace-git-worktree` | Creates and manages isolated task worktrees quickly. |
| `ace-search` | Searches files and content with agent-friendly output. |

## Quick Start

Install a minimal set of tools and run your first command:

- `gem install ace-git-commit ace-review ace-bundle`
- `ace-git-commit -i "fix auth bug"`

## Principles

1. **Same Tools** - Developers and agents use identical CLI commands.
2. **Transparent** - Outputs are inspectable, with file-based artifacts and dry-run support.
3. **Modular** - Capabilities ship as focused, installable gems.
4. **Provider Freedom** - Switch providers or CLI agents without changing your workflow.

## Documentation

- [Vision](docs/vision.md)
- [Architecture](docs/architecture.md)
- [Tools Reference](docs/tools.md)
- [Contributing](docs/contributing/)

## License

MIT
