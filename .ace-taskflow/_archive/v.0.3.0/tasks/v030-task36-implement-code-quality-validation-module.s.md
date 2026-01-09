---
id: v.0.3.0+task.36
status: done
priority: medium
estimate: 18h
dependencies: [v.0.3.0+task.06, v.0.3.0+task.34]
---

# Implement Multi-Phase Code Quality Orchestration System

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/lib/coding_agent_tools/cli/commands | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools/lib/coding_agent_tools/cli/commands
    ├── code
    │   ├── review_prepare
    │   └── review.rb
    ├── install_binstubs.rb
    ├── llm
    │   ├── models.rb
    │   ├── query.rb
    │   └── usage_report.rb
    ├── release
    │   ├── all.rb
    │   ├── current.rb
    │   ├── generate_id.rb
    │   └── next.rb
    ├── task
    │   ├── all.rb
    │   ├── generate_id.rb
    │   ├── next.rb
    │   └── recent.rb
    └── task.rb
    
    6 directories, 14 files
```

## Objective

Create a comprehensive 3-phase code quality orchestration system that integrates existing linting tools, adds moderate autofix capabilities, and provides foundation for agent-based error resolution. The system follows ATOM architecture principles and supports configuration-driven pipeline orchestration.

**Vision**: `Phase 1: Detection & Validation → Phase 2: Moderate Autofix & Error Distribution → Phase 3: Agent Coordination Foundation`

## Scope of Work

### Three-Phase Implementation Strategy

**Phase 1: Core Linting Infrastructure**
- Integrate existing linting tools (lint-security, lint-cassettes, lint-task-metadata, lint-md-links.rb)
- Create new validators (StandardRB, Template Embedding, Kramdown Formatter)
- Implement ATOM architecture with unified CLI interface
- Support .coding-agent/lint.yml configuration with project root override
- **Path Handling**: Support execution from any directory level using ProjectRootDetector

**Phase 2: Moderate Autofix & Error Distribution**
- Implement moderate-level autofix capabilities with re-validation
- Create even error distribution system (.lint-errors-{1-4}.md files)
- Ensure one issue per file to prevent agent conflicts
- Add comprehensive diff review for all changes

**Phase 3: Agent Integration Foundation**
- Design extensibility hooks for future agent coordination
- Create fix-linting-issue-from.wf.md workflow instruction
- Build foundation for 4-agent parallel processing
- Implement final change review and validation

### Updated Architecture Based on Requirements

**Command Structure:**
```
code-lint (orchestrator with .coding-agent/lint.yml config)
├── ruby (run all Ruby linters)
│   ├── standardrb
│   ├── security (existing lint-security)
│   └── cassettes (existing lint-cassettes)
└── markdown (run in configured order)
    ├── styleguide (kramdown-based)
    ├── link-validation (existing lint-md-links.rb)
    ├── template-embedding (new, based on .ace/handbook/guides/documents-embedding.g.md)
    └── task-metadata (existing lint-task-metadata)
```

**Key Technical Decisions:**
1. **Markdown Formatter**: kramdown gem (eliminates Node.js dependency)
2. **Error Distribution**: Even distribution across 4 files, one issue per file
3. **Configuration**: .coding-agent/lint.yml in project root overrides defaults
4. **Autofix Safety**: Moderate level (safe formatting, basic refactoring)
5. **Final Review**: Comprehensive diff analysis of all changes
6. **Path Handling**: Support execution from any directory level using ProjectRootDetector

### Existing Tools Integration

**Ruby Linters:**
- **lint-security** (.ace/tools/bin/lint-security) → SecurityValidator atom
- **lint-cassettes** (.ace/tools/bin/lint-cassettes) → CassettesValidator atom
- **standardrb** (external) → StandardRbValidator atom

**Markdown Linters:**
- **lint-task-metadata** (.ace/taskflow/.../lint-task-metadata) → TaskMetadataValidator atom
- **lint-md-links.rb** (.ace/taskflow/.../lint-md-links.rb) → MarkdownLinkValidator atom
- **template-embedding** (new) → TemplateEmbeddingValidator atom
- **kramdown formatter** (new) → KramdownFormatter atom

### Deliverables

#### Create

**Executable & CLI**
- exe/code-lint (standalone executable with ExecutableWrapper)
- lib/coding_agent_tools/cli/commands/code/lint.rb (CLI command integration)

**ATOM Architecture Components**
- lib/coding_agent_tools/atoms/code_quality/security_validator.rb
- lib/coding_agent_tools/atoms/code_quality/cassettes_validator.rb
- lib/coding_agent_tools/atoms/code_quality/task_metadata_validator.rb
- lib/coding_agent_tools/atoms/code_quality/markdown_link_validator.rb
- lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb
- lib/coding_agent_tools/atoms/code_quality/template_embedding_validator.rb
- lib/coding_agent_tools/atoms/code_quality/kramdown_formatter.rb
- lib/coding_agent_tools/atoms/code_quality/configuration_loader.rb
- lib/coding_agent_tools/atoms/code_quality/error_distributor.rb
- lib/coding_agent_tools/atoms/code_quality/path_resolver.rb
- lib/coding_agent_tools/molecules/code_quality/ruby_linting_pipeline.rb
- lib/coding_agent_tools/molecules/code_quality/markdown_linting_pipeline.rb
- lib/coding_agent_tools/molecules/code_quality/autofix_orchestrator.rb
- lib/coding_agent_tools/molecules/code_quality/error_file_generator.rb
- lib/coding_agent_tools/molecules/code_quality/diff_review_analyzer.rb
- lib/coding_agent_tools/organisms/code_quality/multi_phase_quality_manager.rb
- lib/coding_agent_tools/organisms/code_quality/validation_workflow_manager.rb
- lib/coding_agent_tools/organisms/code_quality/agent_coordination_foundation.rb

**Models & Configuration**
- lib/coding_agent_tools/models/validation_result.rb
- lib/coding_agent_tools/models/autofix_operation.rb
- lib/coding_agent_tools/models/linting_config.rb
- lib/coding_agent_tools/models/error_distribution.rb

**Configuration & Workflow**
- .coding-agent/lint.yml (default configuration template)
- .ace/handbook/workflow-instructions/fix-linting-issue-from.wf.md

**Comprehensive Test Suite**
- Corresponding spec files for all ATOM components
- Integration tests for multi-phase pipeline
- CLI tests using Aruba framework

#### Modify

- lib/coding_agent_tools/cli.rb (register code lint CLI command)
- coding_agent_tools.gemspec (add kramdown dependency)

#### Extract & Integrate

- .ace/tools/bin/lint-security → SecurityValidator atom
- .ace/tools/bin/lint-cassettes → CassettesValidator atom
- .ace/taskflow/.../lint-task-metadata → TaskMetadataValidator atom
- .ace/taskflow/.../lint-md-links.rb → MarkdownLinkValidator atom

#### Delete

- None (preserve existing tools during transition)

## Phases

### Phase 1: Core Linting Infrastructure (Hours 1-8)
1. Extract existing linting tools into ATOM structure
2. Create kramdown-based markdown formatter
3. Implement template embedding validator (based on documents-embedding.g.md)
4. Build unified CLI interface with configuration management
5. Create basic orchestration pipeline

### Phase 2: Moderate Autofix & Error Distribution (Hours 9-14)
6. Implement moderate autofix capabilities with re-validation
7. Create error distribution system for even file distribution
8. Add .coding-agent/lint.yml configuration override
9. Build diff review analyzer for change validation
10. Test autofix safety and rollback capabilities

### Phase 3: Agent Integration Foundation (Hours 15-18)
11. Design extensibility hooks for future agent coordination
12. Create workflow instruction for agent-based error fixing
13. Implement foundation for 4-agent parallel processing
14. Add final comprehensive change review system
15. Create integration tests for complete pipeline

## Implementation Plan

### Planning Steps

* [x] Analyze existing linting tools and extract common patterns
  > TEST: Tool Analysis
  > Type: Pre-condition Check
  > Assert: All existing tools analyzed and extraction patterns identified
  > Command: wc -l .ace/tools/bin/lint-security .ace/tools/bin/lint-cassettes .ace/taskflow/.../lint-task-metadata .ace/taskflow/.../lint-md-links.rb
* [x] Design 3-phase pipeline architecture with ATOM hierarchy
  > TEST: Architecture Design
  > Type: Pre-condition Check
  > Assert: Pipeline phases and component responsibilities defined
  > Command: echo "Architecture: Phase 1: Detection → Phase 2: Autofix → Phase 3: Agent Foundation"
* [x] Research kramdown integration for markdown formatting
  > TEST: Kramdown Research
  > Type: Pre-condition Check
  > Assert: Kramdown capabilities and integration approach understood
  > Command: gem list kramdown && ruby -r kramdown -e "puts Kramdown::VERSION"
* [x] Study template embedding requirements from documents-embedding.g.md
  > TEST: Template Embedding Study
  > Type: Pre-condition Check
  > Assert: Template embedding requirements understood and validator designed
  > Command: test -f .ace/handbook/guides/documents-embedding.g.md && wc -l .ace/handbook/guides/documents-embedding.g.md
* [x] Plan moderate autofix safety levels and error distribution strategy
  > TEST: Autofix Planning
  > Type: Pre-condition Check
  > Assert: Autofix safety levels defined and error distribution algorithm planned
  > Command: echo "Autofix: moderate level, even distribution, one issue per file"

### Execution Steps

**Phase 1: Core Linting Infrastructure (Hours 1-8)**

- [x] Create exe/code-lint executable with ExecutableWrapper pattern
  > TEST: Executable Creation
  > Type: File Test
  > Assert: Standalone executable exists and follows ExecutableWrapper pattern
  > Command: test -x exe/code-lint && head -10 exe/code-lint
- [x] Extract SecurityValidator atom from lint-security
  > TEST: Security Validator
  > Type: Unit Test
  > Assert: SecurityValidator maintains original functionality
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/security_validator_spec.rb
- [x] Extract CassettesValidator atom from lint-cassettes
  > TEST: Cassettes Validator
  > Type: Unit Test
  > Assert: CassettesValidator maintains original functionality
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/cassettes_validator_spec.rb
- [x] Extract TaskMetadataValidator atom from lint-task-metadata
  > TEST: Task Metadata Validator
  > Type: Unit Test
  > Assert: TaskMetadataValidator maintains original functionality
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/task_metadata_validator_spec.rb
- [x] Extract MarkdownLinkValidator atom from lint-md-links.rb
  > TEST: Markdown Link Validator
  > Type: Unit Test
  > Assert: MarkdownLinkValidator maintains original functionality
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/markdown_link_validator_spec.rb
- [x] Create StandardRbValidator atom for external StandardRB integration
  > TEST: StandardRB Validator
  > Type: Unit Test
  > Assert: StandardRbValidator integrates correctly with StandardRB
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/standard_rb_validator_spec.rb
- [x] Create TemplateEmbeddingValidator atom based on documents-embedding.g.md
  > TEST: Template Embedding Validator
  > Type: Unit Test
  > Assert: TemplateEmbeddingValidator validates template embedding correctly
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/template_embedding_validator_spec.rb
- [x] Create KramdownFormatter atom to replace Node.js dependency
  > TEST: Kramdown Formatter
  > Type: Unit Test
  > Assert: KramdownFormatter provides markdown formatting functionality
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/kramdown_formatter_spec.rb
- [x] Create ConfigurationLoader atom for .coding-agent/lint.yml handling
  > TEST: Configuration Loader
  > Type: Unit Test
  > Assert: ConfigurationLoader loads and overrides configuration correctly
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/configuration_loader_spec.rb
- [x] Create PathResolver atom for project-aware path handling
  > TEST: Path Resolver
  > Type: Unit Test
  > Assert: PathResolver handles relative/absolute paths correctly from any directory
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/path_resolver_spec.rb
- [x] Build RubyLintingPipeline molecule for Ruby linter coordination
  > TEST: Ruby Linting Pipeline
  > Type: Integration Test
  > Assert: RubyLintingPipeline coordinates all Ruby linters correctly
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/code_quality/ruby_linting_pipeline_spec.rb
- [x] Build MarkdownLintingPipeline molecule for Markdown linter coordination
  > TEST: Markdown Linting Pipeline
  > Type: Integration Test
  > Assert: MarkdownLintingPipeline coordinates all Markdown linters correctly
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/code_quality/markdown_linting_pipeline_spec.rb
- [x] Create MultiPhaseQualityManager organism for pipeline orchestration
  > TEST: Multi-Phase Quality Manager
  > Type: Integration Test
  > Assert: MultiPhaseQualityManager orchestrates all phases correctly
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/code_quality/multi_phase_quality_manager_spec.rb

**Phase 2: Moderate Autofix & Error Distribution (Hours 9-14)**

- [x] Create ErrorDistributor atom for even file distribution
  > TEST: Error Distributor
  > Type: Unit Test
  > Assert: ErrorDistributor distributes errors evenly with one issue per file
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/error_distributor_spec.rb
- [x] Build AutofixOrchestrator molecule for moderate autofix coordination
  > TEST: Autofix Orchestrator
  > Type: Integration Test
  > Assert: AutofixOrchestrator applies moderate fixes safely with re-validation
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/code_quality/autofix_orchestrator_spec.rb
- [x] Create ErrorFileGenerator molecule for .lint-errors-{1-4}.md creation
  > TEST: Error File Generator
  > Type: Unit Test
  > Assert: ErrorFileGenerator creates properly formatted error files
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/code_quality/error_file_generator_spec.rb
- [x] Build DiffReviewAnalyzer molecule for comprehensive change review
  > TEST: Diff Review Analyzer
  > Type: Integration Test
  > Assert: DiffReviewAnalyzer provides comprehensive change analysis
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/code_quality/diff_review_analyzer_spec.rb
- [x] Implement ValidationWorkflowManager organism for Phase 2 coordination
  > TEST: Validation Workflow Manager
  > Type: Integration Test
  > Assert: ValidationWorkflowManager coordinates autofix and error distribution
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/code_quality/validation_workflow_manager_spec.rb
- [x] Add CLI support for --autofix flag with moderate safety level
  > TEST: CLI Autofix Integration
  > Type: CLI Test
  > Assert: CLI autofix commands work with moderate safety level
  > Command: exe/code-lint ruby --autofix --dry-run
- [x] Create default .coding-agent/lint.yml configuration template
  > TEST: Default Configuration
  > Type: File Test
  > Assert: Default configuration is properly structured and overrides work
  > Command: test -f .coding-agent/lint.yml && exe/code-lint --validate-config

**Phase 3: Agent Integration Foundation (Hours 15-18)**

- [x] Design extensibility hooks for future agent coordination
  > TEST: Agent Hooks
  > Type: Architecture Test
  > Assert: Agent integration hooks are properly designed and documented
  > Command: grep -r "agent.*hook\|extensibility" lib/coding_agent_tools/organisms/code_quality/
- [x] Create AgentCoordinationFoundation organism for future agent integration
  > TEST: Agent Coordination Foundation
  > Type: Unit Test
  > Assert: AgentCoordinationFoundation provides proper integration points
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/code_quality/agent_coordination_foundation_spec.rb
- [x] Create fix-linting-issue-from.wf.md workflow instruction
  > TEST: Workflow Instruction
  > Type: File Test
  > Assert: Workflow instruction is properly formatted and actionable
  > Command: test -f .ace/handbook/workflow-instructions/fix-linting-issue-from.wf.md && wc -l .ace/handbook/workflow-instructions/fix-linting-issue-from.wf.md
- [x] Implement foundation for 4-agent parallel processing
  > TEST: Parallel Processing Foundation
  > Type: Integration Test
  > Assert: Foundation supports 4-agent parallel processing preparation
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/code_quality/agent_coordination_foundation_spec.rb -e "parallel"
- [x] Add comprehensive diff review system for final validation
  > TEST: Comprehensive Diff Review
  > Type: Integration Test
  > Assert: Diff review system provides complete change analysis
  > Command: exe/code-lint all --autofix --review-diff
- [x] Register CLI command and ensure integration with existing patterns
  > TEST: CLI Registration
  > Type: Integration Test
  > Assert: Code lint integrates properly with existing CLI framework
  > Command: cd .ace/tools && bundle exec exe/coding_agent_tools code lint --help
- [ ] Create comprehensive end-to-end integration tests
  > TEST: End-to-End Integration
  > Type: Integration Test
  > Assert: Complete 3-phase pipeline works correctly
  > Command: cd .ace/tools && bundle exec rspec spec/integration/multi_phase_quality_pipeline_spec.rb

## Acceptance Criteria

### Phase 1: Core Linting Infrastructure
* [x] **Existing Tool Integration**: All existing linting tools (security, cassettes, task-metadata, md-links) work through ATOM structure
* [x] **New Tool Creation**: StandardRB, Template Embedding, and Kramdown formatters integrated
* [x] **Configuration System**: .coding-agent/lint.yml loads and overrides defaults correctly
* [x] **CLI Interface**: Commands `code-lint ruby`, `code-lint markdown`, `code-lint all` work correctly
* [x] **Node.js Elimination**: Kramdown replaces Node.js markdown formatter dependency

### Phase 2: Moderate Autofix & Error Distribution
* [x] **Moderate Autofix**: Safe formatting and basic refactoring fixes applied correctly
* [x] **Error Distribution**: Errors distributed evenly across .lint-errors-{1-4}.md files
* [x] **One Issue Per File**: Each error file contains issues from single files only
* [x] **Re-validation**: Autofix changes are re-validated for correctness
* [x] **Diff Review**: Comprehensive analysis of all changes made during autofix

### Phase 3: Agent Integration Foundation
* [x] **Extensibility Hooks**: Agent integration points properly designed and documented
* [x] **Workflow Instruction**: fix-linting-issue-from.wf.md provides clear agent guidance
* [x] **Parallel Foundation**: Infrastructure supports 4-agent parallel processing
* [x] **Final Review**: Complete change review system validates all modifications
* [x] **Future Ready**: Foundation enables seamless agent coordination implementation

### Technical Requirements
* [x] **ATOM Architecture**: Clean separation of atoms, molecules, and organisms
* [x] **Error Handling**: Robust error handling throughout all phases
* [x] **Performance**: Acceptable performance for all linting and autofix operations
* [x] **Security**: Safe external tool execution with proper validation
* [ ] **Test Coverage**: Comprehensive unit, integration, and CLI test coverage
* [x] **Path Handling**: Commands work consistently from any directory level within the project

### User Experience
* [ ] **Intuitive CLI**: Clear command structure and helpful error messages
* [ ] **Configuration**: Simple .coding-agent/lint.yml configuration management
* [ ] **Feedback**: Clear progress indicators and actionable output
* [ ] **Reliability**: Consistent behavior across all supported file types

## Out of Scope

### Current Implementation Boundaries
* ❌ **Advanced Agent Implementation**: Full agent orchestration (foundation only)
* ❌ **Custom Validation Rules**: New validation rules beyond existing tools
* ❌ **Complex AI Integration**: LLM-based analysis (future enhancement)
* ❌ **Real-time Monitoring**: File watching and continuous validation

### Phase 3 Clarifications
* ✅ **Agent Foundation**: Design hooks and interfaces for future agent integration
* ✅ **Moderate Autofix**: Safe automated fixes with re-validation
* ✅ **Error Distribution**: Even distribution for parallel agent processing
* ✅ **Change Review**: Comprehensive diff analysis and validation

## References

### Dependencies
* **v.0.3.0+task.06**: ✅ Shell command execution and path handling molecules
* **v.0.3.0+task.34**: ✅ Code review module patterns and ATOM architecture

### Existing Tool Sources
* **lint-security**: .ace/tools/bin/lint-security → SecurityValidator atom
* **lint-cassettes**: .ace/tools/bin/lint-cassettes → CassettesValidator atom
* **lint-task-metadata**: .ace/taskflow/.../lint-task-metadata → TaskMetadataValidator atom
* **lint-md-links.rb**: .ace/taskflow/.../lint-md-links.rb → MarkdownLinkValidator atom

### Technical References
* **Template Embedding**: .ace/handbook/guides/documents-embedding.g.md
* **Kramdown Documentation**: For markdown formatting capabilities
* **ExecutableWrapper Pattern**: From existing code-review implementation
* **ATOM Architecture**: Established patterns from taskflow_management
* **ProjectRootDetector**: .ace/tools/lib/coding_agent_tools/atoms/project_root_detector.rb

### Configuration & Workflow
* **Configuration Override**: .coding-agent/lint.yml in project root
* **Error Distribution**: Even distribution across 4 files, one issue per file
* **Autofix Safety**: Moderate level (safe formatting, basic refactoring)
* **Agent Preparation**: Foundation for 4-agent parallel processing