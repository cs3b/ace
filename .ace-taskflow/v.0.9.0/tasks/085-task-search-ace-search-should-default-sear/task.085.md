---
id: v.0.9.0+task.085
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# ace-search should default to searching entire project from root

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-search "pattern"` from any directory within the project (including deeply nested subdirectories)
- **Process**: Tool detects project root using `PROJECT_ROOT_PATH` env var or markers (.git, Gemfile, etc.), executes search from project root
- **Output**: Search results from entire project, not just current directory and below

**Current Problem**: When running `ace-search "pattern"` from a subdirectory (e.g., `project/deep/nested/dir`), search only covers files from current directory downward, missing files in parent directories or sibling branches of the project tree.

**Desired Experience**: Regardless of current working directory within a project, `ace-search "pattern"` searches the entire project from its root directory.

### Expected Behavior

Users should be able to search the entire project by default, with the ability to scope searches when needed:

```bash
# Default: search entire project from root (NEW BEHAVIOR)
ace-search "test"                    # Searches from $PROJECT_ROOT_PATH

# Override with second positional argument
ace-search "test" ./                 # Current directory only
ace-search "test" ./**/*.md          # All .md files in current dir tree
ace-search "test" src/               # Search only src/ directory
ace-search "test" ../other-project/  # Search different directory tree

# Existing flags work relative to search directory
ace-search "test" --glob "**/*.rb"   # Glob relative to project root (default)
ace-search "test" ./ --glob "*.rb"   # Glob relative to current dir
ace-search "test" --include lib/,src/     # Include paths relative to search root
ace-search "test" --exclude test/,docs/   # Exclude paths relative to search root
```

The search path resolution:
1. If second positional argument provided → use as search path
2. Else if `PROJECT_ROOT_PATH` env var set → use that path
3. Else use `Ace::Core::Molecules::ProjectRootFinder` to detect root
4. Else fall back to current directory (`.`)

### Interface Contract

**CLI Syntax:**
```bash
ace-search [options] PATTERN [SEARCH_PATH]
```

**Arguments:**
- `PATTERN` (required): Search pattern or query string
- `SEARCH_PATH` (optional): Directory or glob pattern to search within
  - Relative paths resolved from current directory
  - Absolute paths used as-is
  - Defaults to project root if not provided

**Key Flags Behavior:**
- `--glob PATTERN`: File patterns relative to `SEARCH_PATH`
- `--include PATHS`: Paths to include, relative to `SEARCH_PATH`
- `--exclude PATHS`: Paths to exclude, relative to `SEARCH_PATH`
- All other existing flags (`--type`, `--case-insensitive`, `--context`, etc.) work unchanged

**Normal Operation:**
```bash
# From any directory in project:
$ cd /project/deep/nested/dir
$ ace-search "TODO"
# Searches /project/** (entire project)

# With explicit path:
$ ace-search "TODO" ./
# Searches /project/deep/nested/dir/** (current dir only)

# With include/exclude:
$ ace-search "config" --include "src/,lib/" --exclude "test/"
# Searches /project/src/** and /project/lib/**, excluding /project/test/**
```

**Error Handling:**
- **Non-existent search path**: `Error: Search path '/path' does not exist`
- **No project root found**: Fall back to current directory, optionally show warning
- **Invalid glob pattern**: `Error: Invalid glob pattern: 'pattern'`
- **No read permission**: `Error: Permission denied: '/path'`

**Edge Cases:**
- **Search path is a file**: Should search work on single file, or require directory?
- **Search path contains spaces**: Should be properly quoted/escaped
- **Search path is symlink**: Should resolve symlinks or search symlink target?
- **Multiple path arguments**: Should reject with error or treat as multiple searches?

### Success Criteria

- [ ] **Default Project Root Search**: When run from any subdirectory without `SEARCH_PATH` argument, searches from project root
- [ ] **Project Root Detection**: Uses `Ace::Core::Molecules::ProjectRootFinder` to locate root via markers (.git, Gemfile, etc.)
- [ ] **ENV Variable Support**: Respects `PROJECT_ROOT_PATH` environment variable when set
- [ ] **Optional Path Override**: Second positional argument overrides default search location
- [ ] **Relative Path Handling**: Include/exclude/glob patterns relative to the search directory
- [ ] **Backward Compatibility**: All existing flags and options continue to work
- [ ] **Graceful Fallback**: Falls back to current directory when no project root detected
- [ ] **Error Messages**: Clear error messages for invalid paths or patterns

### Validation Questions

- [ ] **Relative vs Absolute Paths**: How should relative paths in `SEARCH_PATH` be resolved? From current directory or from project root?
  - **Recommendation**: From current directory (standard Unix behavior)

- [ ] **Path Validation**: Should we validate that `SEARCH_PATH` exists before executing search?
  - **Current**: ripgrep/fd handle non-existent paths with their own errors
  - **Question**: Add explicit validation for better error messages?

- [ ] **Single File Search**: Should `SEARCH_PATH` accept a single file path, or require directories?
  - **Current**: ripgrep supports file paths
  - **Question**: Should we preserve this or limit to directories?

- [ ] **Symlink Resolution**: When `SEARCH_PATH` is a symlink, should we resolve it or search the link target?
  - **Current**: Likely follows symlinks (ripgrep default)
  - **Question**: Should this be configurable?

- [ ] **Flag Separator**: Should we support `--` to separate flags from positional arguments?
  - **Use case**: `ace-search "pattern" -- ./--weird-dirname`
  - **Question**: Is this needed or edge case enough to skip?

- [ ] **Configuration File**: Should default search path be configurable in `.ace/search/config.yml`?
  - **Potential**: `default_search_path: project_root | current_dir | custom_path`
  - **Question**: Is this needed or would ENV variable be sufficient?

## Objective

Enable developers to search entire projects regardless of their current working directory, while maintaining the ability to scope searches when needed. This improves the developer experience by making `ace-search` behave consistently and predictably across the entire project.

**User Value**:
- Eliminates the need to `cd` to project root before searching
- Reduces false negatives when searching from subdirectories
- Maintains consistency with other project-aware tools
- Preserves flexibility for scoped searches

## Scope of Work

### User Experience Scope
- Command-line interface for search path specification
- Project root detection and resolution
- Search path validation and error handling
- Relative path resolution for patterns and filters

### System Behavior Scope
- Integration with `Ace::Core::Molecules::ProjectRootFinder`
- Search path determination logic (priority: explicit → env → detected → fallback)
- Path resolution for include/exclude/glob patterns
- Error handling for invalid paths and patterns

### Interface Scope
- Optional second positional argument (`SEARCH_PATH`)
- Existing flags: `--glob`, `--include`, `--exclude` (behavior relative to search path)
- Environment variable: `PROJECT_ROOT_PATH`
- Error messages and validation feedback

### Deliverables

#### Behavioral Specifications
- CLI syntax with optional `SEARCH_PATH` argument
- Search path resolution algorithm (4-step priority)
- Relative path behavior for patterns and filters
- Error handling scenarios and messages

#### Validation Artifacts
- Test scenarios covering all search path combinations
- Edge case handling (symlinks, spaces, special characters)
- Backward compatibility verification
- User acceptance criteria for project root detection

## Out of Scope

- ❌ **Implementation Details**: File structure changes, code organization, specific classes or modules
- ❌ **Performance Optimization**: Caching strategies, indexing, search performance improvements
- ❌ **Advanced Path Features**: Regex paths, multiple simultaneous search paths, path templates
- ❌ **UI Changes**: Output formatting changes, progress indicators, interactive features
- ❌ **Configuration Complexity**: Advanced config file options beyond simple defaults
- ❌ **Cross-Project Search**: Searching multiple projects simultaneously

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251013-162828-ace-search-do-not-search-in-whole-project-by-defau.md`
- Existing tool: `Ace::Core::Molecules::ProjectRootFinder` at `ace-core/lib/ace/core/molecules/project_root_finder.rb`
- Current implementation: `ace-search/lib/ace/search/atoms/ripgrep_executor.rb:112-118` (defaults to `["."]`)
- CLI entry point: `ace-search/exe/ace-search`
