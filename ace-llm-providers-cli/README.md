# ace-llm-providers-cli

CLI-backed provider adapters for `ace-llm`.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-llm-providers-cli` extends `ace-llm` with provider clients that execute through installed CLI tools while preserving the shared `ace-llm` command interface.

## How It Works

1. The gem loads CLI provider clients on require.
2. Provider defaults are read from `.ace-defaults/llm/providers/*.yml` and can be overridden through normal ACE config cascade.
3. `ace-llm` routes model calls to these provider clients, which execute subprocess commands and return normalized responses.

## Use Cases

**Use CLI-native providers through one `ace-llm` surface** - run prompts against Claude, Codex, OpenCode, Gemini, pi, and Codex OSS without changing calling conventions.

**Keep provider configuration in versioned YAML** - tune models and provider behavior via config instead of custom glue code.

**Diagnose local provider readiness quickly** - verify installed/authenticated tools using `ace-llm-providers-cli-check`.

## Works With

- **[ace-llm](../ace-llm)** for unified provider abstraction and prompt execution.
- **[ace-support-config](../ace-support-config)** for layered provider configuration overrides.
- **[ace-support-cli](../ace-support-cli)** for consistent command behavior across ACE tooling.

## Features

- CLI provider clients for Claude, Codex, OpenCode, Gemini, pi, and Codex OSS.
- Automatic provider registration during gem load.
- Safe subprocess capture utilities used by provider clients.
- Health-check executable for common CLI provider environments.

## Quick Start

Install package:

```bash
bundle add ace-llm-providers-cli

```

Check local CLI provider availability and auth:

```bash
ace-llm-providers-cli-check

```

Use through `ace-llm`:

```bash
ace-llm claude:sonnet "Summarize this module"
ace-llm codex:gpt-5 "Review this Ruby file"

```

## CLI Prerequisites

Install and authenticate whichever provider CLIs you plan to use. The checker currently validates:

- Claude Code (`claude`)
- Codex (`codex`)
- OpenCode (`opencode`)
- Codex OSS (`codex-oss`)

Run:

```bash
ace-llm-providers-cli-check

```

## Documentation

- Command help: `ace-llm-providers-cli-check --help`
- Package changelog: [CHANGELOG.md](CHANGELOG.md)
- Runtime implementation: `lib/ace/llm/providers/cli/`

## Agent Skills

`ace-llm-providers-cli` currently ships no package-owned canonical skills.

## Part of ACE

`ace-llm-providers-cli` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
