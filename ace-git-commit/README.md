# ace-git-commit

Meaningful commit messages from your diff in one command.

Run the same commit workflow from terminal scripts or agent sessions with predictable output.

![ace-git-commit demo](docs/demo/ace-git-commit-getting-started.gif)

## Why ace-git-commit

`ace-git-commit` turns staged or working-tree changes into clear commit messages using your project context and intent. It helps teams keep commit history readable while staying fast in monorepos and multi-package repos.

## Quick Start

Run:

```bash
gem install ace-git-commit
ace-git-commit -i "fix auth bug"
```

## Features

- LLM-powered commit message generation from your diff
- Intention-aware messages with `-i` for better context
- Monorepo-aware scope handling for multi-package changes
- Configurable behavior through project and user ACE config files
- Works for both developer and agent-driven workflows

## Documentation

- [Getting Started](docs/getting-started.md)
- [Changelog](CHANGELOG.md)
- [Comparison Notes](COMPARISON.md)
- Runtime help: `ace-git-commit --help`

## Common Commands

```bash
ace-git-commit -i "fix auth bug"
ace-git-commit --only-staged
ace-git-commit path/to/file.rb path/to/other.rb
ace-git-commit --dry-run
```

## Part of ACE

`ace-git-commit` is part of ACE (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
