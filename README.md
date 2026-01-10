# ACE (Agentic Coding Environment)

**Version:** 0.9.0+ | **Architecture:** Modular Ruby Gems | **Status:** Active Development

ACE is a monorepo ecosystem of modular Ruby gems providing deterministic CLI tools for AI-assisted software development. Both human developers and AI agents use the same tools through consistent, predictable interfaces.

## What is ACE?

ACE packages development capabilities as installable Ruby gems. Each gem includes CLI tools, agents, and workflows - making it a complete, reusable capability. Whether it's context loading, task management, git commits, or LLM integration - ACE provides focused, composable tools that work seamlessly with AI coding assistants like Claude Code.

**Core Principle:** Every development capability becomes an installable gem with deterministic CLI commands.

## Available Gems

| Gem | Command(s) | Purpose |
|-----|------------|---------|
| **ace-context** | `ace-context` | Project context loading with smart caching |
| **ace-git** | `ace-git` | Unified Git operations (status, diff, branch, PR) |
| **ace-git-commit** | `ace-git-commit` | LLM-powered smart commit message generation |
| **ace-lint** | `ace-lint` | Code quality linting (markdown, YAML, frontmatter) |
| **ace-llm** | `ace-llm-query` | Multi-provider LLM integration |
| **ace-nav** | `ace-nav` | Resource discovery and wfi:// protocol navigation |
| **ace-review** | `ace-review` | Preset-based code review with LLM analysis |
| **ace-search** | `ace-search` | Unified file and content search |
| **ace-taskflow** | `ace-taskflow` | Task, release, and idea management |
| **ace-test-runner** | `ace-test` | Test execution with parallel processing |
| **ace-support-core** | _(library)_ | Configuration cascade and shared utilities |

Each gem is independently installable: `gem install ace-context ace-taskflow`

> **Note:** This table shows core CLI gems. See [docs/vision.md](docs/vision.md#current-capabilities) for additional gems including ace-docs, ace-git-secrets, ace-git-worktree, ace-prompt, and ace-llm-providers-cli.

## Quick Start

### Installation

```bash
# Install specific gems
gem install ace-context ace-taskflow ace-git-commit

# Or clone for development
git clone https://github.com/your-org/ace-meta.git
cd ace-meta && bundle install
```

### Usage Examples

```bash
# Load project context
ace-context project

# Get next task to work on
ace-taskflow task

# Create smart commit
ace-git-commit -i "fixing authentication bug"

# Review code changes
ace-review --preset pr

# Run tests
ace-test test/specific_test.rb
```

### Claude Code Integration

| Type | Where to Run | Prefix | Example |
|------|--------------|--------|---------|
| Claude Commands | Chat | `/ace:` | `/ace:work-on-task 121` |
| CLI Tools | Terminal | `ace-` | `ace-taskflow task 121` |

Key Claude commands: `/ace:load-context`, `/ace:work-on-task`, `/ace:commit`, `/ace:review-pr`

## Documentation

| Document | Purpose |
|----------|---------|
| [Vision](docs/vision.md) | Why ACE exists, core principles, workflow examples |
| [Architecture](docs/architecture.md) | System architecture and ATOM pattern |
| [Tools Reference](docs/tools.md) | CLI command quick reference |
| [Gem Development](docs/ace-gems.g.md) | Creating new ace-* gems |
| [Blueprint](docs/blueprint.md) | Codebase navigation guide |
| [Decisions](docs/decisions/) | Architecture Decision Records |

Each gem has its own README in its directory.

## Project Structure

ACE is organized as a mono-repo where each gem is developed and versioned together, enabling seamless cross-gem integration and consistent tooling.

```
ace-meta/
├── ace-context/           # Context loading
├── ace-git/               # Git operations
├── ace-git-commit/        # Commit generation
├── ace-lint/              # Code linting
├── ace-llm/               # LLM integration
├── ace-nav/               # Resource navigation
├── ace-review/            # Code review
├── ace-search/            # File search
├── ace-taskflow/          # Task management
├── ace-test-runner/       # Test execution
├── ace-support-core/      # Foundation (zero dependencies)
├── .ace/                  # Configuration cascade root
├── docs/                  # System documentation
└── Gemfile                # Shared dependencies
```

## Configuration

ACE uses a cascade configuration system:

```
./.ace/          # Project-specific (highest priority)
~/.ace/          # User defaults
gem defaults     # Bundled with each gem (lowest priority)
```

Resolution: Nearest wins (project → user → gem defaults)

## Core Principles

1. **Same Environment, Same Tools** - Humans and agents use identical CLI commands
2. **DX/AX Dual Optimization** - Excellent for both developer and agent experience
3. **Configuration Without Lock-In** - Override defaults at any level
4. **Distribution Without Friction** - Every capability is an installable gem
5. **ATOM Architecture** - Consistent patterns across all gems
6. **AI-Native Design** - Deterministic output for autonomous execution

## Development

```bash
# Run commands via mono-repo binstubs
./bin/ace-context project

# Test specific gem
cd ace-your-gem && bundle exec rake test

# Test all gems
bundle exec ace-test-suite
```

See [docs/ace-gems.g.md](docs/ace-gems.g.md) for gem development guide.

## License

MIT License - See LICENSE file.

---

**ACE: Making AI-assisted development as simple as `gem install ace-*`**
