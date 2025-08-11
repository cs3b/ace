---
id: v.0.5.0+task.007
status: done
priority: high
estimate: 30m
dependencies: ["v.0.5.0+task.006"]
---

# Fix search command --search-root flag behavior

## Behavioral Context

**Issue**: The `--search-root` flag in the search command was not working correctly. When users tried to search from a specific directory using `--search-root`, it would still search from the current directory instead of the specified path.

**Key Behavioral Requirements**:
- Search should default to project root regardless of current working directory
- `--search-root .` should explicitly search from current directory
- `--search-root /path` should search from the specified path
- The behavior should be consistent and predictable

## Objective

Fixed the search command to properly handle the `--search-root` flag, ensuring it searches from the project root by default and only searches from the current directory when explicitly requested.

## Scope of Work

- Fixed naming mismatch between CLI option (`search_root`) and executor expectation (`search_path`)
- Modified UnifiedSearcher to use project root as default search path
- Updated CLI to properly map and handle the `--search-root` option
- Improved help text to clarify the new behavior

### Deliverables

#### Modify

- `/Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-tools/exe/search`
  - Added mapping from `search_root` to `search_path` for executor compatibility
  - Special handling for `--search-root .` to use current directory
  - Updated help text to clarify behavior

- `/Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-tools/lib/coding_agent_tools/organisms/search/unified_searcher.rb`
  - Modified `search_files` and `search_content_direct` methods
  - Added logic to use project root as default search path
  - Ensured search_path option is properly passed to executors

## Implementation Summary

### What Was Done

- **Problem Identification**: User reported that `--search-root` flag wasn't working when trying to search from project root while in a subdirectory
- **Investigation**: Discovered a naming mismatch - CLI used `search_root` but executors expected `search_path`
- **Root Cause**: The UnifiedSearcher wasn't passing any search path to executors, causing them to default to current directory
- **Solution**: 
  1. Modified UnifiedSearcher to pass project root as default `search_path`
  2. Fixed CLI to map `search_root` to `search_path` for compatibility
  3. Added special handling for `--search-root .` to mean current directory
- **Validation**: Tested from various directories to confirm correct behavior

### Technical Details

The fix involved two main components:

1. **UnifiedSearcher changes**:
```ruby
# Now uses project root as default search path
options_with_path = options.dup
options_with_path[:search_path] ||= @project_root
```

2. **CLI changes**:
```ruby
# Maps search_root to search_path and handles special case
if search_options[:search_root]
  root = search_options.delete(:search_root)
  search_options[:search_path] = (root == '.') ? Dir.pwd : root
end
```

### Testing/Validation

```bash
# Test 1: Default search from subdirectory (should search project root)
cd dev-handbook/workflow-instructions
search "bin/tnid"
# Result: Found 70 results from project root ✓

# Test 2: Search from current directory with --search-root .
search "bin/tnid" --search-root .
# Result: No results (correct, as no matches in current dir) ✓

# Test 3: Search from specific path
search "bin/tnid" --search-root /Users/michalczyz/Projects/CodingAgent/handbook-meta
# Result: Found 70 results from specified path ✓
```

**Results**: All tests passed, search behavior now works as expected

## References

- Commit: `3e94438` in dev-tools submodule - "feat(search): default to project root, allow current dir"
- Related issue: Discovered during user testing of search simplification (v.0.5.0+task.006)
- Documentation: Updated help text in search command to clarify behavior
- Follow-up needed: None - issue fully resolved