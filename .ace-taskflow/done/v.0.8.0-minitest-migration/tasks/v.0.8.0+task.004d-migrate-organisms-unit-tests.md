---
id: v.0.8.0+task.004d
status: pending
priority: medium
estimate: 4h
dependencies: [v.0.8.0+task.004a, v.0.8.0+task.004b, v.0.8.0+task.004c]
parent_task: v.0.8.0+task.004
---

# Migrate Organisms Unit Tests

## Objective

Migrate all unit tests for Organism components to Minitest. Organisms orchestrate molecules to implement business logic, requiring complex mocking and state management in tests.

## Scope of Work

- Write comprehensive unit tests for 54 Organism components
- Test business logic orchestration with complex mocking
- Verify workflow coordination and error handling
- Follow Minitest patterns established in test_helper.rb

## Component Checklist (54 total)

### Claude Integration Organisms (8 components)
- [ ] `claude_integration/agent_installer.rb` - Installs Claude agents
- [ ] `claude_integration/claude_command_generator.rb` - Generates Claude commands
- [ ] `claude_integration/claude_command_lister.rb` - Lists Claude commands
- [ ] `claude_integration/claude_commands_orchestrator.rb` - Orchestrates commands
- [ ] `claude_integration/claude_validator.rb` - Validates Claude setup
- [ ] `claude_integration/command_discoverer.rb` - Discovers available commands
- [ ] `claude_integration/command_installer.rb` - Installs commands
- [ ] `claude_integration/workflow_command_generator.rb` - Generates workflow commands

### Code Quality Organisms (7 components)
- [ ] `code_quality/agent_coordination_foundation.rb` - Agent coordination base
- [ ] `code_quality/language_runner_factory.rb` - Creates language runners
- [ ] `code_quality/language_runner.rb` - Base language runner
- [ ] `code_quality/markdown_runner.rb` - Markdown linting runner
- [ ] `code_quality/multi_phase_quality_manager.rb` - Multi-phase quality checks
- [ ] `code_quality/ruby_runner.rb` - Ruby linting runner
- [ ] `code_quality/validation_workflow_manager.rb` - Validation workflow management

### Code Review Organisms (5 components)
- [ ] `code/content_extractor.rb` - Extracts code content
- [ ] `code/context_loader.rb` - Loads review context
- [ ] `code/prompt_builder.rb` - Builds review prompts
- [ ] `code/review_manager.rb` - Manages review workflow
- [ ] `code/session_manager.rb` - Manages review sessions

### Context Organisms (1 component)
- [ ] `context_loader.rb` - Main context loading orchestrator

### Cost Tracking Organisms (1 component)
- [ ] `cost_tracker.rb` - Tracks LLM usage costs

### Coverage Organisms (2 components)
- [ ] `coverage_analyzer.rb` - Analyzes test coverage
- [ ] `coverage_report_generator.rb` - Generates coverage reports

### Documentation Organisms (1 component)
- [ ] `doc_dependency_analyzer.rb` - Analyzes documentation dependencies

### Editor Integration Organisms (1 component)
- [ ] `editor/editor_integration.rb` - Integrates with editors

### Git Organisms (1 component)
- [ ] `git/git_orchestrator.rb` - Orchestrates git operations

### Idea Management Organisms (1 component)
- [ ] `idea_capture.rb` - Captures and processes ideas

### LLM API Client Organisms (6 components)
- [ ] `llm/api/anthropic_client.rb` - Anthropic API client
- [ ] `llm/api/google_client.rb` - Google API client
- [ ] `llm/api/lmstudio_client.rb` - LM Studio API client
- [ ] `llm/api/mistral_client.rb` - Mistral API client
- [ ] `llm/api/openai_client.rb` - OpenAI API client
- [ ] `llm/api/togetherai_client.rb` - TogetherAI API client

### LLM Base Organisms (2 components)
- [ ] `llm/base/base_chat_completion_client.rb` - Base chat completion
- [ ] `llm/base/base_client.rb` - Base LLM client

### LLM CLI Client Organisms (4 components)
- [ ] `llm/cli/claude_code_client.rb` - Claude Code CLI client
- [ ] `llm/cli/codex_client.rb` - Codex CLI client
- [ ] `llm/cli/codex_oss_client.rb` - Codex OSS CLI client
- [ ] `llm/cli/open_code_client.rb` - OpenCode CLI client

### LLM Support Organisms (1 component)
- [ ] `llm/support/prompt_processor.rb` - Processes prompts

### MCP Integration Organisms (3 components)
- [ ] `mcp/http_transport.rb` - MCP HTTP transport
- [ ] `mcp/proxy_server.rb` - MCP proxy server
- [ ] `mcp/stdio_transport.rb` - MCP stdio transport

### Notification Organisms (1 component)
- [ ] `notifications.rb` - Central notification system

### Pricing Organisms (1 component)
- [ ] `pricing_fetcher.rb` - Fetches LLM pricing data

### Search Organisms (2 components)
- [ ] `search/result_aggregator.rb` - Aggregates search results
- [ ] `search/unified_searcher.rb` - Unified search interface

### System Organisms (1 component)
- [ ] `system/command_executor.rb` - Executes system commands

### Taskflow Management Organisms (3 components)
- [ ] `taskflow_management/release_manager.rb` - Manages releases
- [ ] `taskflow_management/task_manager.rb` - Manages tasks
- [ ] `taskflow_management/template_synchronizer.rb` - Synchronizes templates

### Tool Management Organisms (1 component)
- [ ] `tool_lister.rb` - Lists available tools

### Coverage Analysis Organisms (1 component)
- [ ] `undercovered_items_extractor.rb` - Extracts under-covered items

## Progress Tracking

- **Components completed:** 0/54
- **Estimated time per component:** ~4-5 minutes
- **Current focus:** [Not started]

## Implementation Plan

### Execution Steps

1. **Setup Test Infrastructure**
   - [ ] Create test/unit/organisms/ directory structure
   - [ ] Set up complex mocking helpers for organisms
   - [ ] Configure test fixtures for stateful operations

2. **Test Simple Orchestrators First** (Priority: High)
   - [ ] Test notification and cost tracking (minimal state)
   - [ ] Test tool lister and command discoverer
   - [ ] Test simple workflow managers

3. **Test Client Organisms** (Priority: Medium)
   - [ ] Test LLM clients with mocked HTTP/CLI
   - [ ] Test base client abstractions
   - [ ] Test error handling and retries

4. **Test Complex Workflows** (Priority: Low)
   - [ ] Test multi-phase quality managers
   - [ ] Test review session management
   - [ ] Test release and task management

## Acceptance Criteria

- [ ] All 54 organism components have corresponding test files
- [ ] Each test covers:
  - Complete workflow orchestration
  - State management and transitions
  - Error handling and recovery
  - Proper delegation to molecules
  - Business logic validation
- [ ] Tests pass with `ace-test organisms`
- [ ] Tests run serially (no parallelize_me!)
- [ ] Complex mocking for external services
- [ ] Clear separation of concerns in tests

## Testing Guidelines

### Organism Test Principles
- Business logic: test complete workflows
- State management: verify state transitions
- Error recovery: test failure handling
- Orchestration: verify proper coordination
- Serial execution: avoid parallel test conflicts

### Example Test Structure
```ruby
class SomeOrganismTest < OrganismTest
  def setup
    @mock_molecule1 = Minitest::Mock.new
    @mock_molecule2 = Minitest::Mock.new
    @organism = SomeOrganism.new(
      molecule1: @mock_molecule1,
      molecule2: @mock_molecule2
    )
  end

  def test_orchestrates_complete_workflow
    # Setup expectations
    @mock_molecule1.expect(:process, "step1_result", ["input"])
    @mock_molecule2.expect(:transform, "final", ["step1_result"])

    # Execute workflow
    result = @organism.execute_workflow("input")

    # Verify orchestration
    assert_equal "final", result
    @mock_molecule1.verify
    @mock_molecule2.verify
  end

  def test_handles_partial_failure
    @mock_molecule1.expect(:process, -> { raise ProcessError })

    # Should gracefully handle and potentially retry
    result = @organism.execute_workflow("input")
    assert_equal "fallback_result", result
  end

  def test_manages_state_correctly
    @organism.start_session
    assert_equal :active, @organism.state

    @organism.complete_session
    assert_equal :completed, @organism.state
  end
end
```

## Out of Scope

- Integration with real external services
- Performance benchmarking
- Concurrent execution testing
- UI/CLI output testing (covered in E2E)

## References

- **Testing Guide**: `docs/development/testing.g.md` - Essential testing patterns and setup
- Test helper: `test/test_helper.rb`
- Organism base class: `OrganismTest`
- Example organism test: `test/unit/organisms/example_organism_test.rb`
- Note: Organisms run serially, not in parallel