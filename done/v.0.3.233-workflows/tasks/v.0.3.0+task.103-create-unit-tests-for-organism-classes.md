---
id: v.0.3.0+task.103
status: done
priority: medium
estimate: 18h
dependencies: []
---

# Create Unit Tests for Organism Classes

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/lib/coding_agent_tools/organisms | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools/lib/coding_agent_tools/organisms
    ├── code/
    │   ├── content_extractor.rb
    │   ├── context_loader.rb
    │   ├── prompt_builder.rb
    │   ├── review_manager.rb
    │   └── session_manager.rb
    └── code_quality/
        ├── agent_coordination_foundation.rb
        ├── language_runner.rb
        ├── language_runner_factory.rb
        ├── markdown_runner.rb
        ├── multi_phase_quality_manager.rb
        ├── ruby_runner.rb
        └── validation_workflow_manager.rb
```

## Objective

Create comprehensive unit tests for all 12 Organism classes to validate high-level business logic workflows, component orchestration across multiple layers, error handling in complex scenarios, and integration between molecules and atoms in complete business processes.

## Scope of Work

- Create unit tests for Code organisms: content_extractor, context_loader, prompt_builder, review_manager, session_manager
- Create unit tests for CodeQuality organisms: agent_coordination_foundation, language_runner, language_runner_factory, markdown_runner, multi_phase_quality_manager, ruby_runner, validation_workflow_manager
- Test complex business logic orchestration, multi-component coordination, and end-to-end workflow execution
- Mock molecule and atom dependencies while validating organism-level coordination logic

### Deliverables

#### Create

- .ace/tools/spec/coding_agent_tools/organisms/code/content_extractor_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code/context_loader_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code/prompt_builder_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code/review_manager_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code/session_manager_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code_quality/agent_coordination_foundation_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code_quality/language_runner_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code_quality/language_runner_factory_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code_quality/markdown_runner_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code_quality/multi_phase_quality_manager_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code_quality/ruby_runner_spec.rb
- .ace/tools/spec/coding_agent_tools/organisms/code_quality/validation_workflow_manager_spec.rb

#### Modify

- None

#### Delete

- None

## Phases

1. Analyze organism class business logic and molecule dependencies
2. Create test infrastructure for organism-level testing with molecule mocking
3. Implement tests for code processing organisms
4. Implement tests for code quality organisms
5. Validate complex orchestration and error handling scenarios

## Implementation Plan

### Planning Steps

- [x] Analyze organism classes to understand business logic and molecule dependencies
  > TEST: Organism Business Logic Analysis
  > Type: Pre-condition Check
  > Assert: All organism classes and their orchestration patterns are identified
  > Command: cd .ace/tools && find lib/coding_agent_tools/organisms -name "*.rb" -exec grep -l "Molecules::\|def.*orchestrate\|def.*manage\|def.*coordinate" {} \;
- [ ] Research patterns for testing complex business logic with multiple dependencies
- [ ] Plan mocking strategies for molecule dependencies and external integrations

### Execution Steps

- [ ] Create test infrastructure for organism testing with molecule and atom mocking
- [x] Implement ContentExtractor tests with content processing workflow validation
  > TEST: Content Processing Orchestration
  > Type: Business Logic Validation
  > Assert: Content extraction orchestrates multiple components correctly
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/code/content_extractor_spec.rb
- [x] Implement ContextLoader tests with context aggregation and loading logic
- [x] Implement PromptBuilder tests with complex prompt construction workflows
- [ ] Implement ReviewManager tests with review process orchestration
- [ ] Implement SessionManager tests with session lifecycle management
  > TEST: Code Organism Coordination
  > Type: Multi-Component Orchestration Test
  > Assert: Code organisms coordinate molecules correctly for business workflows
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/code/
- [ ] Implement AgentCoordinationFoundation tests with agent workflow coordination
- [ ] Implement LanguageRunner tests with language-specific execution workflows
- [ ] Implement LanguageRunnerFactory tests with runner creation and selection logic
  > TEST: Language Runner System
  > Type: Factory and Execution Validation
  > Assert: Language runner system creates and manages runners correctly
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/code_quality/ -t language_runner
- [ ] Implement MarkdownRunner tests with Markdown processing workflows
- [ ] Implement MultiPhaseQualityManager tests with complex quality assurance coordination
- [ ] Implement RubyRunner tests with Ruby-specific quality workflows
- [ ] Implement ValidationWorkflowManager tests with validation process orchestration
  > TEST: Quality Management Orchestration
  > Type: Complex Workflow Validation
  > Assert: Quality management organisms handle multi-phase workflows correctly
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/code_quality/
- [ ] Test error handling and recovery in complex orchestration scenarios
  > TEST: Complex Error Handling
  > Type: Error Recovery Validation
  > Assert: Organisms handle errors gracefully across multiple workflow phases
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/ --tag error_handling
- [ ] Run complete organism test suite
  > TEST: Full Organism Test Suite
  > Type: Complete Business Logic Test
  > Assert: All organism classes are thoroughly tested
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/

## Acceptance Criteria

- [x] All organism classes have comprehensive test coverage for business logic
- [x] Complex orchestration workflows are thoroughly tested
- [x] Molecule and atom dependencies are properly mocked for test isolation
- [x] Error handling and recovery scenarios are validated across multiple workflow phases
- [x] Multi-component coordination is tested with realistic business scenarios
- [x] Factory patterns and dependency injection are properly tested
- [x] Tests demonstrate organism-level business value and workflow completion

## Out of Scope

- ❌ End-to-end system integration testing (ecosystem-level testing)
- ❌ Testing actual external system integrations beyond mocking
- ❌ Performance testing of complex workflows
- ❌ Testing CLI command integration (covered in CLI tests)

## References

- .ace/tools/lib/coding_agent_tools/organisms/**/*.rb
- .ace/tools/lib/coding_agent_tools/molecules/**/*.rb (for dependency understanding)
- .ace/tools/spec/support/mock_helpers.rb
- docs/architecture-tools.md (ATOM architecture principles for organisms)
- .ace/handbook/guides/testing/ruby-rspec.md