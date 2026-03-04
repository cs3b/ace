---
update:
  update_frequency: weekly
  max_lines: 160
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2026-02-23'
---

# ACE - System Architecture

## Overview

ACE (Agentic Coding Environment) is a mono-repo ecosystem of modular Ruby gems that provide a deterministic CLI surface
for AI-assisted software development. Both human developers and AI agents use the same tools through consistent
interfaces.

## Scope

This document covers the technical architecture of ACE:
- Component organization and ATOM pattern
- Configuration cascade (ADR-022)
- Key architectural decisions
- Security and quality standards

For the project vision and core principles, see [vision.md](vision.md). For CLI usage, see [tools.md](tools.md).

## ATOM Architecture Pattern

All ace-\* gems follow the ATOM pattern for consistent, testable code organization:

### Atoms (Pure Functions)

* No side effects or external dependencies
* Single, well-defined purpose
* Examples: `yaml_parser`, `deep_merger`, `path_expander`

### Molecules (Composed Operations)

* Combine atoms to perform specific operations
* May have controlled side effects (file I/O)
* Examples: `yaml_loader`, `config_finder`, `context_chunker`

### Organisms (Business Logic)

* Orchestrate molecules to implement features
* Handle complex workflows and coordination
* Examples: `config_resolver`, `context_loader`, `test_orchestrator`

### Models (Data Structures)

* Pure data carriers with no business logic
* Immutable value objects preferred
* Examples: `config`, `context_data`, `test_result`

### Implementation

All gems use flat directory structure: `lib/ace/gem/{atoms,molecules,organisms,models}/` with `cli/commands/` for dry-cli. CLIs use either multi-command (Registry) or single-command pattern. See [ADR-023](decisions/ADR-023-dry-cli-framework.md).
Tests mirror this in `test/{atoms,molecules,organisms,models,commands}/` (flat, not nested).

## Component Types

### Tools (ace-\* gems)

Modular Ruby gems providing focused CLI functionality:

* **ace-support-core**: Configuration management foundation
* **ace-bundle**: Project context loading with protocol support
* **ace-docs**: Documentation management with frontmatter-based tracking
* **ace-git**: Unified Git operations and PR context
* **ace-git-commit**: Smart git commit generation with LLM integration
* **ace-git-secrets**: Security scanning and token remediation
* **ace-git-worktree**: Worktree management
* **ace-lint**: Code quality linting (markdown, YAML, frontmatter)
* **ace-llm**: Multi-provider AI model integration with CLI-based providers
* **ace-nav**: Resource discovery and navigation with wfi:// protocol
* **ace-prompt-prep**: Prompt workspace with archiving, LLM enhancement, and task integration
* **ace-review**: Preset-based code review with LLM-powered analysis
* **ace-search**: Unified file and content search with auto-detected pattern matching
* **ace-taskflow**: Task and release management with presets
* **ace-idea**: Standalone idea management with B36TS-based IDs (extracted from ace-taskflow)
* **ace-test**: Test execution and reporting
* **ace-test-support**: Shared testing infrastructure

All gems follow ATOM architecture with `handbook/` for agents/workflows. See [ace-gems.g.md](ace-gems.g.md) for
development guide.

### Workflows (.wf.md)

Self-contained instruction documents for complete processes:

* **Location**: `gem/handbook/workflow-instructions/<namespace>/<action>.wf.md`
* **Structure**: Frontmatter (purpose, params, tools) + complete instructions + embedded templates
* **Principle**: ADR-001 self-containment - include all context inline
* **Namespaces**: `task/`, `bug/`, `git/`, `docs/`, `test/`, `e2e/`, `review/`, `handbook/`, `release/`, `assign/`, `lint/`, `search/`, `idea/`, `retro/`, `integration/`
* **Discovery**: `ace-bundle wfi://namespace/action` or browse with `ace-nav wfi://namespace/*`
* **Use when**: Multi-step process, decision points, context management

### Agents (.ag.md)

Single-purpose, composable agents for focused actions:

* **Location**: `gem/handbook/agents/*.ag.md`, symlinked to `.claude/agents/`
* **Design**: Single responsibility, minimal state, standardized responses
* **Use when**: Single command execution, composable operations
* **Examples**: `ace-search` has `search.ag.md` (execute search), `research.ag.md` (multi-search analysis)

### Guides

Development patterns and best practices in `handbook/guides/*.g.md`. Generic guides in `ace-handbook/`, package-specific guides in respective gems.

### Handbook Organization

Each gem includes `handbook/` with `agents/`, `guides/`, `templates/`, and `workflow-instructions/`. Agents are for single actions, workflows for multi-step processes. Both use frontmatter.

## AI Integration

* **Skills**: `.agent/skills/` is the canonical provider-neutral location; provider dirs (`.claude/`, `.codex/`, `.gemini/`, `.pi/`) symlink to it
* **Agents**: `.claude/agents/` provides agent access via frontmatter-defined capabilities
* **Deterministic CLI**: Predictable, parseable output for autonomous execution
* **wfi:// Protocol**: Direct workflow access via ace-nav

## Key Architectural Decisions

* **ADR-015 Mono-Repo**: Each capability as focused ace-\* gem with simplified dependencies
* **ADR-011 ATOM Pattern**: Clean separation of concerns; consistent across gems; testable structure
* **ADR-001 Workflow Self-Containment**: Include all templates inline; no external dependencies
* **ADR-022 Configuration Cascade**: Four-tier merge (CLI > Project > User > Gem defaults)
* **Zero-Dependency Core**: ace-support-core uses only Ruby stdlib

## Configuration Cascade

The configuration system (ADR-022) uses a four-tier cascade with nearest-wins resolution:

1. **CLI Flags** - immediate overrides for this invocation
2. **Project `.ace/`** - repository-specific settings (committed)
3. **User `~/.ace/`** - personal preferences across projects
4. **Gem `.ace-defaults/`** - sensible defaults

Settings are deep-merged, so you only specify what differs from defaults. Example: if `ace-git-commit` defaults to `model: glite` and your project sets `model: gflash` in `.ace/git/commit.yml`, the project setting wins.

```ruby
resolver = Ace::Support::Config.create
config = resolver.resolve_namespace("git", filename: "commit")
# Gem defaults + user + project + CLI = final config
```

## Security & Quality

* Path validation, input sanitization, comprehensive test coverage
* CI/CD with GitHub Actions matrix testing across Ruby versions
* Deterministic, predictable command output

## Future Vision

**ace-handbook gem**: Workflows, guides, templates as installable gem. Every capability becomes a gem with embedded
prompts, agents, workflows - instantly available via `gem install ace-*`.

*For detailed decisions, see [docs/decisions.md](decisions.md)*

