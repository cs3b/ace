---
doc-type: bundle
title: Project Decisions
purpose: Documentation for docs/decisions.md
ace-docs:
  last-updated: '2026-03-18'
---

# Project Decisions

This document provides actionable decisions from Architecture Decision Records (ADRs) that directly affect how AI agents and developers should work with this codebase.

## Active Decisions

### Workflow Self-Containment
**Decision**: All AI workflows must be completely self-contained with embedded templates and context. Workflows cannot depend on other workflows or external files except the three standard context documents.
**Impact**: When executing workflows, never load external guides or templates. All necessary information must be within the .wf.md file itself. Only load `docs/vision.md`, `docs/architecture.md`, and `docs/blueprint.md` for project context.
**Details**: [ADR-001](decisions/ADR-001-workflow-self-containment-principle.md)

### XML Template Embedding
**Decision**: Use XML format `<documents>` and `<template>` tags for embedding templates within workflow files, placed at the end of the document.
**Impact**: When updating workflows, preserve XML template blocks exactly. Use `handbook sync-templates` command to synchronize embedded templates with source files. Never use four-tick markdown blocks for templates.
**Details**: [ADR-002](decisions/ADR-002-xml-template-embedding-architecture.md)

### Template Directory Structure
**Decision**: All templates must be stored in `dev-handbook/templates/` with standardized subdirectories and `.template.md` extension.
**Impact**: When creating new templates, place them in the appropriate subdirectory (project-docs/, release-tasks/, code-review/, reflections/, task-management/). Always use `.template.md` extension.
**Details**: [ADR-003](decisions/ADR-003-template-directory-separation.md)

### Consistent Path Standards
**Decision**: All document paths must be relative to project root, never absolute. Follow standard patterns like `dev-handbook/templates/**/*.template.md`.
**Impact**: When referencing files in documentation or code, always use paths relative to the project root. Never use absolute paths or paths starting with `./` or `../`.
**Details**: [ADR-004](decisions/ADR-004-consistent-path-standards.md)

### Universal Document Embedding
**Decision**: Use the universal `<documents>` container format for embedding any type of document (templates, guides, examples) in workflows.
**Impact**: When embedding documents in workflows, always use the `<documents>` wrapper with appropriate document type tags. This enables automated synchronization and validation.
**Details**: [ADR-005](decisions/ADR-005-universal-document-embedding-system.md)

## Architecture Decisions

### Mono-Repo Migration to ace-* Gems
**Decision**: Migrate from multi-repository submodule architecture to mono-repo with modular ace-* Ruby gems.
**Impact**: When working with the codebase:
- All new functionality goes into appropriate ace-* gems at the repository root (20+ gems completed)
- Follow ATOM architecture (atoms/, molecules/, organisms/, models/) in each gem
- Use the root Gemfile for development dependencies
- Run commands with `bundle exec` during development
- Configuration uses .ace/ cascade with nearest/deepest wins (see docs/ace-gems.g.md)
- Legacy dev-tools mostly migrated; dev-handbook migrating to ace-handbook gem
**Details**: [ADR-015](decisions/ADR-015-mono-repo-ace-gems-migration.md)

### ACE Gem Configuration Default and Override Pattern
**Decision**: All ace-* gems load defaults from `.ace-defaults/` files and merge with user overrides from `.ace/` cascade using `ace-config` gem.
**Impact**: When creating or modifying gems:
- Put complete defaults in `.ace-defaults/gem-name/config.yml` (single source of truth)
- Use `Ace::Config.create(gem_path: gem_root).resolve_namespace("gem-name")` for configuration cascade
- Use `Ace::Config::Models::Config.wrap(defaults, user_config)` for merging defaults with overrides
- Provide `reset_config!` method for test isolation
- Support backward compatibility for renamed keys with deprecation path
**Status**: All applicable packages compliant (Task 143, Dec 2025). ace-llm deferred (ENV-based). ace-config extracted (Task 157).
**Details**: [ADR-022](decisions/ADR-022-configuration-default-and-override-pattern.md) (supersedes ADR-019)

## Gem Architecture Patterns

### Handbook Directory Architecture
**Decision**: All gems include `handbook/` with `agents/` and `workflow-instructions/` subdirectories for AI integration.
**Impact**: When creating gems:
- Include `handbook/agents/*.ag.md` for single-purpose, composable agents
- Include `handbook/workflow-instructions/*.wf.md` for complete, self-contained workflows
- Symlink to `.claude/agents/` for Claude Code integration
**Details**: [ADR-016](decisions/ADR-016-handbook-directory-architecture.md)

### Flat Test Structure
**Decision**: Tests must use flat structure mirroring ATOM layers: `test/{atoms,molecules,organisms,models,commands}/`
**Impact**: Use `test/atoms/` NOT `test/ace/gem/atoms/` - flat structure only. Simplifies navigation and maintains consistency.
**Details**: [ADR-017](decisions/ADR-017-flat-test-structure.md)

### dry-cli CLI Framework
**Decision**: All CLI gems use dry-cli with `lib/ace/gem/cli/` directory for command classes.
**Impact**: Create command classes in `cli/`. Use multi-command (Registry) pattern for tools with subcommands, or single-command pattern for focused tools. Multi-command CLIs use `HelpCommand.build()` for help display. Commands raise `Ace::Core::CLI::Error` for non-zero exit. Test in `test/commands/`. `-v` reserved for `--verbose`.
**Details**: [ADR-023](decisions/ADR-023-dry-cli-framework.md) (supersedes ADR-018)

### Semantic Versioning and CHANGELOG
**Decision**: All gems must follow semantic versioning and maintain CHANGELOG.md in Keep a Changelog format.
**Impact**: Update CHANGELOG.md with every change, bump versions according to semver (MAJOR for breaking, MINOR for features, PATCH for fixes).
**Details**: [ADR-020](decisions/ADR-020-semantic-versioning-changelog.md)

### No Backward Compatibility Until 1.0.0
**Decision**: No backward compatibility mechanisms will be provided for pre-1.0.0 gems.
**Impact**: When working with gems during pre-1.0 development:
- No require path shims for renamed gems
- No namespace aliases for refactored modules
- No deprecation warnings for breaking changes
- All consumers in mono-repo are updated together
**Status**: Accepted January 2026 - applies until 1.0.0 release
**Details**: [ADR-024](decisions/ADR-024-no-backward-compatibility-pre-1.0.md)

### Standardized Rakefile
**Decision**: All gems use standardized Rakefile with Rake::TestTask and CI compatibility.
**Impact**: Include `task :spec => :test` for CI, set `default: :test`, use standard test file pattern.
**Details**: [ADR-021](decisions/ADR-021-standardized-rakefile.md)

## Development Tool Decisions

### HTTP Client Strategy
**Decision**: Use Faraday as the standard HTTP client with retry middleware and observability integration.
**Impact**: For all HTTP requests, use Faraday with the standard middleware stack. Never use Net::HTTP directly. Ensure retry logic and monitoring are configured.
**Details**: [ADR-010](decisions/ADR-010-HTTP-Client-Strategy-with-Faraday.md)

### ATOM Architecture Rules
**Decision**: Strictly follow ATOM architecture layers: Models (pure data), Molecules (focused operations), Organisms (business orchestration), Ecosystems (complete workflows).
**Impact**: When creating new components in dev-tools:
- Pure data structures go in `models/` (no behavior)
- Focused operations composing Atoms go in `molecules/` (single responsibility)
- Business logic orchestrating Molecules goes in `organisms/` (complex coordination)
- Never place data carriers in `molecules/` or behavior in `models/`
**Details**: [ADR-011](decisions/ADR-011-ATOM-Architecture-House-Rules.md)

### Dynamic Provider System
**Decision**: Implement a dynamic provider system for LLM integrations with standardized interfaces.
**Impact**: When adding new LLM providers, follow the established provider interface pattern. Register providers dynamically through the provider system.
**Details**: [ADR-012](decisions/ADR-012-Dynamic-Provider-System-Architecture.md)

### Class Naming Conventions
**Decision**: Preserve established technical acronyms in class names (JSONFormatter, HTTPClient, APICredentials) while using CamelCase for domain terms.
**Impact**: When naming classes, keep technical acronyms uppercase (HTTP, API, JSON). Use CamelCase for domain-specific terms (LlmModelInfo, not LLMModelInfo). Note: Zeitwerk-specific inflections are legacy; current gems use explicit requires.
**Details**: [ADR-013](decisions/ADR-013-Class-Naming-Conventions-and-Zeitwerk-Inflections.md)

### LLM Integration Architecture
**Decision**: Use hybrid approach for LLM context sizes: API-first with static fallback mappings.
**Impact**: When integrating with LLM providers, first attempt to get context size from API. Maintain static mappings as fallback for providers without API support.
**Details**: [ADR-014](decisions/ADR-014-LLM-Integration-Architecture.md)

### Protocol-Driven Prompt Composition for ace-llm
**Decision**: Compose prompts for ace-llm consumers via protocol-addressable resources and `ace-bundle` (`base`, `sections`, `presets`) instead of hardcoded in-code prompt strings.
**Impact**: When building prompt stacks, use `tmpl://`, `prompt://`, `wfi://` (or file paths) and bundle configuration so users can override behavior through resources/config, not Ruby code edits.
**Details**: [ADR-026](decisions/ADR-026-protocol-driven-prompt-composition-for-ace-llm-via-ace-bundle.md)

### Canonical Skill Platform and Projection Model
**Decision**: Package-owned canonical `handbook/skills/` entries are the source of truth; provider-native skill trees are generated projections with provider-specific frontmatter only.
**Impact**: Put skill contracts, workflow bindings, and schema-valid metadata in canonical package skills. Treat `.claude/skills`, `.codex/skills`, `.gemini/skills`, `.opencode/skills`, and `.pi/skills` as sync outputs, not authored content.
**Details**: [ADR-027](decisions/ADR-027-canonical-skill-platform-and-projection-model.md)

### Assignment Fork Execution and Recovery
**Decision**: Assignment execution is explicitly scopeable (`--assignment <id>@<phase>`) and subtree-first fork delegation, stall handling, and recovery behavior are part of the workflow contract.
**Impact**: Fork-enabled assignment drivers must operate on the targeted subtree, record stall/recovery state, and require completion evidence before reporting success.
**Details**: [ADR-028](decisions/ADR-028-assignment-fork-execution-and-recovery.md)

### Local Artifact Layout Standardization
**Decision**: Runtime artifacts standardize on `.ace-local/<short-name>/...` with short-name paths preferred over package-name paths.
**Impact**: New defaults and docs should use short-name `.ace-local` locations; legacy `.cache/ace-*` and `.ace-local/ace-*` paths are compatibility reads only where already shipped.
**Details**: [ADR-029](decisions/ADR-029-local-artifact-layout-standardization.md)

### Cross-Cutting Compact ID Contract
**Decision**: New artifact/task identifiers use 6-character Base36 compact IDs in the current release line, with explicit compatibility for legacy formats.
**Impact**: New human-facing IDs should be compact and sortable; readers may continue to accept older timestamp or legacy identifiers where persistence already exists.
**Details**: [ADR-030](decisions/ADR-030-cross-cutting-compact-id-contract.md)

### CLI Argument and Execution Contract
**Decision**: Tool/provider delegation normalizes execution to deterministic argv arrays, preserves strict string/array semantics, propagates `working_dir` explicitly, and avoids shell interpolation.
**Impact**: Commands that spawn subprocesses must pass structured arguments and execution context explicitly instead of joining shell strings or inheriting cwd implicitly.
**Details**: [ADR-031](decisions/ADR-031-cli-argument-and-execution-contract.md)

### E2E Rerun and Checkpoint Contract
**Decision**: E2E fix flows require reruns after each fix iteration, scenario-level rerun checkpoints, and a final failure-surface verification gate.
**Impact**: E2E work is not complete when code changes land; completion requires rerun evidence and a final `--only-failures` verification pass on the remaining failure surface.
**Details**: [ADR-032](decisions/ADR-032-e2e-rerun-and-checkpoint-contract.md)

### Git Secrets Security Model
**Decision**: ace-git-secrets uses gitleaks as primary detection with Ruby fallback, multiple defense layers, and documented threat model.
**Impact**: When working with secret detection:
- Use gitleaks integration for production scanning
- Understand confidence levels for effective filtering
- Review reports with `raw_value` for revocation workflows
- Token handling uses memory-backed tmpfs when available
**Details**: [ADR-025](decisions/ADR-025-ace-git-secrets-security-model.md)

### Repository Slug and Naming Strategy
**Decision**: The canonical brand is **ACE**, expanded as **Agentic Coding Environment**. The category framing is **Agentic Development Environment (ADE)**. The repository slug is `ace` (renamed from `ace-meta`). Gem names, CLI binaries, module namespaces, and config directories remain unchanged.
**Impact**: When referencing the project publicly, use "ACE (Agentic Coding Environment)" as the standard introduction. Use "ADE" only in category/positioning contexts. All `spec.homepage` URLs point to `https://github.com/cs3b/ace`. Historical references to `ace-meta` in CHANGELOGs and retrospectives are unchanged.
**Details**: [ADR-033](decisions/ADR-033-repository-slug-and-naming-strategy.md)

## Archived Decisions

ADR-006/007/008 (legacy tech), ADR-009/018/019 (superseded). See `docs/decisions/archive/README.md` for details and `docs/decisions/` for complete history.
