---
id: v.0.5.0+task.002
status: pending
priority: high
estimate: 16h
dependencies: []
---

# Unified Project-Aware Search Tool

## Behavioral Specification

### User Experience
- **Input**: Search patterns/globs with optional flags from any project subdirectory
- **Process**: Automatic project root detection, DWIM mode selection, git-aware file enumeration, multi-repository coordination
- **Output**: Editor-friendly results with context lines, interactive fzf selection, or structured JSON for automation

### Expected Behavior
Users experience a single, intelligent search command that seamlessly handles both file name and content searches across their entire project, including submodules and nested repositories. The tool automatically detects the project root from any subdirectory, making search behavior consistent regardless of where it's invoked. Smart DWIM heuristics determine whether users want to search file names, file contents, or both based on the pattern and flags provided. Git-aware scopes allow focusing searches on tracked, staged, changed, or recent files with time-based filtering.

The system provides immediate visual feedback with streaming results, context lines around matches, and syntax highlighting. Interactive mode with fzf enables real-time preview and selection, while the `--open` flag allows direct navigation to matches in the user's preferred editor. For automation needs, structured JSON output conforms to a documented schema.

### Interface Contract
```bash
# CLI Interface
search [FLAGS] [--] <pattern>
search --files [FLAGS] [--] <glob>...  
search --preset <name> [--var k=v ...] [FLAGS] [--] <pattern?>

# Key flags
-C, --context <N>         # Lines of context (default: 2)
-n, --name <glob>         # Include only matching files
-t, --type <types>        # File types (rb, js, ts, etc.)
--tracked/--staged        # Git-aware scopes
--changed [<range>]       # Changed files in range
--since <time>           # Files changed since time
--fzf                    # Interactive mode
--open                   # Open in $EDITOR
--json                   # Machine-readable output
```

**Error Handling:**
- Missing dependencies: Actionable install instructions
- Invalid git ranges: Clear error messages with examples
- No matches: Exit code 1 (distinguishable from errors)
- Conflicting flags: Helpful explanations with corrections

**Edge Cases:**
- Empty pattern: Show usage help
- Massive result sets: Respect --max-results limit
- Binary files: Skip with notification
- Symlinks: Follow with cycle detection
- Large files: Stream results efficiently

### Success Criteria
- [ ] **Project Root Detection**: Tool finds root from any subdirectory within 50ms
- [ ] **DWIM Accuracy**: Mode selection matches user intent 90%+ of the time
- [ ] **Multi-Repository Support**: Seamless search across submodules and nested repos
- [ ] **Editor Integration**: --open flag works with VS Code, Vim, Sublime
- [ ] **Performance**: Startup ≤ 200ms, results begin streaming immediately
- [ ] **Git Integration**: Scopes correctly enumerate files across all repositories
- [ ] **JSON Schema**: Output validates against documented schema
- [ ] **Preset System**: User-defined presets merge correctly with CLI flags

### Validation Questions
- [ ] **Requirement Clarity**: Should binary file handling be configurable or always skip?
- [ ] **Edge Case Handling**: How should the tool handle repositories with no commits?
- [ ] **User Experience**: Should --fzf mode support multi-select for batch operations?
- [ ] **Success Definition**: What constitutes acceptable performance for 100k+ file repos?

## Objective

Provide developers and AI agents with a unified, intelligent search tool that eliminates the complexity of choosing between `fd`, `rg`, `grep`, and `git grep`. Enable efficient code discovery and navigation across complex multi-repository projects with smart defaults and powerful customization options.

## Scope of Work

- **User Experience Scope**: All search interactions from simple pattern matching to complex multi-repository queries
- **System Behavior Scope**: File enumeration, content searching, git integration, result formatting
- **Interface Scope**: CLI with comprehensive flags, configuration files, preset system, editor integrations

### Deliverables

#### Behavioral Specifications
- Complete DWIM heuristics definition
- Git-aware scope enumeration algorithms
- Multi-repository coordination logic
- Interactive mode user flows

#### Validation Artifacts
- Performance benchmarks for various repository sizes
- DWIM accuracy test suite
- Editor integration test scenarios
- JSON schema validation tests

## Out of Scope

- ❌ **Implementation Details**: Ruby gem structure, ATOM architecture specifics
- ❌ **Technology Decisions**: Specific Faraday configurations, caching strategies
- ❌ **Performance Optimization**: Detailed threading models, memory management
- ❌ **Future Enhancements**: Language server integration, Windows support

## Code Review Findings

After thorough review of the existing codebase, significant reusable components have been identified:

### Reusable Components
1. **Command Execution**: `ShellCommandExecutor` provides robust command execution with timeout, retries, and safety checks
2. **File Operations**: Multiple existing atoms handle file scanning, pattern matching, and directory traversal
3. **Multi-Repository**: `MultiRepoCoordinator` already implements cross-repository execution patterns
4. **Output Formatting**: `FormatHandlers` provides extensible formatting infrastructure
5. **Project Navigation**: `ProjectRootDetector` handles automatic root detection from any subdirectory

### Components to Create
- Minimal new atoms needed: only wrappers for ripgrep/fd that use existing executors
- DWIM heuristics engine (new logic for intelligent mode selection)
- Search-specific result formatting and aggregation
- FZF integration (no existing implementation)

### Key Implementation Insights
- No need to create new command execution infrastructure
- Can leverage existing error handling and result patterns
- Multi-repository support requires minimal new code
- Most complexity will be in DWIM heuristics and result aggregation

## Technical Approach

### Architecture Pattern
The search tool will follow the ATOM architecture pattern established in the dev-tools codebase:
- **Atoms**: Low-level search executors (ripgrep wrapper, fd wrapper, git wrapper), pattern matchers, result parsers
- **Molecules**: DWIM heuristics engine, scope enumerator, result formatter, fzf integrator
- **Organisms**: Search orchestrator coordinating all search operations across repositories
- **CLI Command**: Main search command with comprehensive flag handling

### Technology Stack
- **External Tools**: ripgrep (content search), fd (file search), fzf (interactive selection), git (repository awareness)
- **Ruby Process Management**: Open3 for safe command execution with streaming output
- **Existing Components to Reuse**: 
  - `Atoms::TaskflowManagement::ShellCommandExecutor` - Safe command execution with timeout, retries, and output capture
  - `Atoms::SystemCommandExecutor` - Simple command execution and availability checking
  - `Atoms::ProjectRootDetector` - Automatic project root detection from any subdirectory
  - `Atoms::DirectoryScanner` - Directory scanning with glob patterns and exclusions
  - `Atoms::TaskflowManagement::FileSystemScanner` - File pattern matching and traversal
  - `Atoms::JSONFormatter` - Structured JSON output formatting
  - `Molecules::Git::MultiRepoCoordinator` - Multi-repository coordination across submodules
  - `Molecules::Code::FilePatternExtractor` - Pattern matching and file extraction logic
  - `Molecules::FormatHandlers` - Output formatting for different modes (text, json, etc.)
  - `Atoms::Git::RepositoryScanner` - Repository discovery and enumeration
  - `Atoms::Git::GitCommandExecutor` - Git command execution with repository context

### Implementation Strategy
1. Wrap external tools (rg, fd) with Ruby atoms for consistent interface
2. Build DWIM heuristics based on pattern analysis (glob patterns → file search, regex → content search)
3. Leverage existing multi-repo infrastructure for seamless submodule support
4. Stream results in real-time for responsive user experience
5. Support both CLI and programmatic usage for AI agent integration

### Implementation Patterns to Follow
Based on review of existing codebase:
1. **Command Execution**: Use `ShellCommandExecutor` for all external tool calls (ripgrep, fd, fzf)
   - Provides timeout, retry, safe execution, and output capture
   - Returns structured `CommandResult` with success status and duration
2. **File Operations**: Reuse existing atoms for file system operations
   - `DirectoryScanner` for local file enumeration
   - `FileSystemScanner` for pattern-based file finding
   - `ProjectRootDetector` for automatic root detection
3. **Multi-Repository**: Use `MultiRepoCoordinator` patterns
   - Filter repositories with options[:repository]
   - Execute across repositories with proper error handling
4. **Output Formatting**: Follow `FormatHandlers` pattern
   - Separate formatters for text, JSON, and other output modes
   - Include metadata (execution time, provider info) in structured output
5. **Error Handling**: Follow existing patterns
   - Return hash with `:success`, `:error`, `:output` keys
   - Provide actionable error messages for missing dependencies
6. **Testing**: Follow existing RSpec patterns
   - Unit tests for atoms with minimal dependencies
   - Integration tests for molecules and organisms
   - Use VCR for external command recording where appropriate

## Tool Selection

| Criteria | ripgrep + fd | Pure Ruby | git grep only | Selected |
|----------|--------------|-----------|---------------|----------|
| Performance | Excellent | Poor | Good | ripgrep + fd |
| Features | Complete | Limited | Limited | ripgrep + fd |
| Git Integration | Via flags | Manual | Native | ripgrep + fd |
| Maintenance | External deps | Self-contained | Git only | ripgrep + fd |

**Selection Rationale:** ripgrep and fd are industry-standard tools with exceptional performance and features. They're widely available and provide the best user experience.

## File Modifications

### Create (New Components Only)
- dev-tools/lib/coding_agent_tools/atoms/search/
  - ripgrep_executor.rb - Wrapper for ripgrep using ShellCommandExecutor
  - fd_executor.rb - Wrapper for fd using ShellCommandExecutor
  - pattern_analyzer.rb - Analyze patterns for DWIM mode selection
  - result_parser.rb - Parse ripgrep/fd output into structured format

- dev-tools/lib/coding_agent_tools/molecules/search/
  - dwim_heuristics_engine.rb - Intelligent mode selection based on pattern
  - git_scope_enumerator.rb - Enumerate files based on git scopes (staged, tracked, changed)
  - search_result_formatter.rb - Format search results for different output modes
  - fzf_integrator.rb - Interactive selection with preview using ShellCommandExecutor
  - preset_manager.rb - Load and merge search presets from config
  - time_filter.rb - Filter files by modification time using File.stat

- dev-tools/lib/coding_agent_tools/organisms/search/
  - search_orchestrator.rb - Main search coordination logic
  - unified_searcher.rb - Coordinate searches across repos using MultiRepoCoordinator

- dev-tools/lib/coding_agent_tools/cli/commands/search.rb
  - Main CLI command implementation

- dev-tools/exe/search
  - Executable wrapper script

- dev-tools/spec/coding_agent_tools/atoms/search/*_spec.rb
  - Unit tests for all atoms

- dev-tools/spec/coding_agent_tools/molecules/search/*_spec.rb
  - Unit tests for all molecules

- dev-tools/spec/coding_agent_tools/organisms/search/*_spec.rb
  - Integration tests for orchestrator

- dev-tools/spec/coding_agent_tools/cli/commands/search_spec.rb
  - CLI command tests

### Modify
- dev-tools/lib/coding_agent_tools/cli.rb
  - Register new search command
  
- dev-tools/lib/coding_agent_tools/organisms/tool_lister.rb
  - Add search tool to categorization

## Test Case Planning

### Happy Path Scenarios
- Search for file by name pattern: `search "*.rb"`
- Search for content with regex: `search "def.*initialize"`
- Search with context lines: `search -C 3 "TODO"`
- Interactive selection: `search --fzf "class"`
- JSON output for automation: `search --json "pattern"`

### Edge Case Scenarios
- Empty pattern → Show usage help
- No matches found → Exit code 1 with clear message
- Binary file handling → Skip with notification
- Symlink cycles → Detect and handle gracefully
- Large result sets → Respect --max-results limit
- Unicode in patterns → Proper encoding handling

### Error Condition Scenarios
- Missing ripgrep/fd → Actionable install instructions
- Invalid regex pattern → Clear error with correction hints
- Permission denied on files → Continue search, note skipped files
- Git repository errors → Fall back to non-git search

### Integration Scenarios
- Multi-repository search → Coordinate across all submodules
- Git scope filtering → Correctly enumerate tracked/staged files
- Time-based filtering → Accurate file selection
- Editor integration → Proper formatting for VS Code, Vim

### Performance Scenarios
- Large repository (100k+ files) → Start streaming within 200ms
- Deep directory trees → Efficient traversal
- Network filesystems → Timeout handling
- Concurrent searches → Resource management

## Risk Assessment

### Technical Risks
- **Risk:** External tool availability (ripgrep/fd not installed)
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Use SystemCommandExecutor.command_available? for detection, provide install instructions
  - **Rollback:** Fall back to git grep or DirectoryScanner for basic functionality

- **Risk:** Performance degradation on large repositories
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Use ripgrep's built-in optimizations, add --max-results flag
  - **Rollback:** Add performance tuning options

- **Risk:** Streaming output support in ShellCommandExecutor
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** ShellCommandExecutor currently buffers output; may need to enhance for real-time streaming
  - **Rollback:** Use buffered output initially, add streaming in optimization phase

### Integration Risks
- **Risk:** Breaking changes in external tool outputs
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Pin tool versions in documentation, comprehensive output parsing tests
  - **Monitoring:** Version detection and compatibility warnings

## Implementation Plan

### Planning Steps
* [x] Analyze ripgrep and fd command-line interfaces and output formats
* [x] Research Ruby process management best practices for streaming output
* [x] Design DWIM heuristics based on pattern analysis
* [x] Plan integration with existing multi-repo infrastructure
* [x] Define JSON output schema for structured results

### Execution Steps

#### Phase 1: Core Search Infrastructure
- [ ] Create ripgrep and fd executor atoms using ShellCommandExecutor
  > TEST: Tool Execution
  > Type: Unit Test
  > Assert: ripgrep and fd execute successfully using existing ShellCommandExecutor
  > Command: bin/test spec/atoms/search/ripgrep_executor_spec.rb spec/atoms/search/fd_executor_spec.rb

- [ ] Implement pattern analyzer for DWIM mode selection (reuse FilePatternExtractor logic)
  > TEST: Pattern Analysis
  > Type: Unit Test
  > Assert: Patterns correctly identified as file/content/hybrid searches
  > Command: bin/test spec/atoms/search/pattern_analyzer_spec.rb

- [ ] Build result parser for ripgrep/fd output formats
  > TEST: Result Parsing
  > Type: Unit Test
  > Assert: Tool outputs parsed into consistent internal format
  > Command: bin/test spec/atoms/search/result_parser_spec.rb

#### Phase 2: Search Intelligence
- [ ] Implement DWIM heuristics engine using pattern analysis
  > TEST: DWIM Mode Selection
  > Type: Integration Test
  > Assert: Search mode matches user intent 90%+ of the time
  > Command: bin/test spec/molecules/search/dwim_heuristics_engine_spec.rb

- [ ] Create git scope enumerator using GitCommandExecutor
  > TEST: Git Scope Enumeration
  > Type: Integration Test
  > Assert: Correctly identifies tracked/staged/changed files using git commands
  > Command: bin/test spec/molecules/search/git_scope_enumerator_spec.rb

- [ ] Build search result formatter extending FormatHandlers patterns
  > TEST: Output Formatting
  > Type: Unit Test
  > Assert: All output modes (text, json, fzf) produce correct format
  > Command: bin/test spec/molecules/search/search_result_formatter_spec.rb

#### Phase 3: Advanced Features
- [ ] Implement fzf integration for interactive selection
  > TEST: Interactive Mode
  > Type: Manual Test
  > Assert: fzf launches with preview and allows selection
  > Command: search --fzf "test"

- [ ] Add preset system for saved searches
  > TEST: Preset Loading
  > Type: Integration Test
  > Assert: Presets load and merge with CLI flags correctly
  > Command: bin/test spec/molecules/search/preset_manager_spec.rb

- [ ] Create time-based file filtering
  > TEST: Time Filtering
  > Type: Integration Test
  > Assert: Files filtered correctly by modification time
  > Command: search --since "1 week ago" "pattern"

#### Phase 4: Multi-Repository Support
- [ ] Create unified searcher using existing MultiRepoCoordinator
  > TEST: Multi-Repo Search
  > Type: Integration Test
  > Assert: Search spans all submodules using MultiRepoCoordinator.execute_across_repositories
  > Command: bin/test spec/organisms/search/unified_searcher_spec.rb

- [ ] Implement repository-aware result aggregation with repo context
  > TEST: Result Aggregation
  > Type: Integration Test
  > Assert: Results properly labeled with repository name and path
  > Command: search --json "TODO" | jq '.results[].repository'

#### Phase 5: CLI Integration
- [ ] Create main CLI command with comprehensive flags
  > TEST: CLI Command
  > Type: CLI Test
  > Assert: All flags work as documented
  > Command: bin/test spec/cli/commands/search_spec.rb

- [ ] Add search command to tool registry
  > TEST: Tool Discovery
  > Type: Integration Test
  > Assert: Search tool appears in tool listing
  > Command: exe/coding_agent_tools all | grep search

- [ ] Create executable wrapper
  > TEST: Executable
  > Type: Manual Test
  > Assert: Search command available from command line
  > Command: search --help

#### Phase 6: Documentation and Testing
- [ ] Write comprehensive unit tests for all components
  > TEST: Test Coverage
  > Type: Coverage Report
  > Assert: 95%+ code coverage for search components
  > Command: bin/test --coverage

- [ ] Add integration tests for complex scenarios
  > TEST: Integration Suite
  > Type: Integration Test
  > Assert: All user scenarios pass
  > Command: bin/test spec/integration/search_scenarios_spec.rb

- [ ] Create user documentation with examples
  > TEST: Documentation
  > Type: Manual Review
  > Assert: Clear usage examples for all features
  > Command: cat docs/user/search.md

- [ ] Validate performance benchmarks
  > TEST: Performance
  > Type: Benchmark
  > Assert: Startup ≤ 200ms, results begin streaming immediately
  > Command: time search "pattern" | head -1

## Acceptance Criteria
- [x] Project Root Detection: Tool finds root from any subdirectory within 50ms
- [ ] DWIM Accuracy: Mode selection matches user intent 90%+ of the time
- [ ] Multi-Repository Support: Seamless search across submodules and nested repos
- [ ] Editor Integration: --open flag works with VS Code, Vim, Sublime
- [ ] Performance: Startup ≤ 200ms, results begin streaming immediately
- [ ] Git Integration: Scopes correctly enumerate files across all repositories
- [ ] JSON Schema: Output validates against documented schema
- [ ] Preset System: User-defined presets merge correctly with CLI flags

## Out of Scope
- ❌ Windows-specific optimizations (focus on Unix-like systems initially)
- ❌ Language-specific parsing (leave for future language server integration)
- ❌ Custom ranking algorithms (use tool defaults initially)
- ❌ Cloud storage search integration

## References

- Source idea: dev-taskflow/backlog/ideas/20250809-1022-unified-project-aware-search-spec.md
- Similar tools: ripgrep, fd, git grep, ack, ag
- Integration examples: fzf.vim, telescope.nvim
- ATOM Architecture: docs/architecture-tools.md
