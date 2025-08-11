---
id: v.0.5.0+task.006
status: draft
priority: high
estimate: TBD
dependencies: [v.0.5.0+task.005]
---

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