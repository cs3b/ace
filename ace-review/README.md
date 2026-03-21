# ace-review

Multi-model code review with configurable presets.

Run the same review workflow from terminal scripts or Claude Code with consistent outputs.

![ace-review demo](docs/demo/ace-review-getting-started.gif)

## Why ace-review

`ace-review` helps teams run repeatable code reviews with focused presets, multi-model execution, and optional GitHub PR integration. It keeps review inputs and outputs explicit so humans and agents can collaborate with the same command surface.

## Quick Start

Run:

```bash
gem install ace-review
ace-review --pr 123 --auto-execute
```

## Features

- Multi-model review execution with optional synthesis
- Preset-based configuration for code, docs, security, and PR workflows
- GitHub PR review mode, including comment posting when enabled
- Flexible subject/context composition from files, diffs, and presets
- Session artifacts saved for traceability and follow-up

## Documentation

- [Getting Started](docs/getting-started.md)
- [Feedback Workflow](docs/feedback-workflow.md)
- [Changelog](CHANGELOG.md)
- Runtime help: `ace-review --help`

## Common Commands

```bash
ace-review --preset code --subject diff:origin/main..HEAD --auto-execute
ace-review --pr 123 --preset code-pr --auto-execute
ace-review --pr 123 --preset security --post-comment --auto-execute
ace-review --list-presets
```

## Part of ACE

`ace-review` is part of ACE (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
