---
id: v.0.5.0+task.008
status: draft
priority: high
estimate: TBD
dependencies: ["v.0.5.0+task.007"]
---

# Fix search command path filtering and display format

## Behavioral Specification

### User Experience
- **Input**: Users run `search "pattern"` from any directory in the project
- **Process**: Search executes from project root with working default filters that properly exclude archived/done tasks as configured
- **Output**: Clean, readable search results showing relative paths from project root instead of verbose absolute paths

### Expected Behavior
Users expect the search command to respect its default exclusion filters regardless of where they run the command from. When searching for patterns, they should not see results from directories that are supposed to be excluded by default (like `dev-taskflow/done/**/*` and `dev-taskflow/current/*/tasks/x/*`). 

Additionally, users want search results to display clean, relative paths that are easy to read and understand in the context of their project, rather than long absolute paths that clutter the output and make it harder to scan results quickly.

The search command should provide consistent, predictable filtering behavior that works the same way whether run from the project root, a subdirectory, or any location within the project structure.

### Interface Contract
```bash
# Current broken behavior
$ cd dev-handbook/workflow-instructions
$ search "bin/tnid"
Search context: mode: content | pattern: "bin/tnid" | filters: [exclude: dev-taskflow/current/*/tasks/x/*,dev-taskflow/done/**/*]
Found 73 results
  /Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-taskflow/done/v.0.2.0-synapse/tasks/v.0.2.0+task.3:2:0: ...
  # ^^ Shows results from excluded paths (filters not working)
  # ^^ Shows full absolute paths (verbose and hard to read)

# Expected behavior after fix
$ cd dev-handbook/workflow-instructions  
$ search "bin/tnid"
Search context: mode: content | pattern: "bin/tnid" | filters: [exclude: dev-taskflow/current/*/tasks/x/*,dev-taskflow/done/**/*]
Found 11 results
  ./CHANGELOG.md:663:0: ...
  ./dev-taskflow/current/v.0.5.0-insights/researches/binstub-audit-results.md:5:0: ...
  # ^^ Excludes dev-taskflow/done/ results (filters working correctly)
  # ^^ Shows relative paths from project root (clean and readable)

# Filter control interface remains unchanged
$ search "pattern" --exclude none           # Disables all filters, shows everything
$ search "pattern" --exclude "custom/path"  # Adds custom exclusions to defaults
$ search "pattern" --include "specific/**"  # Limits search to specific paths
```

**Error Handling:**
- Invalid filter patterns: Display clear error message explaining the issue
- No matches after filtering: Show "No results found" with active filters listed
- Conflicting include/exclude: Include filters take precedence

**Edge Cases:**
- Searching from outside project: Should still detect project root correctly
- Symlinked directories: Filters should work on resolved paths
- Case sensitivity in filters: Should follow platform conventions

### Success Criteria
- [ ] **Default Filter Functionality**: Default exclusion filters (`dev-taskflow/current/*/tasks/x/*`, `dev-taskflow/done/**/*`) successfully filter out matching paths from results
- [ ] **Relative Path Display**: All search results show paths relative to project root (e.g., `./path/to/file.md` or `path/to/file.md`)
- [ ] **Consistent Filtering**: Path filtering works correctly regardless of user's current working directory
- [ ] **Custom Filter Support**: User-specified include/exclude filters continue to work as documented
- [ ] **Performance Maintained**: Filtering doesn't significantly impact search performance for typical codebases

### Validation Questions
- [ ] **Path Display Format**: Should relative paths be shown with `./` prefix or without any prefix?
- [ ] **Performance Optimization**: Should we implement ripgrep-level filtering (--glob) for better performance in large codebases?
- [ ] **Help Text Updates**: Do we need to update the --help text to clarify how filtering works with absolute vs relative paths?
- [ ] **Filter Syntax**: Should we support more advanced filter patterns beyond glob patterns?

## Objective

Fix the search command so that default exclusion filters work correctly when searching from any directory, and improve the user experience by displaying clean relative paths instead of verbose absolute paths.

## Scope of Work

- **User Experience Scope**: Search result filtering and display formatting from user's perspective
- **System Behavior Scope**: Correct application of include/exclude filters regardless of search location
- **Interface Scope**: Maintaining existing CLI interface while fixing underlying behavior

### Deliverables

#### Behavioral Specifications
- Clear definition of how filters should behave with project-root-based searching
- Specification of relative path display format for results
- Examples of expected behavior in various scenarios

#### Validation Artifacts
- Test cases for filter behavior from different directories
- Examples showing before/after output format
- Success criteria validation checklist

## Out of Scope

- ❌ **Implementation Details**: Specific code changes to ResultAggregator or path conversion logic
- ❌ **Technology Decisions**: Whether to use Ruby's pathname library or string manipulation
- ❌ **Performance Optimization**: Specific strategies for improving filter performance
- ❌ **Future Enhancements**: Additional filter types or search modes not currently supported

## References

- Related issue: v.0.5.0+task.007 (Fix search command --search-root flag behavior)
- User feedback: Filters showing in output but not being applied to results
- Current behavior: Absolute paths from ripgrep not matching relative path filter patterns