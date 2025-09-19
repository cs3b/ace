---
id: v.0.8.0+task.004a
status: done
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
- [x] `claude/workflow_scanner.rb` - Scans for workflow instruction files
- [x] `claude/yaml_frontmatter_validator.rb` - Validates YAML frontmatter format

### CLI Atoms (1 component)
- [x] ~~`cli/cli_constants.rb`~~ - REMOVED (unused dead code)

### Code Quality Atoms (11 components)
- [x] `code_quality/cassettes_validator.rb` - Validates VCR cassette files
- [x] `code_quality/configuration_loader.rb` - Loads configuration files
- [x] `code_quality/error_distributor.rb` - Distributes errors by category
- [x] `code_quality/file_type_detector.rb` - Detects file types for linting
- [x] `code_quality/kramdown_formatter.rb` - Formats markdown with kramdown
- [x] `code_quality/language_file_filter.rb` - Filters files by language
- [x] `code_quality/markdown_link_validator.rb` - Validates markdown links
- [x] `code_quality/security_validator.rb` - Validates security rules
- [x] `code_quality/standard_rb_validator.rb` - Validates Ruby with StandardRB
- [x] `code_quality/task_metadata_validator.rb` - Validates task metadata
- [x] `code_quality/template_embedding_validator.rb` - Validates embedded templates

### Code Atoms (4 components)
- [x] `code/directory_creator.rb` - Creates directories safely
- [x] `code/file_content_reader.rb` - Reads file contents
- [x] `code/session_name_builder.rb` - Builds session names
- [x] `code/session_timestamp_generator.rb` - Generates session timestamps

### Context Atoms (2 components)
- [x] `context/context_config_loader.rb` - Loads context configuration
- [x] `context/template_parser.rb` - Parses context templates

### Coverage Atoms (2 components)
- [x] `coverage_calculator.rb` - Calculates test coverage percentages
- [x] `coverage_file_reader.rb` - Reads coverage data files

### Directory/File Atoms (3 components)
- [x] `directory_scanner.rb` - Scans directories for files (integration test)
- [x] `docs_dependencies_config_loader.rb` - Loads docs dependency config
- [x] `dot_graph_writer.rb` - Writes DOT graph format

### Editor Atoms (2 components)
- [x] `editor/editor_detector.rb` - Detects available editors
- [x] `editor/editor_launcher.rb` - Launches editor commands

### Environment Atoms (2 components)
- [x] `env_reader.rb` - Reads environment variables
- [x] `file_reference_extractor.rb` - Extracts file references from text

### Git Atoms (5 components)
- [x] `git/git_command_executor.rb` - Executes git commands
- [x] `git/log_color_formatter.rb` - Formats git log with colors
- [x] `git/repository_scanner.rb` - Scans git repositories
- [x] `git/status_color_formatter.rb` - Formats git status with colors
- [x] `git/submodule_detector.rb` - Detects git submodules

### JSON Atoms (2 components)
- [x] `json_exporter.rb` - Exports data as JSON
- [x] `json_formatter.rb` - Formats JSON output

### LLM Atoms (1 component)
- [x] ~~`llm/model_constants.rb`~~ - SKIPPED (dead code, not used)

### MCP Atoms (1 component)
- [x] `mcp/protocol_validator.rb` - Validates MCP protocol messages

### Path Atoms (3 components)
- [x] `path_resolver.rb` - Resolves file paths
- [x] `path_sanitizer.rb` - Sanitizes file paths for security
- [x] `project_root_detector.rb` - Detects project root directory

### Ruby Atoms (1 component)
- [x] `ruby_method_parser.rb` - Parses Ruby method definitions

### Search Atoms (5 components)
- [x] `search/fd_executor.rb` - Executes fd (find) commands
- [x] `search/pattern_analyzer.rb` - Analyzes search patterns
- [x] `search/result_parser.rb` - Parses search results
- [x] `search/ripgrep_executor.rb` - Executes ripgrep commands
- [x] `search/tool_availability_checker.rb` - Checks if search tools available

### Security Atoms (1 component)
- [x] `security_logger.rb` - Logs security-relevant events

### System Atoms (2 components)
- [x] `system_command_executor.rb` - Executes system commands
- [x] `table_renderer.rb` - Renders tables for CLI output

### Taskflow Management Atoms (5 components)
- [x] `taskflow_management/directory_navigator.rb` - Navigates task directories
- [x] `taskflow_management/file_system_scanner.rb` - Scans task file system
- [x] `taskflow_management/shell_command_executor.rb` - Executes shell commands
- [x] `taskflow_management/task_id_parser.rb` - Parses task IDs
- [x] `taskflow_management/yaml_frontmatter_parser.rb` - Parses YAML frontmatter

### Utility Atoms (4 components)
- [x] `threshold_validator.rb` - Validates threshold values
- [x] `timestamp_generator.rb` - Generates timestamps
- [x] `xdg_directory_resolver.rb` - Resolves XDG directories
- [x] `yaml_reader.rb` - Reads YAML files

## Progress Tracking

- **Components completed:** 61/61 (1 removed as dead code, all atoms have comprehensive unit tests)
- **Estimated time per component:** ~4 minutes
- **Latest batch results:** Fixed test isolation issues by moving I/O tests to integration
- **Current focus:** Tests are now deterministic and properly isolated

### Completed Batch 2 Summary (10 atoms, 364 tests)

1. ✅ `kramdown_formatter.rb` - 35 tests
2. ✅ `language_file_filter.rb` - 35 tests
3. ✅ `markdown_link_validator.rb` - 35 tests
4. ✅ `security_validator.rb` - 30 tests
5. ✅ `standard_rb_validator.rb` - 36 tests
6. ✅ `task_metadata_validator.rb` - 51 tests
7. ✅ `template_embedding_validator.rb` - 33 tests
8. ✅ `context_config_loader.rb` - 30 tests (found bug: undefined Error constant)
9. ✅ `template_parser.rb` - 40 tests
10. ✅ `coverage_calculator.rb` - 38 tests

### Completed Batch 3 Summary (10 atoms, 354 tests)

1. ✅ `coverage_file_reader.rb` - 32 tests
2. ✅ `directory_scanner.rb` - 22 tests (moved to integration/atoms/)
3. ✅ `docs_dependencies_config_loader.rb` - 43 tests
4. ✅ `dot_graph_writer.rb` - 30 tests
5. ✅ `editor/editor_detector.rb` - 30 tests
6. ✅ `editor/editor_launcher.rb` - 47 tests
7. ✅ `env_reader.rb` - 43 tests
8. ✅ `file_reference_extractor.rb` - 46 tests
9. ✅ `git/git_command_executor.rb` - 21 tests
10. ✅ `git/log_color_formatter.rb` - 40 tests

### Next Batch Queue (10 atoms)

1. `git/repository_scanner.rb` - Scans git repositories
2. `git/status_color_formatter.rb` - Formats git status with colors
3. `git/submodule_detector.rb` - Detects git submodules
4. `json_exporter.rb` - Exports data as JSON
5. `json_formatter.rb` - Formats JSON output
6. `llm/model_constants.rb` - Defines LLM model constants
7. `mcp/protocol_validator.rb` - Validates MCP protocol messages
8. `path_sanitizer.rb` - Sanitizes file paths for security
9. `ruby_method_parser.rb` - Parses Ruby method definitions
10. `search/fd_executor.rb` - Executes fd (find) commands

## Implementation Plan

### Parallel Test Creation Process

Each batch of 10 atoms should be tested using parallel sub-tasks with the following structure:

#### Sub-Task Instructions Template

```
1. LOAD CONTEXT FILES:
   - Read testing guide: /Users/mc/Ps/ace/.ace/tools/docs/development/testing.g.md
   - Read test helper: /Users/mc/Ps/ace/.ace/tools/test/test_helper.rb
   - Read example test: /Users/mc/Ps/ace/.ace/tools/test/unit/atoms/claude/command_existence_checker_test.rb
   - Read target atom: /Users/mc/Ps/ace/.ace/tools/lib/ace_tools/atoms/[category]/[atom_name].rb

2. VERIFY ATOM USAGE:
   - Run: search "[AtomClassName]" --content --hidden --include .ace/tools
   - Confirm atom is actually used in production code
   - Skip test creation if dead code found (no usage)

3. CREATE COMPREHENSIVE TEST FILE:
   - Location: test/unit/atoms/[category]/[atom_name]_test.rb
   - Use AtomTest base class (inherits parallelize_me!)
   - Test ALL public methods comprehensively
   - Include edge cases and error conditions
   - Use descriptive test method names (test_action_condition)
   - No external dependencies or network calls
   - Use temporary directories/files as needed

4. VERIFY TEST EXECUTION:
   - Run: ace-test test/unit/atoms/[category]/[atom_name]_test.rb
   - Ensure all tests pass (0 failures, 0 errors)
   - Fix any failures before marking complete
   - Verify test can run independently

5. REPORT RESULTS:
   - Number of tests created
   - Coverage of public methods
   - Any special considerations discovered
```

### Execution Steps

1. **Setup Test Infrastructure** ✅
   - [x] Create test/unit/atoms/ subdirectories matching lib structure
   - [x] Set up shared test helpers for atoms

2. **Test Pure Functions First** (Priority: High)
   - [x] Test path/file atoms (path_resolver, file_content_reader, directory_creator)
   - [x] Test formatters and renderers (error_distributor, file_type_detector)
   - [x] Test parsers and validators (yaml_frontmatter_validator, cassettes_validator)

3. **Test System Interaction Atoms** (Priority: Medium) - IN PROGRESS
   - [ ] Test command executors with mocked system calls
   - [ ] Test file readers/scanners with fixture files
   - [ ] Test environment readers with controlled ENV

4. **Test Integration Points** (Priority: Low)
   - [ ] Test git atoms with test repositories
   - [ ] Test search atoms with sample data
   - [ ] Test editor atoms with mock editors

## Acceptance Criteria

- [x] All 61 atom components have corresponding test files
- [x] Each test file covers all public methods
- [x] Tests pass with `ace-test atoms`
- [x] No external dependencies or network calls in tests
- [x] Tests run in parallel (using parallelize_me!)
- [x] Clear test names describing behavior being tested

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