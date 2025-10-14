---
update:
  update_frequency: weekly
  max_lines: 150
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2025-10-14'
---

# Project Decisions

This document provides actionable decisions from Architecture Decision Records (ADRs) that directly affect how AI agents and developers should work with this codebase.

## Active Decisions

### Workflow Self-Containment
**Decision**: All AI workflows must be completely self-contained with embedded templates and context. Workflows cannot depend on other workflows or external files except the three standard context documents.
**Impact**: When executing workflows, never load external guides or templates. All necessary information must be within the .wf.md file itself. Only load `docs/what-do-we-build.md`, `docs/architecture.md`, and `docs/blueprint.md` for project context.
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
- All new functionality goes into appropriate ace-* gems at the repository root (15+ gems completed)
- Follow ATOM architecture (atoms/, molecules/, organisms/, models/) in each gem
- Use the root Gemfile for development dependencies
- Run commands with `bundle exec` during development
- Configuration uses .ace/ cascade with nearest/deepest wins (see docs/ace-gems.g.md)
- Legacy dev-tools mostly migrated; dev-handbook migrating to ace-handbook gem
**Details**: [ADR-015](decisions/ADR-015-mono-repo-ace-gems-migration.md)

### ACE Gem Configuration Patterns
**Decision**: All ace-* gems use ace-core's config cascade with standardized .ace/ directory structure.
**Impact**: When creating or modifying gems:
- NEVER use hardcoded config paths or custom config loaders
- Use `Ace::Core.config.get('ace', 'gem_name')` for loading configuration
- Place example configs in `.ace.example/gem-name/` within gem directory
- Support both flat structure (main configs) and nested structure (general configs)
**Details**: [ADR-019](decisions/ADR-019-configuration-architecture.md)

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

### Thor CLI Commands Pattern
**Decision**: All CLI gems use Thor with `lib/ace/gem/commands/` directory for command classes.
**Impact**: Create command classes in `commands/`, use `cli.rb` as Thor entry point, test in `test/commands/`. Commands return exit codes (0/1).
**Details**: [ADR-018](decisions/ADR-018-thor-cli-commands-pattern.md)

### Semantic Versioning and CHANGELOG
**Decision**: All gems must follow semantic versioning and maintain CHANGELOG.md in Keep a Changelog format.
**Impact**: Update CHANGELOG.md with every change, bump versions according to semver (MAJOR for breaking, MINOR for features, PATCH for fixes).
**Details**: [ADR-020](decisions/ADR-020-semantic-versioning-changelog.md)

### Standardized Rakefile
**Decision**: All gems use standardized Rakefile with Rake::TestTask and CI compatibility.
**Impact**: Include `task :spec => :test` for CI, set `default: :test`, use standard test file pattern.
**Details**: [ADR-021](decisions/ADR-021-standardized-rakefile.md)

## Development Tool Decisions

### HTTP Client Strategy
**Decision**: Use Faraday as the standard HTTP client with retry middleware and observability integration.
**Impact**: For all HTTP requests, use Faraday with the standard middleware stack. Never use Net::HTTP directly. Ensure retry logic and monitoring are configured.
**Details**: [ADR-010](decisions/ADR-010-HTTP-Client-Strategy-with-Faraday.t.md)

### ATOM Architecture Rules
**Decision**: Strictly follow ATOM architecture layers: Models (pure data), Molecules (focused operations), Organisms (business orchestration), Ecosystems (complete workflows).
**Impact**: When creating new components in dev-tools:
- Pure data structures go in `models/` (no behavior)
- Focused operations composing Atoms go in `molecules/` (single responsibility)
- Business logic orchestrating Molecules goes in `organisms/` (complex coordination)
- Never place data carriers in `molecules/` or behavior in `models/`
**Details**: [ADR-011](decisions/ADR-011-ATOM-Architecture-House-Rules.t.md)

### Dynamic Provider System
**Decision**: Implement a dynamic provider system for LLM integrations with standardized interfaces.
**Impact**: When adding new LLM providers, follow the established provider interface pattern. Register providers dynamically through the provider system.
**Details**: [ADR-012](decisions/ADR-012-Dynamic-Provider-System-Architecture.t.md)

### Class Naming Conventions
**Decision**: Preserve established technical acronyms in class names (JSONFormatter, HTTPClient, APICredentials) while using CamelCase for domain terms.
**Impact**: When naming classes, keep technical acronyms uppercase (HTTP, API, JSON). Use CamelCase for domain-specific terms (LlmModelInfo, not LLMModelInfo). Note: Zeitwerk-specific inflections are legacy; current gems use explicit requires.
**Details**: [ADR-013](decisions/ADR-013-Class-Naming-Conventions-and-Zeitwerk-Inflections.t.md)

### LLM Integration Architecture
**Decision**: Use hybrid approach for LLM context sizes: API-first with static fallback mappings.
**Impact**: When integrating with LLM providers, first attempt to get context size from API. Maintain static mappings as fallback for providers without API support.
**Details**: [ADR-014](decisions/ADR-014-LLM-Integration-Architecture.t.md)

## Archived Decisions

The following decisions are **archived** as they apply only to legacy `_legacy/dev-tools`:
- **ADR-006**: CI-Aware VCR Configuration (VCR not used in current gems)
- **ADR-007**: Zeitwerk Autoloading (current gems use explicit requires)
- **ADR-008**: Observability with dry-monitor (not used in current gems)
- **ADR-009**: Centralized CLI Error Reporting (superseded by ADR-018 Thor patterns)

See `docs/decisions/archive/README.md` for details on archived decisions.

## Decision History

For complete decision history and detailed rationale, refer to the individual ADR documents in `docs/decisions/`.
