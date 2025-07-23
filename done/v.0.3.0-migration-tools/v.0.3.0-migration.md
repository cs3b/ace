# v.0.3.0 Migration

## Release Overview
This release focuses on the comprehensive migration of 12 task management and development tools from `dev-tools/exe-old/` into the `coding_agent_tools` Ruby gem architecture. The migration addresses security/stability risks while evolving the codebase to a unified gem-based approach, following the established ATOM pattern.

## Release Information

* **Type**: Feature
* **Start Date**: 2025-01-05
* **Target Date**: 2025-02-23  
* **Status**: Planning

## Collected Notes
From dev-taskflow/backlog/migrate-tools/backlog/plan.md:

- Comprehensive migration of 12 tools from exe-old to coding_agent_tools gem
- Address security/stability risks with current exe-old implementation
- Support architectural evolution toward unified gem-based approach
- 7-week timeline with 5 major phases
- Migrate task management tools (get-next-task, get-recent-tasks, get-all-tasks, get-next-task-id, get-current-release-path.sh)
- Migrate git and project tools (get-recent-git-log, show-directory-tree)
- Migrate quality and linting tools (lint-task-metadata, lint-md-links.rb)
- Migrate documentation tools (markdown-sync-embedded-documents - 442 lines, most complex)
- Migrate utility tools (diff-list-modified-files.rb, fetch-github-pr-data.rb)
- Create comprehensive documentation (docs/tools.md)
- Standardize commit commands (replace bin/git-commit-with-message with bin/gc -i)
- Create binstub implementation guide
- Implement ATOM architecture (atoms/molecules/organisms pattern)
- Update bin/ scripts to use new gem commands transparently
- Extract shell logic from workflows into reusable modules (600+ lines)
- Add context window guidance for review workflows
- Zero disruption to existing workflows during transition
- Maintain exe-old operational throughout migration
- Comprehensive testing with regression tests against exe-old output
- Performance benchmarking to ensure equal or better performance
- 90%+ test coverage requirement
- Update all documentation and workflows to reference gem commands
- Create migration guide and deprecation strategy

## Goals & Requirements

### Primary Goals

* [ ] Migrate all 12 exe-old tools to coding_agent_tools gem with functional parity
* [ ] Achieve zero workflow disruption through transparent bin/ script updates
* [ ] Improve security and stability through ATOM architecture implementation

### Dependencies

* Ruby >= 3.2.0 environment
* Existing coding_agent_tools gem structure
* dry-cli framework
* Access to test repositories for validation

### Risks & Mitigation

* Performance Degradation: Benchmark each tool before/after migration
* Behavioral Differences: Comprehensive regression testing against exe-old output
* Workflow Disruption: Keep exe-old operational, update bin/ scripts atomically

## Implementation Plan

### Core Components

1. **Design & Architecture**
   * [ ] Establish ATOM directory structure for task management
   * [ ] Design CLI command namespaces (task, project)

2. **Dependencies**  
   * [ ] No new external dependencies required
   * [ ] Leverage existing gem dependencies

3. **Implementation Phases**
   * [ ] Phase 1: Foundation & Critical Documentation (Week 1)
   * [ ] Phase 2: Core Task Management Migration (Weeks 2-3)
   * [ ] Phase 3: Extended Features & Parallel Work (Weeks 4-5)
   * [ ] Phase 4: Advanced Features (Week 6)
   * [ ] Phase 5: Finalization & Cleanup (Week 7)

## Quality Assurance

### Test Coverage

* [ ] Unit Tests (>90% coverage for new components)
* [ ] Integration Tests (CLI command testing)
* [ ] Performance Tests (benchmarking vs exe-old)
* [ ] Regression Tests (output comparison)

### Documentation

* [ ] Tool Reference Documentation (docs/tools.md)
* [ ] Binstub Implementation Guide
* [ ] Migration Guide
* [ ] Updated CLAUDE.md

## Release Checklist

* [ ] All 12 tools successfully migrated with identical output
* [ ] All tests passing (unit, integration, regression)
* [ ] Documentation complete and reviewed
* [ ] CHANGELOG.md updated with all changes
* [ ] Version numbers updated in relevant files
* [ ] Security review completed (path validation, input sanitization)
* [ ] Performance benchmarks meet or exceed exe-old
* [ ] Backward compatibility verified (bin/ scripts work transparently)
* [ ] Migration guide prepared
* [ ] Release notes drafted

## Notes
This is a significant architectural migration that will establish the foundation for all future tool development within the gem structure. The phased approach ensures continuous functionality while systematically improving the codebase.