---
id: v.0.5.0+task.006
status: pending
priority: high
estimate: 3h
dependencies: [v.0.5.0+task.005]
needs_review: true
---

## Review Questions (Pending Human Input)

### [HIGH] Architecture and Implementation Strategy Questions

- [ ] **Should the --repository flag be completely removed or deprecated with graceful fallback?**
  - **Research conducted**: Current CLI code shows --repository flag is actively used in line 114-116
  - **Current implementation**: Flag filters repositories in `get_repositories()` method
  - **Usage analysis**: Some users may rely on this flag for targeted searches
  - **Suggested approach**: Deprecate with warning message but maintain functionality temporarily
  - **Why needs human input**: Breaking change decision affects existing users and scripts

- [ ] **How should backward compatibility be handled during the transition?**
  - **Research conducted**: Current implementation has complex multi-repo coordination with specific paths
  - **Breaking changes identified**: 
    - Removal of MultiRepoCoordinator changes search execution model
    - Result format may change from repository-grouped to flat structure
    - Path references will change from repo-relative to project-relative
  - **Suggested approach**: Implement gradual migration with feature flags
  - **Why needs human input**: Migration strategy impacts user experience and rollback options

- [ ] **Should result format maintain repository context or switch to purely path-based?**
  - **Research conducted**: Current aggregator groups results by repository name (line 375-412 in CLI)
  - **User interface impact**: CLI output currently shows "repository_name: (X results)"
  - **Options considered**:
    - Keep repository grouping for clarity: `dev-tools: (5 results)`
    - Switch to flat list with path context: `./dev-tools/file.rb:10:text`
    - Hybrid approach with optional grouping flag
  - **Why needs human input**: UX decision affects how users interpret and navigate results

### [MEDIUM] Performance and Scope Questions

- [ ] **Should default exclusions be preserved or made explicit via --exclude?**
  - **Research conducted**: Current CLI has hardcoded default exclusions (lines 13-16)
  - **Default patterns**: `dev-taskflow/current/*/tasks/x/*`, `dev-taskflow/done/**/*`
  - **User behavior**: Users may depend on these defaults to filter noise
  - **Options**:
    - Keep defaults for familiarity
    - Remove defaults, require explicit --exclude for transparency
    - Make defaults configurable via .searchrc file
  - **Why needs human input**: Balances convenience vs explicit control preference

- [ ] **What should happen to the search root detection when MultiRepoCoordinator is removed?**
  - **Research conducted**: Current implementation uses `@coordinator.instance_variable_get(:@project_root)` (line 119)
  - **Project root detection**: Depends on ProjectRootDetector.find_project_root
  - **Alternative approaches**:
    - Use ProjectRootDetector directly in UnifiedSearcher
    - Always search from pwd unless --search-root specified
    - Remove search root concept entirely
  - **Why needs human input**: Determines search behavior consistency across different directory contexts

### [LOW] Enhancement and Future Direction Questions

- [ ] **Should we add optional repository tagging in results for clarity?**
  - **Research conducted**: Web search shows ripgrep best practices favor clear path context
  - **Current paths**: Results show relative paths from project root
  - **Enhancement options**:
    - Add `[repo]` prefix: `[dev-tools] ./dev-tools/lib/file.rb:10:text`
    - Add repository metadata to JSON output
    - Leave paths as-is (users can infer from path)
  - **Suggested default**: Path-only approach (simpler, follows ripgrep conventions)
  - **Why needs human input**: Feature scope decision for initial implementation

- [ ] **Should the DWIM heuristics engine behavior change with single search execution?**
  - **Research conducted**: Current engine analyzes patterns for file vs content search decisions
  - **Implementation status**: DWIM engine is independent of multi-repo coordination
  - **Behavior analysis**: Should remain unchanged as pattern analysis logic is still valuable
  - **Consideration**: Single search may provide different performance characteristics for hybrid searches
  - **Why needs human input**: Validation that existing heuristics remain optimal for unified search

# Simplify search tool to single unified search from project root

## Behavioral Specification

### User Experience
- **Input**: Search patterns and optional path filters (--include/--exclude)
- **Process**: Single, fast search execution from project root with real-time results display
- **Output**: Unified result list with no duplicates, showing all matches with their paths

### Expected Behavior
The search tool executes a single search from the project root directory, treating the entire project (including submodules) as one search space. Users get a clean, duplicate-free list of results. When users want to search only in specific directories, they use the intuitive `--include` flag. When they want to exclude paths, they use `--exclude`. The search behaves like standard grep/ripgrep that developers are familiar with.

Results appear in a single unified list, making it easy to see the total count and all matches at once. File paths in results clearly show which submodule or directory contains each match. The search is faster because it runs as a single process instead of multiple parallel searches.

### Interface Contract
```bash
# CLI Interface
search <pattern> [options]

# Search entire project (default behavior)
search "TODO"
# Output format:
# Found 45 results
#   ./README.md:10:0: TODO: Update installation
#   ./dev-taskflow/current/...:23:0: TODO: Review this
#   ./dev-tools/lib/...:45:0: TODO: Implement feature

# Search only in specific directory
search "TODO" --include dev-taskflow
# Output: Results only from paths matching dev-taskflow

# Search with multiple includes
search "TODO" --include "dev-tools,dev-handbook"
# Output: Results from both dev-tools and dev-handbook

# Exclude specific paths
search "TODO" --exclude "dev-taskflow/done/**/*"
# Output: All results except from excluded paths

# Combine include and exclude
search "TODO" --include dev-taskflow --exclude "*/done/**"
# Output: Results from dev-taskflow, excluding done directories
```

**Error Handling:**
- [Pattern not found]: Display "No results found" with search context
- [Invalid path in --include]: Continue search, warn about invalid path
- [Invalid glob pattern]: Display clear error message with pattern syntax help

**Edge Cases:**
- [Empty pattern]: Show error "Search pattern required"
- [Conflicting include/exclude]: Include takes precedence, then exclude filters
- [No searchable files]: Display "No searchable files found in specified paths"

### Success Criteria
- [ ] **No Duplicates**: Each file appears exactly once in search results
- [ ] **Single Execution**: Search runs as one process from project root
- [ ] **Path Filtering**: --include and --exclude work intuitively for directory targeting
- [ ] **Performance**: Measurable speed improvement over multi-repository search
- [ ] **Backward Compatible**: Existing exclude patterns continue to work
- [ ] **Clear Output**: Results show full paths relative to project root

### Validation Questions
- [ ] **Repository Context**: Should we optionally show which repository owns each file (e.g., prefix with [dev-tools])?
- [ ] **Backward Compatibility**: Should we keep --repository flag for compatibility or deprecate it?
- [ ] **Default Excludes**: Should default exclusions (like dev-taskflow/done) remain active?
- [ ] **Output Grouping**: Should we offer optional grouping by directory/repository?

## Objective

Simplify the search tool implementation and user experience by eliminating duplicate results and complex multi-repository logic, providing a single, fast, unified search across the entire project.

## Scope of Work

- **User Experience Scope**: All search operations across the project, path filtering, result display
- **System Behavior Scope**: Single search execution, path filtering logic, result formatting
- **Interface Scope**: search command with --include/--exclude options, output format

### Deliverables

#### Behavioral Specifications
- Unified search behavior definition
- Path filtering interface specification
- Result display format specification

#### Validation Artifacts
- Performance comparison metrics (before/after)
- Duplicate elimination verification
- Path filtering test scenarios

## Out of Scope

- ❌ **Implementation Details**: Specific code refactoring approach
- ❌ **Technology Decisions**: Which search libraries or algorithms to use
- ❌ **Performance Optimization**: Specific optimization techniques beyond single execution
- ❌ **Future Enhancements**: Additional search features not related to unification

## References

- Previous implementation discussion and analysis
- Current multi-repository search issues (duplicates)
- User feedback on search tool behavior

## Technical Approach

### Architecture Pattern
- Simplify from multi-repository coordinator pattern to single search execution
- Remove repository iteration and aggregation complexity
- Maintain existing executor pattern (ripgrep/fd) for actual search
- Keep DWIM heuristics for search mode detection

### Technology Stack
- Continue using ripgrep for content search (already proven)
- Continue using fd for file search (already integrated)
- Remove MultiRepoCoordinator dependency
- Simplify ResultAggregator to basic formatter
- Maintain existing ShellCommandExecutor for command execution

### Implementation Strategy
- Incremental refactoring to minimize risk
- Preserve existing CLI interface where possible
- Keep default exclusions functionality
- Maintain backward compatibility for critical options

## File Modifications

### Modify
- `lib/coding_agent_tools/organisms/search/unified_searcher.rb`
  - Changes: Remove multi-repository logic, simplify to single search
  - Impact: Core search execution simplified
  - Integration points: Direct executor calls without repository iteration

- `lib/coding_agent_tools/organisms/search/result_aggregator.rb`
  - Changes: Simplify from multi-repo aggregation to single result formatting
  - Impact: Simpler result processing
  - Integration points: Format results from single search

- `lib/coding_agent_tools/atoms/search/ripgrep_executor.rb`
  - Changes: Remove search_path complexity, search from current directory
  - Impact: Simpler command building
  - Integration points: Direct search execution

- `lib/coding_agent_tools/atoms/search/fd_executor.rb`
  - Changes: Remove search_path complexity, search from current directory
  - Impact: Simpler command building
  - Integration points: Direct search execution

- `exe/search`
  - Changes: Update help text, possibly deprecate --repository option
  - Impact: User-facing interface changes
  - Integration points: CLI option handling

### Delete
- None required - refactoring existing files

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing scripts that use --repository flag
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Keep flag but make it no-op with deprecation warning
  - **Rollback:** Restore multi-repo logic if needed

- **Risk:** Performance regression for large codebases
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Single process should be faster, but monitor
  - **Rollback:** Revert to multi-repo if performance degrades

### Integration Risks
- **Risk:** Path filtering behaves differently
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Extensive testing of include/exclude patterns
  - **Monitoring:** Test with existing exclude patterns

## Implementation Plan

### Planning Steps

* [x] **Analyze current multi-repository flow in detail**
  - **Repository discovery**: MultiRepoCoordinator uses RepositoryScanner to discover repositories
  - **Iteration pattern**: `search_repositories()` iterates through each repo, calls `search_single_repository()`
  - **Current result structure**: Results grouped by repository name with metadata
  - **Key finding**: Complex Dir.chdir logic for each repository search (line 128 in UnifiedSearcher)

* [x] **Research ripgrep/fd direct usage patterns**
  - **Command verification**: Both executors support project-wide search from root directory
  - **Performance analysis**: Web research shows ripgrep excels at single large directory searches
  - **Path filtering**: Current --include/--exclude work via ResultAggregator filtering after search
  - **Best practice**: Single process execution is faster than multiple coordinated searches

* [x] **Design simplified result structure**
  - **Current format**: `{repositories: {repo_name: {results: [...], count: N}}}`
  - **Proposed format**: `{results: [...], total_count: N}` with full paths
  - **Backward compatibility concern**: CLI output parser may need updates
  - **Path format**: Change from repo-relative to project-relative paths throughout

### Research Findings Summary

**Key Discovery**: The current implementation already executes from project root (task.005 fix), but still maintains complex multi-repository iteration that may be causing duplicate results. The simplification can focus on removing the iteration layer while preserving the working root directory execution.

### Execution Steps

- [ ] Step 1: Simplify UnifiedSearcher initialization
  - Remove `@coordinator = Molecules::Git::MultiRepoCoordinator.new`
  - Keep executors and DWIM heuristics
  - Remove `@aggregator` or simplify its role
  > TEST: Verify initialization
  > Type: Unit test
  > Assert: UnifiedSearcher initializes without MultiRepoCoordinator
  > Command: `rspec spec/lib/coding_agent_tools/organisms/search/unified_searcher_spec.rb`

- [ ] Step 2: Refactor main search method
  - Remove `get_repositories` call
  - Remove `search_repositories` iteration
  - Call executors directly with pattern and options
  - Simplify result handling
  > TEST: Basic search functionality
  > Type: Integration test
  > Assert: Search returns results without duplicates
  > Command: `./exe/search "TODO" | grep -c "TODO"`

- [ ] Step 3: Update search execution logic
  - Remove `search_single_repository` method
  - Remove `Dir.chdir` logic
  - Execute search from current directory (project root)
  - Ensure paths in results are relative to project root
  > TEST: Path correctness
  > Type: Integration test
  > Assert: Results show correct relative paths
  > Command: `./exe/search "task" --include dev-taskflow | head -5`

- [ ] Step 4: Simplify ripgrep executor
  - Remove `search_path` option handling
  - Always search from current directory
  - Keep existing option handling for filters
  > TEST: Ripgrep execution
  > Type: Unit test
  > Assert: Ripgrep command built correctly
  > Command: `ruby -e "require_relative 'lib/coding_agent_tools'; puts CodingAgentTools::Atoms::Search::RipgrepExecutor.new.build_ripgrep_command('test')"`

- [ ] Step 5: Simplify fd executor
  - Remove `search_path` option handling
  - Always search from current directory
  - Keep existing option handling for filters
  > TEST: Fd execution
  > Type: Unit test
  > Assert: Fd command built correctly
  > Command: `ruby -e "require_relative 'lib/coding_agent_tools'; puts CodingAgentTools::Atoms::Search::FdExecutor.new.build_fd_command('*.rb')"`

- [ ] Step 6: Update result aggregator
  - Remove repository-based aggregation logic
  - Simplify to basic result formatting
  - Maintain count tracking
  - Remove duplicate filtering (no longer needed)
  > TEST: Result formatting
  > Type: Integration test
  > Assert: Results formatted correctly without repository grouping
  > Command: `./exe/search "TODO" --json | jq '.total_results'`

- [ ] Step 7: Test path filtering
  - Verify --include works for directory targeting
  - Verify --exclude continues to work
  - Test combination of include and exclude
  > TEST: Include filtering
  > Type: Integration test
  > Assert: Include filter limits results to specified paths
  > Command: `./exe/search "task" --include dev-tools | grep -v "dev-taskflow"`

- [ ] Step 8: Update CLI interface
  - Update help text to reflect single search
  - Consider deprecating --repository option
  - Ensure backward compatibility where needed
  > TEST: CLI compatibility
  > Type: Integration test
  > Assert: Existing CLI options still work
  > Command: `./exe/search "test" --exclude "spec/**/*"`

- [ ] Step 9: Performance validation
  - Compare search times before and after
  - Test with large result sets
  - Verify memory usage is acceptable
  > TEST: Performance comparison
  > Type: Performance test
  > Assert: Single search is faster than multi-repo
  > Command: `time ./exe/search "TODO" > /dev/null`

- [ ] Step 10: Update documentation
  - Update search tool documentation
  - Document migration from multi-repo to single search
  - Update examples in help text
  > TEST: Documentation completeness
  > Type: Manual review
  > Assert: All documentation reflects new behavior
  > Command: `./exe/search --help | grep -i "repository"`

### Enhanced Test Scenarios (Based on Research)

- [ ] **Duplicate Detection Test**
  - Verify no duplicate results across submodules
  - Test with files that exist in multiple repositories
  - Compare result counts before/after simplification
  > Command: `./exe/search "TODO" | sort | uniq -d` (should show no duplicates)

- [ ] **Backward Compatibility Test**
  - Test deprecated --repository flag behavior
  - Verify existing scripts continue to work with warnings
  - Test result format parsing in downstream tools
  > Command: `./exe/search "test" --repository dev-tools 2>&1 | grep -i "deprecat"`

- [ ] **Performance Comparison Test**
  - Time searches before and after simplification
  - Test with large result sets (>1000 matches)
  - Monitor memory usage during search
  > Command: `time ./exe/search "TODO" > /dev/null`

- [ ] **Path Context Test**
  - Verify all results show full project-relative paths
  - Test that include/exclude patterns work with new path format
  - Ensure consistent path format across file and content searches
  > Command: `./exe/search "task" --include dev-taskflow | head -5 | grep "dev-taskflow"`

## Acceptance Criteria

- [ ] Search executes as single process from project root
- [ ] No duplicate results in any search scenario
- [ ] Path filtering with --include/--exclude works correctly
- [ ] Performance improved (measurable via timing)
- [ ] Existing exclude patterns continue to work
- [ ] Results show clear paths relative to project root
- [ ] All tests pass successfully

## Review Summary

**Task Status**: Pending (unchanged) - awaiting human input on critical architectural decisions

**Questions Generated**: 6 total (3 HIGH, 2 MEDIUM, 1 LOW)

**Critical Blockers**: 
- Repository flag deprecation strategy (breaking change impact)
- Backward compatibility approach during transition
- Result format decision (repository grouping vs flat structure)

**Research Conducted**:
- **Codebase Analysis**: Reviewed UnifiedSearcher, ResultAggregator, CLI, and MultiRepoCoordinator implementations
- **Related Tasks**: Analyzed task.002 (completed search tool) and task.005 (path filtering fix) 
- **Web Search**: Researched ripgrep best practices for single vs multi-repository search patterns
- **Performance Insights**: Single process execution confirmed as optimal approach

**Key Research Sources**:
- Current implementation files: 4 key classes analyzed
- Related tasks: 2 tasks providing implementation context  
- External research: Ripgrep performance best practices from 2025 documentation

**Content Updates Made**:
- Added comprehensive review questions with research context
- Updated planning steps with completed research findings
- Enhanced test scenarios based on implementation analysis
- Added research findings summary with key discovery

**Implementation Readiness**: Blocked on human decisions - technical approach is clear but requires UX and compatibility decisions

**Recommended Next Steps**: 
1. Answer HIGH priority questions about repository flag and backward compatibility
2. Make result format decision based on user preference
3. Proceed with implementation using research-validated technical approach

**Processing Status**: Completed - all review workflow steps executed successfully