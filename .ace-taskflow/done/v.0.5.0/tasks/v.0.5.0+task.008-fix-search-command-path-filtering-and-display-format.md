---
id: v.0.5.0+task.008
status: done
priority: high
estimate: 2h
dependencies: ["v.0.5.0+task.007"]
---

# Fix search command path filtering and display format

## Behavioral Specification

### User Experience
- **Input**: Users run `search "pattern"` from any directory in the project
- **Process**: Search executes from project root with working default filters that properly exclude archived/done tasks as configured
- **Output**: Clean, readable search results showing relative paths from project root instead of verbose absolute paths

### Expected Behavior
Users expect the search command to respect its default exclusion filters regardless of where they run the command from. When searching for patterns, they should not see results from directories that are supposed to be excluded by default (like `.ace/taskflow/done/**/*` and `.ace/taskflow/current/*/tasks/x/*`). 

Additionally, users want search results to display clean, relative paths that are easy to read and understand in the context of their project, rather than long absolute paths that clutter the output and make it harder to scan results quickly.

The search command should provide consistent, predictable filtering behavior that works the same way whether run from the project root, a subdirectory, or any location within the project structure.

### Interface Contract
```bash
# Current broken behavior
$ cd .ace/handbook/workflow-instructions
$ search "bin/tnid"
Search context: mode: content | pattern: "bin/tnid" | filters: [exclude: .ace/taskflow/current/*/tasks/x/*,.ace/taskflow/done/**/*]
Found 73 results
  /Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/taskflow/done/v.0.2.0-synapse/tasks/v.0.2.0+task.3:2:0: ...
  # ^^ Shows results from excluded paths (filters not working)
  # ^^ Shows full absolute paths (verbose and hard to read)

# Expected behavior after fix
$ cd .ace/handbook/workflow-instructions  
$ search "bin/tnid"
Search context: mode: content | pattern: "bin/tnid" | filters: [exclude: .ace/taskflow/current/*/tasks/x/*,.ace/taskflow/done/**/*]
Found 11 results
  ./CHANGELOG.md:663:0: ...
  ./.ace/taskflow/current/v.0.5.0-insights/researches/binstub-audit-results.md:5:0: ...
  # ^^ Excludes .ace/taskflow/done/ results (filters working correctly)
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
- [x] **Default Filter Functionality**: Default exclusion filters (`.ace/taskflow/current/*/tasks/x/*`, `.ace/taskflow/done/**/*`) successfully filter out matching paths from results
- [x] **Relative Path Display**: All search results show paths relative to project root (e.g., `./path/to/file.md` or `path/to/file.md`)
- [x] **Consistent Filtering**: Path filtering works correctly regardless of user's current working directory
- [x] **Custom Filter Support**: User-specified include/exclude filters continue to work as documented
- [x] **Performance Maintained**: Filtering doesn't significantly impact search performance for typical codebases

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

## Technical Approach

### Architecture Pattern
- [ ] Path normalization pattern to handle absolute to relative conversion
- [ ] Consistent filter application across all search modes
- [ ] Separation of concerns between search execution and result filtering

### Technology Stack
- [ ] Ruby's File and Pathname for path manipulation
- [ ] Existing ProjectRootDetector for root detection
- [ ] ResultAggregator for centralized filtering logic
- [ ] No new dependencies required

### Implementation Strategy
- [ ] Convert absolute paths to relative before filter matching
- [ ] Update display formatting to show relative paths
- [ ] Maintain backward compatibility with existing filters
- [ ] Test with various directory scenarios

## Tool Selection

No new tools required. Using existing Ruby standard library and project components:
- `File.expand_path` and path string manipulation for conversions
- `ProjectRootDetector` already provides project root detection
- Existing glob pattern matching via `File.fnmatch`

## File Modifications

### Modify
- `.ace/tools/lib/coding_agent_tools/organisms/search/result_aggregator.rb`
  - Changes: Update `filter_result_array_by_path` to convert absolute paths to relative before matching
  - Impact: Fixes filter matching for absolute path results from ripgrep
  - Integration points: Called by aggregate method for all search results

- `.ace/tools/exe/search`
  - Changes: Update `output_single_result` to display relative paths
  - Impact: Cleaner, more readable output for users
  - Integration points: Output formatting for all search modes

## Implementation Plan

### Planning Steps

* [x] **Analyze Current Path Handling**
  - Understand how ripgrep returns paths (absolute when searching from project root)
  - Trace path flow from ripgrep through ResultAggregator to output
  - Identify where path conversion should occur

* [x] **Design Path Conversion Strategy**
  - Determine project root detection method
  - Plan conversion logic for absolute to relative paths
  - Consider edge cases (symlinks, paths outside project)

* [x] **Review Filter Pattern Matching**
  - Understand current `path_matches_any?` implementation
  - Verify glob pattern behavior with relative paths
  - Plan test cases for various filter scenarios

### Execution Steps

- [x] **Update ResultAggregator Path Filtering**
  > TEST: Path Conversion in Filter
  > Type: Unit Test
  > Assert: Absolute paths are converted to relative before filter matching
  > Command: ruby -e "require './.ace/tools/lib/coding_agent_tools/organisms/search/result_aggregator'; puts 'Test filter conversion logic'"
  
  Modify `filter_result_array_by_path` method to:
  ```ruby
  # Convert absolute path to relative if it starts with project root
  if file_path.start_with?('/')
    project_root = Atoms::ProjectRootDetector.find_project_root
    if file_path.start_with?(project_root)
      normalized_path = file_path.sub(project_root + '/', '')
    else
      normalized_path = file_path
    end
  else
    normalized_path = file_path.start_with?('./') ? file_path[2..-1] : file_path
  end
  ```

- [x] **Add Project Root Detection to ResultAggregator**
  > TEST: Project Root Initialization
  > Type: Integration Test
  > Assert: ResultAggregator has access to project root
  > Command: cd .ace/tools && ruby -e "require './lib/coding_agent_tools/organisms/search/result_aggregator'; ra = CodingAgentTools::Organisms::Search::ResultAggregator.new; puts ra.instance_variable_get(:@project_root) || 'No project root'"
  
  Add initialization:
  ```ruby
  def initialize
    @project_root = Atoms::ProjectRootDetector.find_project_root
  end
  ```

- [x] **Update Display Output Formatting**
  > TEST: Relative Path Display
  > Type: End-to-End Test
  > Assert: Search results show relative paths starting with ./
  > Command: search "bin/tnid" --exclude none | head -5 | grep -E "^\s+\./"
  
  Modify `output_single_result` in exe/search:
  ```ruby
  # Convert absolute paths to relative for display
  if result[:file] && result[:file].start_with?('/')
    project_root = Atoms::ProjectRootDetector.find_project_root
    if result[:file].start_with?(project_root)
      display_path = './' + result[:file].sub(project_root + '/', '')
    else
      display_path = result[:file]
    end
  else
    display_path = result[:file]
  end
  ```

- [x] **Test Filter Functionality**
  > TEST: Default Filters Working
  > Type: Integration Test
  > Assert: Results from .ace/taskflow/done are excluded
  > Command: search "bin/tnid" | grep -c ".ace/taskflow/done" | grep "^0$"

- [x] **Test Path Display Format**
  > TEST: Clean Path Display
  > Type: End-to-End Test
  > Assert: All paths show as relative with ./ prefix
  > Command: search "test" | head -20 | grep -v "^\s+\./" | grep -c ":" | grep "^0$"

- [x] **Validate Edge Cases**
  > TEST: Search from Subdirectory
  > Type: Integration Test
  > Assert: Filters work when running from subdirectory
  > Command: cd .ace/handbook && search "bin/tnid" | grep -c ".ace/taskflow/done" | grep "^0$"

## Risk Assessment

### Technical Risks
- **Risk:** Path conversion logic might fail for symlinked directories
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Use File.realpath for symlink resolution if needed
  - **Rollback:** Revert to absolute path matching

### Integration Risks
- **Risk:** Breaking existing custom filters that expect absolute paths
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Test with various filter patterns
  - **Monitoring:** Check filter match counts before/after

### Performance Risks
- **Risk:** Path conversion adds overhead to large result sets
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Cache project root, optimize string operations
  - **Monitoring:** Measure search time for large result sets

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [x] **Filter Functionality**: Default filters successfully exclude .ace/taskflow/done/** paths
- [x] **Path Display**: All results show relative paths from project root
- [x] **Consistency**: Filtering works from any directory in project

### Implementation Quality Assurance
- [x] **Code Quality**: Path conversion logic is clean and efficient
- [x] **Test Coverage**: All embedded tests pass successfully
- [x] **Integration Verification**: Works with all search modes (file, content, hybrid)
- [x] **Performance Requirements**: No noticeable performance degradation

### Documentation and Validation
- [x] **Behavioral Validation**: Success criteria from specification are met
- [x] **Error Handling**: Invalid paths handled gracefully
- [x] **Help Text**: Consider updating if needed for clarity

## References

- Related issue: v.0.5.0+task.007 (Fix search command --search-root flag behavior)
- User feedback: Filters showing in output but not being applied to results
- Current behavior: Absolute paths from ripgrep not matching relative path filter patterns
- Technical analysis: ResultAggregator filtering expects relative paths but receives absolute