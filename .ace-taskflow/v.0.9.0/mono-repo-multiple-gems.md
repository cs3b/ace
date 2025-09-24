# v.0.9.0 Mono-Repo Multiple Gems

## Release Overview

This release begins the transformation of ACE from its current mixed directory structure into a monorepo with modular Ruby gems. This initial phase creates 4 foundational gems as a proof of concept before migrating the entire system, following a "baby steps" approach to minimize risk and ensure each component works correctly.

## Release Information

- **Type**: Feature (Minor release - new functionality, backward compatible)
- **Start Date**: 2025-09-19
- **Target Date**: 2025-10-03
- **Status**: Planning

## Collected Notes

### User Input
- Transform project structure to monorepo with ace-* prefixed gems
- Start with minimal set of 3 commands to extract:
  - ace-context → includes context method functionality
  - ace-core → shared functionality (config loading with .ace cascade search)
  - ace-git → with only ace-gc (simplified for monorepo without submodules)
  - ace-capture → capture-it functionality
- Move elements part by part from dev-* directories
- After these 3 work, plan next migration phases

### Research Document
- See `docs/research-doc.md` for detailed migration plan and architecture
- Each package is a Ruby gem at repo root with ace-* prefix
- Shared docs & ADRs stay under docs/
- Config and markdown discovery via .ace/ (nearest/deepest wins)
- Tools ship as executables inside their gem
- Agents and humans interact with same deterministic CLI surface

## Goals & Requirements

### Primary Goals

- [ ] Create minimal ace-core gem with .ace config cascade resolution
- [ ] Successfully migrate 3 core commands (context, ace-gc, capture-it)
- [ ] Establish foundation for incremental migration of remaining tools

### Dependencies

- Ruby >= 3.2.0
- Bundler for workspace gem management
- Minitest for testing framework

### Risks & Mitigation

- **Risk**: Breaking existing workflows | **Mitigation**: Keep changes minimal, focus on core functionality first
- **Risk**: Config cascade complexity | **Mitigation**: Start with simple implementation, test thoroughly
- **Risk**: Gem interdependencies | **Mitigation**: ace-core is standalone, others depend only on ace-core

## Implementation Plan

### Core Components

1. **Foundation & Infrastructure**
   - [ ] Create ace-core gem with config cascade
   - [ ] Set up root Gemfile for workspace management
   - [ ] Establish Minitest testing infrastructure
   - [ ] Create integration tests for core functionality

2. **Package Migration**
   - [ ] Migrate ace-context with minimal functionality
   - [ ] Migrate ace-capture for idea capture
   - [ ] Create ace-git with simplified ace-gc command

3. **Configuration & Documentation**
   - [ ] Configure .ace/ for this project
   - [ ] Document migration approach and config system

## Quality Assurance

### Test Coverage

- [ ] Unit tests for config cascade resolution
- [ ] Integration tests for each command
- [ ] Config precedence verification
- [ ] Error handling validation

### Documentation

- [ ] README per gem
- [ ] ADR for monorepo decision
- [ ] Migration guide for future phases
- [ ] Config cascade documentation

## Release Checklist

- [ ] All 4 gems created and functional (ace-core, ace-context, ace-git, ace-capture)
- [ ] Root Gemfile manages workspace dependencies
- [ ] .ace/ config cascade works correctly
- [ ] All Minitest suites passing
- [ ] Each gem has working CLI command
- [ ] Documentation complete
- [ ] ADR created for monorepo approach
- [ ] Roadmap updated with release

## Notes

This is Phase 1 of the larger monorepo migration. We're intentionally keeping scope minimal to:
- Validate the approach with real working code
- Establish patterns for future migrations
- Minimize risk by moving incrementally

Future releases will migrate:
- ace-handbook (workflows, guides, templates)
- ace-taskflow (task management)
- ace-llm (LLM integration)
- Remaining tools and functionality