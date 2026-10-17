---
doc-type: bundle
title: ACE - System Architecture
purpose: Documentation for docs/architecture.md
ace-docs:
  last-updated: '2026-10-17'
  last-checked: '2026-10-17'
---

# ACE - System Architecture

## Overview

ACE (Agentic Coding Environment) is a mono-repo ecosystem of modular Ruby gems that provide a deterministic CLI surface
for AI-assisted software development. Both human developers and AI agents use the same tools through consistent
interfaces.

## State ownership

Persisted lab state has one write location and one owner; the canonical map and
executable local flow are in [lab-flow.md](lab-flow.md). Project tasks live in
`.ace-tasks/`; the private overseer list is the gitignored `_overseer` special
folder inside that same task tree (`.ace-tasks/_overseer/`, reached with
`ace-task --in _overseer`). Assignment plans live in `.ace-local/assign/`, HITL
events in `.ace-local/hitl/`, and task worktrees in `.ace-wt/`. There is no
journal, queue engine, authority/admission layer, listener/daemon, topology
registry, or extra state cache; tmux, Herdr, and Hermes are transports only.

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
* **ace-support-***: Shared support packages (`ace-support-config`, `ace-support-fs`, `ace-support-items`, `ace-support-markdown`, `ace-support-models`, `ace-support-nav`, `ace-support-test-helpers`, `ace-support-cli`, `ace-support-mac-clipboard`)
* **ace-bundle**: Project context loading with protocol support
* **ace-docs**: Documentation management with frontmatter-based tracking
* **ace-git**: Unified Git operations and PR context
* **ace-git-commit**: Smart git commit generation with LLM integration
* **ace-git-secrets**: Security scanning and token remediation
* **ace-git-worktree**: Worktree management
* **ace-lint**: Code quality linting (markdown, YAML, frontmatter)
* **ace-llm**: Multi-provider AI model integration with CLI-based providers
* **ace-nav**: Resource discovery and navigation for protocol-backed content
* **ace-prompt-prep**: Prompt workspace with archiving, LLM enhancement, and task integration
* **ace-review**: Preset-based code review with LLM-powered analysis
* **ace-search**: Unified file and content search with auto-detected pattern matching
* **ace-task**: Task and release management with presets
* **ace-idea**: Standalone idea management with B36TS-based IDs (extracted from ace-task)
* **ace-assign**: Multi-step assignment plans and step execution
* **ace-overseer**: Local worktrees, assignments, and status
* **ace-hitl**, **ace-hitl-contract**, **ace-hitl-hermes**: Human-attention event files and adapters
* **ace-handbook**: Handbook asset discovery, projection, and provider sync
* **ace-test**: Test execution and reporting
* **ace-test-runner** / **ace-test-runner-e2e**: CLI test execution and E2E scenarios
* **ace-runtime**, **ace-tmux**, **ace-herdr**: Terminal transport contract and adapters
* **ace-lab**: Read-only lab topology queries today; environment preparation and the installer are planned (L8)

All gems follow ATOM architecture with `handbook/` for agents/workflows. See [ace-gems.g.md](ace-gems.g.md) for
development guide.

### Workflows (.wf.md)

Self-contained instruction documents for complete processes:

* **Location**: `gem/handbook/workflow-instructions/<namespace>/<action>.wf.md`
* **Structure**: Frontmatter (purpose, params, tools) + complete instructions + embedded templates
* **Principle**: ADR-001 self-containment - include all context inline
* **Namespaces**: `task/`, `bug/`, `git/`, `docs/`, `test/`, `e2e/`, `review/`, `handbook/`, `release/`, `assign/`, `lint/`, `search/`, `idea/`, `retro/`, `integration/`
* **Execution**: `ace-bundle wfi://namespace/action`
* **Discovery**: browse with `ace-nav wfi://namespace/*`
* **Use when**: Multi-step process, decision points, context management

### Agents (.ag.md)

Single-purpose, composable agents for focused actions:

* **Location**: `gem/handbook/agents/*.ag.md`, projected by provider integration where a harness needs agent files
* **Design**: Single responsibility, minimal state, standardized responses
* **Use when**: Single command execution, composable operations
* **Examples**: `ace-search` has `search.ag.md` (execute search), `research.ag.md` (multi-search analysis)

### Guides

Development patterns and best practices in `handbook/guides/*.g.md`. Generic guides in `ace-handbook/`, package-specific guides in respective gems.

### Handbook Organization

Each gem includes `handbook/` with `agents/`, `guides/`, `templates/`, and `workflow-instructions/`. General markdown guidance should point readers to workflows through `ace-bundle`; provider-agent skills are a separate integration layer.

## AI Integration

* **Skills**: package `handbook/skills/` files are canonical source of truth for provider-agent integrations and `ace-assign` skill discovery
* **Provider projections**: default sync projects canonical skills into `.agents/skills/`; explicit provider sync can generate harness-native folders (`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`, `.opencode/skills/`, `.pi/skills/`)
* **Provider overrides**: provider-specific frontmatter in `integration.providers.<provider>.frontmatter` can carry execution hints such as Claude `model: role:e2e-reporter` and Codex `model: role:assign-executor`
* **Integration runtime**: `ace-handbook` owns shared provider discovery, projection, sync, and status behavior used by provider packages
* **Agents**: provider integrations project `.ag.md` resources into the harness tree that needs them
* **Deterministic CLI**: Predictable, parseable output for autonomous execution
* **wfi:// Protocol**: Direct workflow access via `ace-bundle`; `ace-nav` remains the discovery layer

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

Settings are deep-merged, so you only specify what differs from defaults. Example: if `ace-git-commit` defaults to `model: role:commit` and your project sets `model: role:review-codex` in `.ace/git/commit.yml`, the project setting wins.

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

Every capability ships as a gem with embedded prompts, agents, and workflows, so
`gem install ace-*` provides the same deterministic surface to humans and
agents. The lab installer and project onboarding are the next planned wave
(L8); the full pre-release and release acceptance waves follow as L9/L10.

*For detailed decisions, see [docs/decisions.md](decisions.md)*
