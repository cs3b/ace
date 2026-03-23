# ace-llm

Query any LLM from the terminal with one interface across API and CLI providers.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-llm demo](docs/demo/ace-llm-getting-started.gif)

`ace-llm` gives developers and coding agents one command surface for multi-provider prompting, alias-based model
selection, fallback routing, and structured output handling.

## Use Cases

**Run the same prompt across different providers** - switch models quickly with aliases while keeping one command
shape and consistent output controls.

**Build resilient prompt workflows** - configure fallback and retry behavior so transient provider issues do not block
interactive development or automation.

**Capture responses for downstream tooling** - emit plain text, markdown, or JSON outputs for handoff into docs,
reviews, and scripted workflows.

## Works With

- **[ace-support-cli](../ace-support-cli)** for shared CLI command patterns and option handling.
- **[ace-support-config](../ace-support-config)** for config cascade across defaults, user, and project.
- **[ace-llm-providers-cli](../ace-llm-providers-cli)** for CLI-provider execution adapters.

## Features

- Unified provider interface for API and CLI model execution.
- Alias-first model selection for fast interactive prompting.
- Fallback and retry routing for transient provider failures.
- Output controls for text, markdown, and JSON response formats.
- Preset support via `@preset` and `--preset` execution profiles.
- Cost and token usage reporting in response metadata.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-llm --help`

## Agent Skills

`ace-llm` currently ships no package-owned canonical skills.

## Part of ACE

`ace-llm` is part of [ACE](../README.md) (Agentic Coding Environment).
