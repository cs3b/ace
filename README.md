# ACE (Agentic Coding Environment) - Monorepo

**Version:** 0.9.0+ | **Architecture:** Modular Ruby Gems | **Status:** Active Development

ACE is a monorepo ecosystem of modular Ruby gems providing deterministic CLI tools for AI-assisted software development. Both human developers and AI agents use the same tools through consistent, predictable interfaces.

## 🎯 What is ACE?

ACE packages development capabilities as installable Ruby gems. Whether it's context loading, task management, git commits, or LLM integration - ACE provides focused, composable tools that work seamlessly with AI coding assistants like Claude Code.

**Key Principle:** Every development capability becomes an installable gem with deterministic CLI commands.

## 📦 Available Gems

All gems follow the `ace-*` naming convention and ATOM architecture pattern:

| Gem | Command(s) | Purpose |
|-----|------------|---------|
| **ace-support-core** | `ace-framework` | Configuration cascade, shared utilities foundation |
| **ace-context** | `ace-context` | Project context loading with smart caching |
| **ace-git-commit** | `ace-git-commit` | LLM-powered smart commit message generation |
| **ace-llm** | `ace-llm-query` | Multi-provider LLM integration (Claude, OpenAI, etc.) |
| **ace-llm-providers-cli** | `ace-llm-providers-cli-check` | CLI-based LLM provider support |
| **ace-nav** | `ace-nav` | Resource discovery and wfi:// protocol navigation |
| **ace-taskflow** | `ace-taskflow` | Task, release, and idea management |
| **ace-test-runner** | `ace-test`, `ace-test-suite` | Test execution with parallel processing |
| **ace-test-support** | _(library)_ | Shared testing infrastructure for all gems |

Each gem is independently installable: `gem install ace-context ace-taskflow`

## 🏗️ Monorepo Structure

As of v0.9.0, ACE uses a monorepo architecture (migrated from Git submodules):

```
ace-meta/
├── ace-support-core/      # Foundation gem (zero dependencies)
├── ace-context/           # Context loading
├── ace-git-commit/        # Git commit tool
├── ace-llm/               # LLM integration
├── ace-llm-providers-cli/ # CLI provider support
├── ace-nav/               # Resource navigation
├── ace-taskflow/          # Task management (includes idea capture)
├── ace-test-runner/       # Test execution
├── ace-test-support/      # Testing infrastructure
├── .ace/                  # Configuration root (cascade system)
├── docs/                  # System documentation and ADRs
├── ace-handbook/          # Handbook gem (workflows, guides, templates)
└── Gemfile                # Shared workspace dependencies
```

**Migration Note:** See `docs/migrations/v0.9.0-monorepo-phase1.md` for detailed migration guide from the old submodule structure.

## 🚀 Quick Start

### Installation (End Users)

Install specific gems you need:

```bash
gem install ace-context ace-taskflow ace-git-commit
```

Or use the monorepo for development:

```bash
git clone https://github.com/your-org/ace-meta.git
cd ace-meta
bundle install
```

### Usage Examples

```bash
# Load project context (preset, file path, or protocol)
ace-context project
ace-context ./docs/custom-context.md
ace-context wfi://load-context

# List available presets
ace-context --list

# Get next task to work on
ace-taskflow task

# List current tasks
ace-taskflow tasks --current

# Create smart commit
ace-git-commit -i "fixing authentication bug"

# Navigate to workflow
ace-context wfi://work-on-task

# Run tests
ace-test test/specific_test.rb
ace-test-suite  # Run all tests
```

### Development

```bash
# From monorepo root
bundle install

# Run commands with bundle exec
bundle exec ace-context project
bundle exec ace-taskflow tasks --current

# Test specific gem
cd ace-support-core
bundle exec rake test

# Test all gems
bundle exec ace-test-suite
```

## ⚙️ Configuration System

ACE uses a cascade configuration system with `.ace/` directories:

```
./.ace/          # Project-specific (highest priority)
~/.ace/          # User defaults
gem defaults     # Bundled with each gem (lowest priority)
```

**Resolution:** Nearest/deepest wins (project → user → gem defaults)

Each gem has its own config namespace:
- `.ace/core/config/core.yml`
- `.ace/context/config/context.yml`
- `.ace/taskflow/config/taskflow.yml`

See `docs/architecture.md` for complete configuration details.

## 🧬 ATOM Architecture

All gems follow the ATOM pattern for consistent, testable code:

- **Atoms**: Pure functions, no side effects
- **Molecules**: Composed operations with controlled side effects
- **Organisms**: Business logic orchestration
- **Models**: Pure data structures

See `docs/ace-gems.g.md` for gem development guide.

## 📚 Documentation

- **Architecture:** [`docs/architecture.md`](docs/architecture.md) - System architecture and patterns
- **Gem Development:** [`docs/ace-gems.g.md`](docs/ace-gems.g.md) - Creating new ace-* gems
- **Migration Guide:** [`docs/migrations/v0.9.0-monorepo-phase1.md`](docs/migrations/v0.9.0-monorepo-phase1.md) - v0.9.0 changes
- **Decisions:** [`docs/decisions/`](docs/decisions/) - Architecture Decision Records
- **Tools Reference:** [`docs/tools.md`](docs/tools.md) - Quick command reference

Each gem has its own README in its directory.

## 🤖 AI Integration

ACE provides two types of commands: **Claude Commands** (slash commands for Claude Code chat) and **CLI Tools** (terminal commands).

### Command Types at a Glance

| Type | Where to Run | Prefix | Example |
|------|--------------|--------|---------|
| **Claude Commands** | Claude Code chat | `/ace:` | `/ace:work-on-task 121` |
| **CLI Tools** | Terminal (bash/fish) | `ace-` | `ace-taskflow task 121` |

### Claude Commands (Slash Commands)

Run in Claude Code conversation by typing directly in chat:

| Command | Purpose |
|---------|---------|
| `/ace:load-context [preset]` | Load project context with AI assistance |
| `/ace:work-on-task [id]` | Work on a task with full agent context |
| `/ace:commit` | Generate intelligent commit with LLM |
| `/ace:review-pr [pr-number]` | Review PR with AI analysis |
| `/ace:draft-task` | Draft a new task specification |
| `/ace:draft-release` | Draft a release with changelog |

These commands invoke AI-assisted workflows that leverage Claude's understanding of your codebase.

### CLI Tools (Terminal Commands)

Run in your terminal for deterministic operations:

```bash
# Task management
ace-taskflow task 148        # Show task details
ace-taskflow tasks --current # List current tasks

# Git operations
ace-git-commit --staged      # Generate commit message
ace-git status               # Full repo context

# Code review
ace-review --preset pr       # Run code review preset

# Testing
ace-test atoms               # Run atom tests
ace-test-suite               # Full test suite
```

See [docs/tools.md](docs/tools.md) for complete CLI reference.

### wfi:// Protocol

Navigate workflows directly from terminal:

```bash
ace-context wfi://work-on-task
ace-context wfi://load-context
```

Workflows are self-contained with embedded templates following ADR-001.

## 🎯 Core Principles

1. **Modular Gems**: Each capability is a focused, independently installable gem
2. **Zero-Dependency Core**: ace-support-core uses only Ruby standard library
3. **Deterministic Commands**: Consistent, parseable output for AI agents
4. **Configuration Cascade**: Project → User → Gem defaults with deep merging
5. **ATOM Architecture**: Consistent patterns across all gems
6. **AI-Native Design**: Commands designed for autonomous agent execution

## 🔄 Legacy Components

The following directories have been archived to `_legacy/`:

- **dev-handbook/**: Migrated to `ace-handbook` gem ✅
- **dev-tools/**: Functionality migrated to various ace-* gems ✅
- **.ace-taskflow/**: Now managed by `ace-taskflow` gem ✅

The `_legacy/` directory contains archived content from the previous multi-repo structure and can be safely removed.

## 🛠️ Development Workflow

### For Contributors

1. **Clone and Setup:**
   ```bash
   git clone https://github.com/your-org/ace-meta.git
   cd ace-meta
   bundle install
   ```

2. **Make Changes:**
   - Work in specific gem: `ace-*/lib/`, `ace-*/test/`
   - Follow ATOM architecture pattern
   - Write tests for new functionality

3. **Test:**
   ```bash
   # Test specific gem
   cd ace-your-gem
   bundle exec rake test

   # Test all
   bundle exec ace-test-suite
   ```

4. **Document:**
   - Update gem README
   - Add examples
   - Update CHANGELOG

See `docs/ace-gems.g.md` for detailed gem development guide.

## 📋 Version History

- **v0.9.0**: Monorepo migration with modular ace-* gems
- **v0.8.x**: Legacy submodule structure (deprecated)

## 🌟 Getting Help & Contributing

- **Issues**: [GitHub Issues](https://github.com/your-org/ace-meta/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/ace-meta/discussions)
- **Documentation**: Check `docs/` directory and individual gem READMEs
- **Architecture**: See ADRs in `docs/decisions/`

### Contributing Guidelines

1. Fork the repository
2. Create a feature branch
3. Make your changes following ATOM architecture
4. Write tests (aim for high coverage)
5. Update documentation
6. Submit a pull request

See `docs/ace-gems.g.md` for gem development guidelines.

## 📄 License

[Specify your license here]

## 🙏 Acknowledgments

ACE is designed for AI-assisted development and works seamlessly with:
- [Claude Code](https://claude.ai/code) - Anthropic's AI coding assistant
- Other AI coding tools supporting deterministic CLI interfaces

---

**ACE: Making AI-assisted development as simple as `gem install ace-*`**
