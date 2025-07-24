---
id: v.0.3.0+task.102
status: pending
priority: medium
estimate: 15h
dependencies: []
---

# Create Unit Tests for Molecule Classes

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/molecules | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/molecules
    ├── code/
    │   ├── file_pattern_extractor.rb
    │   ├── git_diff_extractor.rb
    │   ├── project_context_loader.rb
    │   ├── prompt_combiner.rb
    │   ├── report_collector.rb
    │   ├── session_directory_builder.rb
    │   ├── session_path_inferrer.rb
    │   └── synthesis_orchestrator.rb
    ├── code_quality/
    │   ├── autofix_orchestrator.rb
    │   ├── diff_review_analyzer.rb
    │   ├── error_file_generator.rb
    │   ├── markdown_linting_pipeline.rb
    │   └── ruby_linting_pipeline.rb
    └── taskflow_management/
        └── task_id_generator.rb
```

## Objective

Create comprehensive unit tests for all 13+ Molecule classes to validate data processing workflows, integration between atoms, error propagation, and complex orchestration logic across code processing, quality assurance, and task management domains.

## Scope of Work

- Create unit tests for Code molecules: file_pattern_extractor, git_diff_extractor, project_context_loader, prompt_combiner, report_collector, session_directory_builder, session_path_inferrer, synthesis_orchestrator
- Create unit tests for CodeQuality molecules: autofix_orchestrator, diff_review_analyzer, error_file_generator, markdown_linting_pipeline, ruby_linting_pipeline  
- Create unit tests for TaskflowManagement molecules: task_id_generator
- Test workflow coordination, atom integration, error handling, and data transformation logic
- Mock dependencies and validate integration points between atoms and molecules

### Deliverables

#### Create

- dev-tools/spec/coding_agent_tools/molecules/code/file_pattern_extractor_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code/git_diff_extractor_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code/project_context_loader_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code/prompt_combiner_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code/report_collector_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code/session_directory_builder_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code/session_path_inferrer_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code/synthesis_orchestrator_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code_quality/autofix_orchestrator_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code_quality/diff_review_analyzer_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code_quality/error_file_generator_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code_quality/markdown_linting_pipeline_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/code_quality/ruby_linting_pipeline_spec.rb
- dev-tools/spec/coding_agent_tools/molecules/taskflow_management/task_id_generator_spec.rb

#### Modify

- None

#### Delete

- None

## Phases

1. Analyze molecule class dependencies and atom integration patterns
2. Create test infrastructure for molecule-level testing with atom mocking
3. Implement tests for code processing molecules
4. Implement tests for code quality molecules
5. Implement tests for task management molecules
6. Validate error propagation and workflow orchestration

## Implementation Plan

### Planning Steps

- [ ] Analyze molecule classes to understand atom dependencies and workflow patterns
  > TEST: Molecule Dependency Analysis
  > Type: Pre-condition Check
  > Assert: All molecule classes and their atom dependencies are identified
  > Command: cd dev-tools && find lib/coding_agent_tools/molecules -name "*.rb" -exec grep -l "Atoms::" {} \; | wc -l
- [ ] Research mocking strategies for atom dependencies in molecule tests
- [ ] Plan test scenarios for workflow coordination and error propagation

### Execution Steps

- [ ] Create test infrastructure for molecule testing with atom mocking
- [ ] Implement FilePatternExtractor tests with file system pattern matching
  > TEST: File Pattern Extraction
  > Type: Pattern Matching Validation
  > Assert: File pattern extraction works correctly with various patterns
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/code/file_pattern_extractor_spec.rb
- [ ] Implement GitDiffExtractor tests with git operation mocking
- [ ] Implement ProjectContextLoader tests with context aggregation validation
- [ ] Implement PromptCombiner tests with template and data combination logic
  > TEST: Code Processing Workflows
  > Type: Workflow Integration Test
  > Assert: Code processing molecules coordinate atoms correctly
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/code/ --tag workflow
- [ ] Implement ReportCollector tests with data aggregation and formatting
- [ ] Implement SessionDirectoryBuilder tests with directory structure creation
- [ ] Implement SessionPathInferrer tests with path resolution logic
- [ ] Implement SynthesisOrchestrator tests with complex workflow coordination
  > TEST: Complex Orchestration
  > Type: Multi-Step Workflow Test
  > Assert: Complex orchestration workflows handle multiple steps correctly
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/code/synthesis_orchestrator_spec.rb
- [ ] Implement AutofixOrchestrator tests with fix workflow coordination
- [ ] Implement DiffReviewAnalyzer tests with code analysis and review logic
- [ ] Implement ErrorFileGenerator tests with error reporting and file generation
- [ ] Implement MarkdownLintingPipeline tests with markdown processing workflow
- [ ] Implement RubyLintingPipeline tests with Ruby code quality workflow
  > TEST: Quality Assurance Workflows
  > Type: Quality Pipeline Validation
  > Assert: Code quality molecules execute linting workflows correctly
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/code_quality/
- [ ] Implement TaskIdGenerator tests with ID generation logic and validation
- [ ] Test error propagation across molecule workflows
  > TEST: Error Propagation
  > Type: Error Handling Validation
  > Assert: Errors propagate correctly through molecule workflows
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/ --tag error_handling
- [ ] Run complete molecule test suite
  > TEST: Full Molecule Test Suite
  > Type: Complete Integration Test
  > Assert: All molecule classes are thoroughly tested
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/

## Acceptance Criteria

- [ ] All molecule classes have comprehensive test coverage
- [ ] Atom dependencies are properly mocked to ensure test isolation
- [ ] Workflow coordination and orchestration logic are thoroughly tested
- [ ] Error propagation and handling are validated across all workflows
- [ ] Integration between atoms and molecules is properly tested
- [ ] Complex orchestration scenarios are covered with realistic test data
- [ ] Tests follow ATOM architecture principles for molecule-level testing

## Out of Scope

- ❌ Testing actual external system integrations (use mocks for git, file system, etc.)
- ❌ End-to-end workflow testing (organism-level testing)
- ❌ Performance testing of workflow execution
- ❌ Testing organism-level orchestration logic

## References

- dev-tools/lib/coding_agent_tools/molecules/**/*.rb
- dev-tools/lib/coding_agent_tools/atoms/**/*.rb (for dependency understanding)
- dev-tools/spec/support/mock_helpers.rb
- docs/architecture-tools.md (ATOM architecture principles)
- dev-handbook/guides/testing/ruby-rspec.md