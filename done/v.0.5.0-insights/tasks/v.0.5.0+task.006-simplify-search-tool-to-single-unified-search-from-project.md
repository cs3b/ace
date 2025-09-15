---
id: v.0.5.0+task.006
status: completed
priority: high
estimate: 3h
dependencies: []
needs_review: false
---

## Implementation Decisions (Resolved)

### Architecture Decisions
- ✅ **--repository flag**: Complete removal (no deprecation needed - unreleased feature)
- ✅ **Backward compatibility**: Not required (feature in testing phase)
- ✅ **Result format**: Pure path-based output (no repository grouping)
- ✅ **Default exclusions**: Keep existing defaults (archives/done tasks)
- ✅ **Search root detection**: Use ProjectRootDetector directly
- ✅ **Repository tagging**: Not needed (paths are self-explanatory)
- ✅ **DWIM heuristics**: Keep unchanged (independent of search execution)

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

### Planning Steps (Completed)

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
  - **Backward compatibility concern**: Not needed - unreleased feature
  - **Path format**: Change from repo-relative to project-relative paths throughout

### Research Findings Summary

**Key Discovery**: The current implementation already executes from project root (task.005 fix), but still maintains complex multi-repository iteration that is causing duplicate results. The simplification will remove the iteration layer while preserving the working root directory execution.

### Execution Steps (Ready for Implementation)

- [ ] **Step 1: Remove MultiRepoCoordinator from UnifiedSearcher**
  - Remove `@coordinator = Molecules::Git::MultiRepoCoordinator.new`
  - Add `@project_root = ProjectRootDetector.find_project_root`
  - Keep executors and DWIM heuristics
  - Simplify aggregator to basic formatter
  > TEST: Verify initialization
  > Type: Unit test
  > Assert: UnifiedSearcher initializes without MultiRepoCoordinator
  > Command: `rspec spec/lib/coding_agent_tools/organisms/search/unified_searcher_spec.rb`

- [ ] **Step 2: Refactor main search method**
  - Remove `get_repositories` call
  - Remove `search_repositories` iteration
  - Call executors directly with pattern and options
  - Simplify result handling
  > TEST: Basic search functionality
  > Type: Integration test
  > Assert: Search returns results without duplicates
  > Command: `./exe/search "TODO" | grep -c "TODO"`

- [ ] **Step 3: Update search execution logic**
  - Remove `search_single_repository` method
  - Remove `Dir.chdir` logic (already executing from project root)
  - Call executors directly without repository context
  - Ensure paths in results are project-relative
  > TEST: Path correctness
  > Type: Integration test
  > Assert: Results show correct relative paths from project root
  > Command: `./exe/search "task" --include dev-taskflow | head -5`

- [ ] **Step 4: Simplify executor interfaces**
  - Remove `search_path` parameter from both executors
  - Execute searches from current directory (project root)
  - Keep all filtering options (--include, --exclude, --type)
  > TEST: Executor command building
  > Type: Unit test
  > Assert: Commands built without path parameters
  > Command: `rspec spec/atoms/search/*_executor_spec.rb`

- [ ] **Step 5: Simplify ResultAggregator**
  - Remove repository grouping logic
  - Convert to flat result list with paths
  - Keep count tracking for summary
  - Remove duplicate detection (no longer needed)
  > TEST: Result formatting
  > Type: Integration test
  > Assert: Flat result list with full paths
  > Command: `./exe/search "TODO" --json | jq '.results[0].path'`

- [ ] **Step 6: Update CLI output formatting**
  - Remove repository grouping from text output
  - Show flat list of results with paths
  - Update summary to show total count only
  - Remove --repository flag completely
  > TEST: CLI output format
  > Type: Integration test
  > Assert: No repository grouping in output
  > Command: `./exe/search "test" | grep -c "dev-tools:"`

- [ ] **Step 7: Verify path filtering**
  - Test --include with directory patterns
  - Test --exclude with glob patterns
  - Test combination of both filters
  - Ensure default exclusions still work
  > TEST: Path filtering
  > Type: Integration test
  > Assert: Filters work correctly
  > Command: `./exe/search "task" --include dev-tools --exclude "*/spec/*"`

- [ ] **Step 8: Performance validation**
  - Benchmark before/after implementation
  - Test with large result sets (1000+ matches)
  - Verify no duplicate results
  - Measure memory usage
  > TEST: Performance
  > Type: Benchmark
  > Assert: Faster execution, no duplicates
  > Command: `time ./exe/search "TODO" | sort | uniq -d`

- [ ] **Step 9: Update tests**
  - Update unit tests for simplified components
  - Add integration tests for new behavior
  - Remove multi-repository test scenarios
  - Add duplicate prevention tests
  > TEST: Test suite
  > Type: RSpec suite
  > Assert: All tests pass
  > Command: `bundle exec rspec spec/organisms/search/`

- [ ] **Step 10: Documentation updates**
  - Update search tool documentation
  - Remove references to repository iteration
  - Update CLI help text
  - Add migration notes if needed
  > TEST: Documentation
  > Type: Manual review
  > Assert: Docs match implementation
  > Command: `./exe/search --help`

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

## Implementation Summary

**Task Status**: Ready for implementation

**Decisions Made**: All 7 architectural questions resolved:
- ✅ Remove --repository flag completely (unreleased feature)
- ✅ No backward compatibility needed (testing phase)
- ✅ Pure path-based output format
- ✅ Keep default exclusions
- ✅ Use ProjectRootDetector directly
- ✅ No repository tagging in results
- ✅ Keep DWIM heuristics unchanged

**Implementation Strategy**: 
- Remove MultiRepoCoordinator complexity
- Execute single search from project root
- Flatten result structure
- Eliminate duplicate results

**Expected Benefits**:
- **Performance**: Single process execution (faster)
- **Simplicity**: Remove complex iteration logic
- **Correctness**: No duplicate results
- **UX**: Cleaner, flatter output

**Implementation Order**:
1. Execute task 006 simplification first
2. Then complete task 002 with tests/docs
3. This avoids duplicate effort on documentation

**Next Steps**: 
1. Begin implementation following the 10-step plan
2. Focus on removing multi-repo complexity
3. Validate no duplicates in results
4. Update tests after simplification
