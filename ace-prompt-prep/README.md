# ace-prompt-prep

Prepare prompts in a structured workspace with optional LLM enhancement and bundled project context.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-prompt-prep demo](docs/demo/ace-prompt-prep-getting-started.gif)

`ace-prompt-prep` helps developers and coding agents keep prompt authoring repeatable: initialize templates,
archive every revision, enrich prompt context with `ace-bundle`, and optionally run enhancement through `ace-llm`.

## Use Cases

**Keep prompt history without manual bookkeeping** - initialize and process prompts in a stable workspace where
archives and `_previous.md` are maintained automatically.

**Improve prompt quality before execution** - run `--enhance` with model selection to rewrite prompts for clarity and
completeness before handing them to an agent or API.

**Inject project context directly into prompts** - use `bundle` frontmatter sources so prompts include selected files,
presets, and command output at processing time.

## Works With

- **[ace-task](../ace-task)** for task-scoped prompt directories via `--task`.
- **[ace-bundle](../ace-bundle)** for context loading from files, presets, and commands.
- **[ace-llm](../ace-llm)** for optional LLM-based prompt enhancement.
- **[ace-git](../ace-git)** for branch-aware task workflow usage patterns.

## Features

- Workspace setup with package templates (`setup`, `--template`, `--task`).
- Prompt processing with archive management and output controls (`process`, `--output`).
- Optional context loading via `--bundle` / `--no-bundle` and prompt frontmatter sources.
- Optional enhancement flow via `--enhance`, `--model`, and custom system prompts.
- Task-aware prompt routing for task and subtask IDs.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-prompt-prep --help`

## Agent Skills

- `as-prompt-prep` (package-owned canonical skill)

## Part of ACE

`ace-prompt-prep` is part of [ACE](../README.md) (Agentic Coding Environment).
