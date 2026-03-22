# ace-bundle

Assemble project context for AI agents and developers — in one command.

![ace-bundle demo](docs/demo/ace-bundle-getting-started.gif)

## Why ace-bundle

Context is the bottleneck for AI-assisted development. `ace-bundle` collects files, commands, diffs, and protocol resources into a single context package — so humans and agents work from the same source of truth. Fast enough for tight loops, flexible enough for team-level preset composition.

## Features

- **Preset composition** — stack reusable context packs (project, code-review, security-review, team) with intelligent merging
- **Protocol loading** — fetch workflows, guides, prompts, and templates via `wfi://`, `guide://`, `prompt://`, `tmpl://`
- **Smart caching** — auto-format threshold decides inline vs cached output; artifacts in `.ace-local/bundle/`
- **Mixed inputs** — combine presets, file paths, and protocol URLs in a single invocation
- **Section-based output** — XML-style sections for structured, tool-processable context
- **Compression** — optional exact or agent-mode compression via ace-compressor integration
- **11 built-in presets** — project, base, development, team, code-review, security-review, and more

## Works with

- **[ace-support-nav](../ace-support-nav)** — resolves `wfi://`, `guide://`, `prompt://`, `tmpl://` protocol URLs to filesystem paths
- **[ace-git](../ace-git)** — provides diff context, PR metadata, and branch information for review presets
- **[ace-compressor](../ace-compressor)** — optional section-level compression for large context bundles
- **[ace-llm](../ace-llm)** — prompt context loading for LLM-powered workflows

## Agent Skills

- **`as-bundle`** — load project context from preset names, file paths, or protocol URLs
- **`as-onboard`** — load full project context bundle for onboarding to the codebase

See [Handbook Reference](docs/handbook.md) for the complete catalog.

## Documentation

- [Getting Started](docs/getting-started.md) — end-to-end tutorial
- [Usage Guide](docs/usage.md) — full command reference
- [Configuration Reference](docs/configuration.md) — preset format, sections, parameters
- [Handbook Reference](docs/handbook.md) — skills, workflows, presets
- Runtime help: `ace-bundle --help`

## Part of ACE

`ace-bundle` is part of [ACE](../README.md) (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
