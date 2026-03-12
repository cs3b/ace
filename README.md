# ACE (Agentic Coding Environment)

ACE is a modular toolkit for AI-assisted software development, easily customizable per user and per project.

Both human developers and AI agents use the same tools through consistent, predictable interfaces. Every capability is an installable gem with CLI commands that work identically whether typed by a developer or executed by an agent.

## Key Capabilities

| Tool | Purpose |
|------|---------|
| **ace-review** | Multi-model code review with configurable presets |
| **ace-git-commit** | LLM-powered commit message generation |
| **ace-git-worktree** | Git worktree management for task isolation |
| **ace-bundle** | Project context loading with smart caching |
| **ace-taskflow** | Task, release, and idea management |
| **ace-search** | Unified file and content search |

Each gem is independently installable: `gem install ace-review ace-git-commit`

> See [docs/architecture.md](docs/architecture.md#tools-ace--gems) for the complete list of available capabilities.

## Quick Start: ace-review

Install and run a multi-model code review:

```bash
gem install ace-review

# Review current PR with default preset
ace-review --pr 123

# Review with a specific preset
ace-review --preset code-deep --pr 123
```

**Configuration** (`.ace/review/config.yml`):

```yaml
defaults:
  preset: "code"
  model: "google:gemini-2.5-flash"
  auto_execute: true
```

**Workflow-first usage:**

```bash
# Load the canonical review workflow instructions
ace-bundle wfi://review/pr
```

Provider-specific skills exist for CLI agents and `ace-assign` discovery, but the default documentation path in ACE is direct `ace-*` commands plus `ace-bundle wfi://...` for multi-step workflows.

> See [ace-review/README.md](ace-review/README.md) for full documentation. Each tool has its own README with detailed usage.

## Core Principles

1. **Same Environment, Same Tools** - Humans and agents use identical CLI commands
2. **DX/AX Dual Optimization** - Excellent for both developer and agent experience
3. **Configuration Without Lock-In** - Override defaults at any level
4. **Distribution Without Friction** - Every capability is an installable gem

## Configuration

ACE uses a cascade configuration system:

```
CLI flags        # Command-line arguments (highest priority)
./.ace/          # Project-specific
~/.ace/          # User defaults
gem defaults     # Bundled with each gem (lowest priority)
```

## Documentation

| Document | Purpose |
|----------|---------|
| [Vision](docs/vision.md) | Why ACE exists and core principles (manifesto) |
| [Architecture](docs/architecture.md) | System architecture and ATOM pattern |
| [Tools Reference](docs/tools.md) | CLI command quick reference |

## Contributing

See [docs/contributing/](docs/contributing/) for development setup and contribution guidelines.

## License

MIT License - See LICENSE file.
