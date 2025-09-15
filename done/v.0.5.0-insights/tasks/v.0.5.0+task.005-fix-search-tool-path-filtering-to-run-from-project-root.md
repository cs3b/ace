---
id: v.0.5.0+task.005
title: Fix search tool path filtering to run from project root
status: done
priority: high
estimate: 1h
actual: 1h
dependencies: [v.0.5.0+task.004]
---

# Fix search tool path filtering to run from project root

## Behavioral Context

**Issue**: The search tool's --exclude filter wasn't working correctly. When searching with patterns like `--exclude ".ace/taskflow/done/**/*"`, results from those directories were still appearing because searches were being executed from within each repository's directory rather than from the project root.

**Key Behavioral Requirements**:
- Search tool must execute from project root by default
- Path filters must work consistently across all submodules
- Exclude patterns must match actual file paths in results
- Users should be able to override the search root if needed

## Objective

Fix the search tool to execute searches from the project root directory, enabling proper path filtering across all repositories and submodules.

## Scope of Work

- Modified search execution to run from project root
- Added --search-root option for custom search roots
- Fixed path handling in executors and aggregator
- Updated ripgrep and fd to use correct search paths
- Fixed result path normalization

### Deliverables

#### Modify
- `lib/coding_agent_tools/organisms/search/unified_searcher.rb` - Changed to execute from project root
- `lib/coding_agent_tools/atoms/search/ripgrep_executor.rb` - Added search_path support
- `lib/coding_agent_tools/atoms/search/fd_executor.rb` - Added search_path support
- `lib/coding_agent_tools/organisms/search/result_aggregator.rb` - Fixed path normalization
- `exe/search` - Added --search-root option

## Implementation Summary

### What Was Done

- **Problem Identification**: User reported that `--exclude ".ace/taskflow/done/**/*"` wasn't filtering results
- **Investigation**: Found that searches were executed using `Dir.chdir(repo[:path])` which changed to each repository directory
- **Solution**: 
  - Modified `search_single_repository` to execute from project root
  - Set `search_path` option for each repository (main = ".", submodules = relative path)
  - Updated executors to use `search_path` when provided
  - Fixed result aggregator to handle project-root-relative paths
- **Validation**: Tested with various exclude patterns to confirm filtering works

### Technical Details

Key changes in `unified_searcher.rb`:
```ruby
# Before: Changed to each repo directory
Dir.chdir(repo[:path]) do
  # search...
end

# After: Search from project root with path option
search_root = options[:search_root] || @coordinator.instance_variable_get(:@project_root) || Dir.pwd
repo_options[:search_path] = (repo[:name] == 'main') ? '.' : repo[:path]
Dir.chdir(search_root) do
  # search...
end
```

Path filtering in `result_aggregator.rb`:
```ruby
# Before: Tried to prepend repo_path
full_path = File.join(repo_path, file_path)

# After: Paths already relative to project root
normalized_path = file_path.start_with?('./') ? file_path[2..-1] : file_path
```

### Testing/Validation

```bash
# Test exclude filter works
./.ace/tools/exe/search "task.64" --content --exclude ".ace/taskflow/done/**/*"
# Result: No results (correctly filtered)

# Test without exclude to verify results exist
./.ace/tools/exe/search "task.64" --content --exclude none
# Result: Found 2 results in .ace/taskflow/done/

# Test original user case
./.ace/tools/exe/search "bin/tn" --exclude ".ace/taskflow/done/**/*,dev-taskflow/current/*/tasks/*"
# Result: Correctly excludes specified paths
```

**Results**: Path filtering now works correctly. Searches execute from project root and exclude patterns match the actual file paths.

## References

- Commits: 
  - `52de0af fix(search): run searches from project root with proper path filtering`
  - `b379425 chore: update .ace/tools submodule with search path filtering fix`
- Related issues: User-reported issue with --exclude not working
- Follow-up needed: None - fix is complete and validated