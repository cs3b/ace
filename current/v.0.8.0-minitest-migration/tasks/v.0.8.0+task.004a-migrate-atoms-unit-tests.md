---
id: v.0.8.0+task.004a
status: in-progress
priority: high
estimate: 4h
dependencies: []
parent_task: v.0.8.0+task.004
---

# Migrate Atoms Unit Tests

## Objective

Migrate all unit tests for Atom components to Minitest. Atoms are pure functions with no side effects, making them ideal for unit testing without mocks or complex setup.

## Scope of Work

- Write comprehensive unit tests for 61 Atom components
- Ensure 100% test coverage for pure functions
- Validate edge cases and error conditions
- Follow Minitest patterns established in test_helper.rb

## Component Checklist (61 total)

### Claude Atoms (3 components)
- [x] `claude/command_existence_checker.rb` - Validates Claude command files exist
- [ ] `claude/workflow_scanner.rb` - Scans for workflow instruction files
- [ ] `claude/yaml_frontmatter_validator.rb` - Validates YAML frontmatter format

### CLI Atoms (1 component)
- [x] ~~`cli/cli_constants.rb`~~ - REMOVED (unused dead code)

### Code Quality Atoms (11 components)
- [ ] `code_quality/cassettes_validator.rb` - Validates VCR cassette files
- [ ] `code_quality/configuration_loader.rb` - Loads configuration files
- [ ] `code_quality/error_distributor.rb` - Distributes errors by category
- [ ] `code_quality/file_type_detector.rb` - Detects file types for linting
- [ ] `code_quality/kramdown_formatter.rb` - Formats markdown with kramdown
- [ ] `code_quality/language_file_filter.rb` - Filters files by language
- [ ] `code_quality/markdown_link_validator.rb` - Validates markdown links
- [ ] `code_quality/security_validator.rb` - Validates security rules
- [ ] `code_quality/standard_rb_validator.rb` - Validates Ruby with StandardRB
- [ ] `code_quality/task_metadata_validator.rb` - Validates task metadata
- [ ] `code_quality/template_embedding_validator.rb` - Validates embedded templates

### Code Atoms (4 components)
- [ ] `code/directory_creator.rb` - Creates directories safely
- [ ] `code/file_content_reader.rb` - Reads file contents
- [ ] `code/session_name_builder.rb` - Builds session names
- [ ] `code/session_timestamp_generator.rb` - Generates session timestamps

### Context Atoms (2 components)
- [ ] `context/context_config_loader.rb` - Loads context configuration
- [ ] `context/template_parser.rb` - Parses context templates

### Coverage Atoms (2 components)
- [ ] `coverage_calculator.rb` - Calculates test coverage percentages
- [ ] `coverage_file_reader.rb` - Reads coverage data files

### Directory/File Atoms (3 components)
- [ ] `directory_scanner.rb` - Scans directories for files
- [ ] `docs_dependencies_config_loader.rb` - Loads docs dependency config
- [ ] `dot_graph_writer.rb` - Writes DOT graph format

### Editor Atoms (2 components)
- [ ] `editor/editor_detector.rb` - Detects available editors
- [ ] `editor/editor_launcher.rb` - Launches editor commands

### Environment Atoms (2 components)
- [ ] `env_reader.rb` - Reads environment variables
- [ ] `file_reference_extractor.rb` - Extracts file references from text

### Git Atoms (5 components)
- [ ] `git/git_command_executor.rb` - Executes git commands
- [ ] `git/log_color_formatter.rb` - Formats git log with colors
- [ ] `git/repository_scanner.rb` - Scans git repositories
- [ ] `git/status_color_formatter.rb` - Formats git status with colors
- [ ] `git/submodule_detector.rb` - Detects git submodules

### JSON Atoms (2 components)
- [ ] `json_exporter.rb` - Exports data as JSON
- [ ] `json_formatter.rb` - Formats JSON output

### LLM Atoms (1 component)
- [ ] `llm/model_constants.rb` - Defines LLM model constants

### MCP Atoms (1 component)
- [ ] `mcp/protocol_validator.rb` - Validates MCP protocol messages

### Path Atoms (3 components)
- [x] `path_resolver.rb` - Resolves file paths
- [ ] `path_sanitizer.rb` - Sanitizes file paths for security
- [ ] `project_root_detector.rb` - Detects project root directory

### Ruby Atoms (1 component)
- [ ] `ruby_method_parser.rb` - Parses Ruby method definitions

### Search Atoms (5 components)
- [ ] `search/fd_executor.rb` - Executes fd (find) commands
- [ ] `search/pattern_analyzer.rb` - Analyzes search patterns
- [ ] `search/result_parser.rb` - Parses search results
- [ ] `search/ripgrep_executor.rb` - Executes ripgrep commands
- [ ] `search/tool_availability_checker.rb` - Checks if search tools available

### Security Atoms (1 component)
- [ ] `security_logger.rb` - Logs security-relevant events

### System Atoms (2 components)
- [ ] `system_command_executor.rb` - Executes system commands
- [ ] `table_renderer.rb` - Renders tables for CLI output

### Taskflow Management Atoms (5 components)
- [ ] `taskflow_management/directory_navigator.rb` - Navigates task directories
- [ ] `taskflow_management/file_system_scanner.rb` - Scans task file system
- [ ] `taskflow_management/shell_command_executor.rb` - Executes shell commands
- [ ] `taskflow_management/task_id_parser.rb` - Parses task IDs
- [ ] `taskflow_management/yaml_frontmatter_parser.rb` - Parses YAML frontmatter

### Utility Atoms (4 components)
- [ ] `threshold_validator.rb` - Validates threshold values
- [ ] `timestamp_generator.rb` - Generates timestamps
- [ ] `xdg_directory_resolver.rb` - Resolves XDG directories
- [ ] `yaml_reader.rb` - Reads YAML files

## Progress Tracking

- **Components completed:** 3/61 (1 removed as dead code)
- **Estimated time per component:** ~4 minutes
- **Current focus:** path_resolver complete with 23 tests passing using test project fixtures

## Implementation Plan

### Execution Steps

1. **Setup Test Infrastructure**
   - [ ] Create test/unit/atoms/ subdirectories matching lib structure
   - [ ] Set up shared test helpers for atoms

2. **Test Pure Functions First** (Priority: High)
   - [ ] Test path/file atoms (no external dependencies)
   - [ ] Test formatters and renderers (deterministic output)
   - [ ] Test parsers and validators (clear input/output)

3. **Test System Interaction Atoms** (Priority: Medium)
   - [ ] Test command executors with mocked system calls
   - [ ] Test file readers/scanners with fixture files
   - [ ] Test environment readers with controlled ENV

4. **Test Integration Points** (Priority: Low)
   - [ ] Test git atoms with test repositories
   - [ ] Test search atoms with sample data
   - [ ] Test editor atoms with mock editors

## Acceptance Criteria

- [ ] All 61 atom components have corresponding test files
- [ ] Each test file covers all public methods
- [ ] Tests pass with `ace-test atoms`
- [ ] No external dependencies or network calls in tests
- [ ] Tests run in parallel (using parallelize_me!)
- [ ] Clear test names describing behavior being tested

## Testing Guidelines

### Atom Test Principles
- Pure functions: same input always produces same output
- No side effects: no file writes, network calls, or state changes
- Fast execution: each test should run in milliseconds
- Isolated: no dependencies between tests
- Deterministic: no randomness or time-dependent behavior

### Example Test Structure
```ruby
class SomeAtomTest < AtomTest
  def test_pure_function_with_valid_input
    result = SomeAtom.process("input")
    assert_equal "expected", result
  end

  def test_handles_edge_cases
    assert_raises(ArgumentError) { SomeAtom.process(nil) }
  end
end
```

## Out of Scope

- Integration tests (covered in task.006/007)
- E2E tests (covered in separate tasks)
- Tests requiring external services
- Tests that modify file system

## References

- **Testing Guide**: `docs/development/testing.g.md` - Essential testing patterns and setup
- Test helper: `test/test_helper.rb`
- Atom base class: `AtomTest`
- Example atom test: `test/unit/atoms/path_resolver_test.rb`