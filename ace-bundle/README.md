# ace-bundle

Assemble project context for AI agents and developers in one command.

![ace-bundle demo](docs/demo/ace-bundle-getting-started.gif)

## Why ace-bundle

`ace-bundle` collects context from presets, files, and protocol resources so humans and agents can work from the same source package. It is fast enough for tight loops and flexible enough for team-level preset composition.

## Quick Start

Run:

```bash
gem install ace-bundle
ace-bundle project
```

That command loads the default project context and prints or caches output based on preset settings.

## Features

- Preset composition for reusable team context packs
- Smart caching through `.ace-local/bundle/` artifacts
- Protocol loading (`wfi://`, `guide://`, `task://`) through `ace-nav`
- Mixed inputs: presets, file paths, and ad-hoc config files

## Documentation

- [Getting Started](docs/getting-started.md)
- [Configuration Reference](docs/configuration.md)
- Runtime help: `ace-bundle --help`

## Common Commands

Examples:

```bash
ace-bundle project
ace-bundle project-base
ace-bundle --list
ace-bundle wfi://task/plan
```

## Part of ACE

`ace-bundle` is part of ACE (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
