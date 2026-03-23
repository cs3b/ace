# ace-bundle

Assemble project context for AI agents and developers in one command.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Configuration Reference](docs/configuration.md) | [Handbook Reference](docs/handbook.md)

![ace-bundle demo](docs/demo/ace-bundle-getting-started.gif)

`ace-bundle` helps developers and coding agents load consistent, reusable project context from presets, files, and protocol URLs while staying inside terminal-native workflows.

## Use Cases

**Load baseline project context before coding sessions** - run `ace-bundle project` to gather architecture docs, conventions, and current repository state.

**Pull workflow instructions and guides by protocol URL** - run `ace-bundle wfi://assign/drive` (or `guide://...`, `tmpl://...`, `prompt://...`) to retrieve canonical handbook resources.

**Compose team and task context without manual copy/paste** - combine presets and explicit files in one call to produce targeted context bundles for reviews, implementation, or debugging.

**Handle large context safely in agent loops** - rely on inline-or-cache output behavior and optional compression to keep context payloads manageable.

## Works With

- **[ace-support-nav](../ace-support-nav)** for resolving `wfi://`, `guide://`, `prompt://`, and `tmpl://` protocol URLs.
- **[ace-git](../ace-git)** for diff context, PR metadata, and branch state used by review-oriented presets.
- **[ace-compressor](../ace-compressor)** for optional section-level compression of larger context bundles.
- **[ace-llm](../ace-llm)** for prompt context loading in LLM-powered workflows.

## Features

- Preset composition for reusable context packs (project, code-review, security-review, team) with intelligent merging.
- Protocol loading from `wfi://`, `guide://`, `prompt://`, and `tmpl://`.
- Smart caching with auto-format threshold and artifacts in `.ace-local/bundle/`.
- Mixed input support (preset names, file paths, and protocol URLs) in one invocation.
- Section-based output for structured, tool-processable context.
- Optional exact or agent-mode compression through ace-compressor integration.
- Built-in presets for base onboarding, development, reviews, and team flows.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Configuration Reference](docs/configuration.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-bundle --help`

## Agent Skills

Package-owned canonical skills:

- `as-bundle`
- `as-onboard`

## Part of ACE

`ace-bundle` is part of [ACE](../README.md) (Agentic Coding Environment).
