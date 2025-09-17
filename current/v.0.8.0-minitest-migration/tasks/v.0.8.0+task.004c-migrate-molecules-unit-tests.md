---
id: v.0.8.0+task.004c
status: pending
priority: medium
estimate: 6h
dependencies: [v.0.8.0+task.004a, v.0.8.0+task.004b]
parent_task: v.0.8.0+task.004
---

# Migrate Molecules Unit Tests

## Objective

Migrate all unit tests for Molecule components to Minitest. Molecules are focused operations that compose Atoms, requiring selective mocking for external dependencies.

## Scope of Work

- Write comprehensive unit tests for 114 Molecule components
- Test composed operations with appropriate mocking
- Verify error handling and edge cases
- Follow Minitest patterns established in test_helper.rb

## Component Checklist (114 total)

### Agents Molecules (3 components)
- [ ] `agents/agent_parser.rb` - Parses agent definitions
- [ ] `agents/context_definition_parser.rb` - Parses context definitions
- [ ] `agents/metadata_extractor.rb` - Extracts agent metadata

### API Molecules (2 components)
- [ ] `api_credentials.rb` - Manages API credentials
- [ ] `api_response_parser.rb` - Parses API responses

### Backup Molecules (1 component)
- [ ] `backup_creator.rb` - Creates backup files

### Claude Molecules (3 components)
- [ ] `claude/command_inventory_builder.rb` - Builds command inventory
- [ ] `claude/command_metadata_inferrer.rb` - Infers command metadata
- [ ] `claude/command_validator.rb` - Validates Claude commands

### Client Factory (1 component)
- [ ] `client_factory.rb` - Creates client instances

### Code Quality Molecules (5 components)
- [ ] `code_quality/autofix_orchestrator.rb` - Orchestrates autofixes
- [ ] `code_quality/diff_review_analyzer.rb` - Analyzes diffs for review
- [ ] `code_quality/error_file_generator.rb` - Generates error files
- [ ] `code_quality/markdown_linting_pipeline.rb` - Markdown linting pipeline
- [ ] `code_quality/ruby_linting_pipeline.rb` - Ruby linting pipeline

### Code Molecules (15 components)
- [ ] `code/config_extractor.rb` - Extracts configuration
- [ ] `code/context_integrator.rb` - Integrates context
- [ ] `code/file_pattern_extractor.rb` - Extracts file patterns
- [ ] `code/git_diff_extractor.rb` - Extracts git diffs
- [ ] `code/llm_executor.rb` - Executes LLM queries
- [ ] `code/project_context_loader.rb` - Loads project context
- [ ] `code/prompt_combiner.rb` - Combines prompts
- [ ] `code/prompt_enhancer.rb` - Enhances prompts
- [ ] `code/report_collector.rb` - Collects reports
- [ ] `code/review_assembler.rb` - Assembles reviews
- [ ] `code/review_preset_manager.rb` - Manages review presets
- [ ] `code/session_directory_builder.rb` - Builds session directories
- [ ] `code/session_path_inferrer.rb` - Infers session paths
- [ ] `code/synthesis_orchestrator.rb` - Orchestrates synthesis

### Command Molecules (1 component)
- [ ] `command_template_renderer.rb` - Renders command templates

### Context Molecules (10 components)
- [ ] `context_loader.rb` - Loads context files
- [ ] `context/agent_context_extractor.rb` - Extracts agent context
- [ ] `context/context_aggregator.rb` - Aggregates context
- [ ] `context/context_chunker.rb` - Chunks large context
- [ ] `context/context_file_writer.rb` - Writes context files
- [ ] `context/context_preset_manager.rb` - Manages context presets
- [ ] `context/document_embedder.rb` - Embeds documents
- [ ] `context/input_format_detector.rb` - Detects input formats
- [ ] `context/markdown_yaml_extractor.rb` - Extracts YAML from markdown
- [ ] `context/merger.rb` - Merges context data
- [ ] `context/output_formatter.rb` - Formats context output

### Coverage Molecules (1 component)
- [ ] `coverage_data_processor.rb` - Processes coverage data

### Dependency Molecules (1 component)
- [ ] `circular_dependency_detector.rb` - Detects circular dependencies

### Documentation Molecules (2 components)
- [ ] `doc_link_parser.rb` - Parses documentation links
- [ ] `document_link_resolver.rb` - Resolves document links

### Editor Molecules (1 component)
- [ ] `editor/editor_config_manager.rb` - Manages editor config

### Error Handling (1 component)
- [ ] `error_reporter.rb` - Reports errors consistently

### Executable Molecules (1 component)
- [ ] `executable_wrapper.rb` - Wraps executable calls

### File Operation Molecules (5 components)
- [ ] `file_analyzer.rb` - Analyzes file contents
- [ ] `file_io_handler.rb` - Handles file I/O operations
- [ ] `file_operation_confirmer.rb` - Confirms file operations
- [ ] `file_operation_executor.rb` - Executes file operations
- [ ] `format_handlers.rb` - Handles various formats

### Git Molecules (5 components)
- [ ] `git_path_resolver.rb` - Resolves git paths
- [ ] `git/commit_message_generator.rb` - Generates commit messages
- [ ] `git/concurrent_executor.rb` - Executes git commands concurrently
- [ ] `git/multi_repo_coordinator.rb` - Coordinates multi-repo operations
- [ ] `git/path_dispatcher.rb` - Dispatches git path operations

### HTTP Molecules (3 components)
- [ ] `faraday_dry_monitor_logger.rb` - Logs HTTP with dry-monitor
- [ ] `http_request_builder.rb` - Builds HTTP requests
- [ ] `http/http_client.rb` - HTTP client wrapper
- [ ] `retry_middleware.rb` - HTTP retry middleware

### Idea Molecules (1 component)
- [ ] `idea_enhancer.rb` - Enhances idea descriptions

### LLM Molecules (2 components)
- [ ] `llm_alias_resolver.rb` - Resolves LLM aliases
- [ ] `llm_client.rb` - LLM client wrapper

### MCP Molecules (3 components)
- [ ] `mcp/message_handler.rb` - Handles MCP messages
- [ ] `mcp/security_validator.rb` - Validates MCP security
- [ ] `mcp/tool_wrapper.rb` - Wraps MCP tools

### Metadata Molecules (2 components)
- [ ] `metadata_injector.rb` - Injects metadata
- [ ] `metadata_normalizer.rb` - Normalizes metadata

### Method Coverage (1 component)
- [ ] `method_coverage_mapper.rb` - Maps method coverage

### Path Molecules (3 components)
- [ ] `path_autocorrector.rb` - Auto-corrects paths
- [ ] `path_config_loader.rb` - Loads path configuration
- [ ] `path_resolver.rb` - Resolves complex paths

### Project Molecules (2 components)
- [ ] `project_root_finder.rb` - Finds project root
- [ ] `project_sandbox.rb` - Creates project sandbox

### Provider Molecules (1 component)
- [ ] `provider_model_parser.rb` - Parses provider models

### Provider Usage Parsers (6 components)
- [ ] `provider_usage_parsers/anthropic_usage_parser.rb` - Parses Anthropic usage
- [ ] `provider_usage_parsers/google_usage_parser.rb` - Parses Google usage
- [ ] `provider_usage_parsers/lmstudio_usage_parser.rb` - Parses LM Studio usage
- [ ] `provider_usage_parsers/mistral_usage_parser.rb` - Parses Mistral usage
- [ ] `provider_usage_parsers/openai_usage_parser.rb` - Parses OpenAI usage
- [ ] `provider_usage_parsers/togetherai_usage_parser.rb` - Parses TogetherAI usage

### Reflection Molecules (3 components)
- [ ] `reflection/report_collector.rb` - Collects reflection reports
- [ ] `reflection/synthesis_orchestrator.rb` - Orchestrates synthesis
- [ ] `reflection/timestamp_inferrer.rb` - Infers timestamps

### Report Molecules (1 component)
- [ ] `report_formatter.rb` - Formats reports

### Search Molecules (5 components)
- [ ] `search/dwim_heuristics_engine.rb` - DWIM search heuristics
- [ ] `search/fzf_integrator.rb` - Integrates with fzf
- [ ] `search/git_scope_enumerator.rb` - Enumerates git scope
- [ ] `search/preset_manager.rb` - Manages search presets
- [ ] `search/time_filter.rb` - Filters by time

### Security Molecules (2 components)
- [ ] `secure_path_validator.rb` - Validates secure paths
- [ ] `source_directory_validator.rb` - Validates source directories

### Statistics Molecules (3 components)
- [ ] `statistics_calculator.rb` - Calculates statistics
- [ ] `statistics_collector.rb` - Collects statistics
- [ ] `statistics/adaptive_threshold_calculator.rb` - Calculates adaptive thresholds

### Taskflow Management Molecules (15 components)
- [ ] `taskflow_management/file_synchronizer.rb` - Synchronizes task files
- [ ] `taskflow_management/git_log_formatter.rb` - Formats git logs
- [ ] `taskflow_management/release_path_resolver.rb` - Resolves release paths
- [ ] `taskflow_management/release_resolver.rb` - Resolves releases
- [ ] `taskflow_management/task_dependency_checker.rb` - Checks task dependencies
- [ ] `taskflow_management/task_file_loader.rb` - Loads task files
- [ ] `taskflow_management/task_filter_engine.rb` - Filters tasks
- [ ] `taskflow_management/task_filter_parser.rb` - Parses task filters
- [ ] `taskflow_management/task_id_generator.rb` - Generates task IDs
- [ ] `taskflow_management/task_sort_engine.rb` - Sorts tasks
- [ ] `taskflow_management/task_sort_parser.rb` - Parses sort criteria
- [ ] `taskflow_management/task_status_summary.rb` - Summarizes task status
- [ ] `taskflow_management/unified_task_formatter.rb` - Formats tasks uniformly
- [ ] `taskflow_management/xml_template_parser.rb` - Parses XML templates

### Tool Molecules (2 components)
- [ ] `tool_categorizer.rb` - Categorizes tools
- [ ] `tool_metadata_extractor.rb` - Extracts tool metadata

### Tree Molecules (1 component)
- [ ] `tree_config_loader.rb` - Loads tree configuration

## Progress Tracking

- **Components completed:** 0/114
- **Estimated time per component:** ~3 minutes
- **Current focus:** [Not started]

## Implementation Plan

### Execution Steps

1. **Setup Test Infrastructure**
   - [ ] Create test/unit/molecules/ directory structure
   - [ ] Set up mocking helpers for molecules

2. **Test Simple Molecules First** (Priority: High)
   - [ ] Test parsers and extractors (clear input/output)
   - [ ] Test formatters and renderers
   - [ ] Test validators and checkers

3. **Test Integration Molecules** (Priority: Medium)
   - [ ] Test client wrappers with mocked clients
   - [ ] Test orchestrators with mocked dependencies
   - [ ] Test pipelines with fixture data

4. **Test Complex Molecules** (Priority: Low)
   - [ ] Test multi-step workflows
   - [ ] Test concurrent operations
   - [ ] Test error recovery mechanisms

## Acceptance Criteria

- [ ] All 114 molecule components have corresponding test files
- [ ] Each test covers:
  - Normal operation flow
  - Error conditions and recovery
  - Edge cases and boundaries
  - Proper delegation to atoms
- [ ] Tests pass with `ace-test molecules`
- [ ] Appropriate use of mocks for external dependencies
- [ ] Tests run in parallel where safe

## Testing Guidelines

### Molecule Test Principles
- Focused operations: test one responsibility
- Composition: verify proper delegation to atoms
- Error handling: test failure scenarios
- Mocking: mock external dependencies, not atoms
- Integration: test interaction between atoms

### Example Test Structure
```ruby
class SomeMoleculeTest < MoleculeTest
  def setup
    @mock_client = Minitest::Mock.new
    @molecule = SomeMolecule.new(client: @mock_client)
  end

  def test_successful_operation
    @mock_client.expect(:call, "result", ["input"])
    result = @molecule.process("input")
    assert_equal "processed result", result
    @mock_client.verify
  end

  def test_handles_client_errors
    @mock_client.expect(:call, -> { raise ClientError })
    assert_raises(ProcessingError) do
      @molecule.process("input")
    end
  end
end
```

## Out of Scope

- End-to-end workflow testing (covered in organisms/ecosystems)
- External service integration tests
- Performance testing
- Concurrent execution testing

## References

- Test helper: `test/test_helper.rb`
- Molecule base class: `MoleculeTest`
- Example molecule test: `test/unit/molecules/example_molecule_test.rb`