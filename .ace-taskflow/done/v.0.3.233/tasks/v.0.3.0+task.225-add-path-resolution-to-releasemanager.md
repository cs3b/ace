---
id: v.0.3.0+task.225
status: done
priority: high
estimate: 6h
dependencies: []
---

# Add Path Resolution to ReleaseManager

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/lib/coding_agent_tools/organisms/taskflow_management | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools/lib/coding_agent_tools/organisms/taskflow_management
    ├── release_manager.rb
    └── task_manager.rb
```

## Objective

Enable ReleaseManager to resolve subdirectory paths within the current release, providing a centralized way to get paths like `reflections/`, `reflections/synthesis/`, and `tasks/`. This will standardize path resolution across tools and eliminate hardcoded path logic.

## Scope of Work

- Add `resolve_path(subpath)` method to ReleaseManager class
- Support path resolution for common subdirectories (reflections, tasks, etc.)
- Create directories if they don't exist (with optional flag)
- Return full absolute paths within the current release
- Handle error cases when no current release exists

### Deliverables

#### Create

- None (method addition to existing class)

#### Modify

- .ace/tools/lib/coding_agent_tools/organisms/taskflow_management/release_manager.rb

#### Delete

- None

## Phases

1. Analyze current ReleaseManager implementation
2. Design resolve_path method signature and behavior
3. Implement path resolution logic
4. Add directory creation capability
5. Handle error scenarios
2. Extract …
3. Refactor …

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [x] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: bin/test --check-analysis-complete
- [x] Research best practices and design approach
- [x] Plan detailed implementation strategy

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [x] Add resolve_path method to ReleaseManager class with basic signature and validation
  > TEST: Method exists with proper signature
  > Type: Action Validation
  > Assert: resolve_path method exists and accepts subpath parameter
  > Command: cd .ace/tools && bundle exec ruby -e "require_relative 'lib/coding_agent_tools'; puts CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.instance_methods.include?(:resolve_path)"
- [x] Implement core path resolution logic using existing directory navigator atoms
  > TEST: Path resolution works for basic subdirectories
  > Type: Action Validation
  > Assert: Method returns correct absolute paths for common subdirectories
  > Command: cd .ace/tools && bundle exec ruby -e "require_relative 'lib/coding_agent_tools'; rm = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new; puts rm.resolve_path('tasks').class == String rescue puts 'false'"
- [x] Add directory creation capability with optional create_if_missing flag
  > TEST: Directory creation works when flag is true
  > Type: Action Validation
  > Assert: Method creates directories when create_if_missing is true
  > Command: cd .ace/tools && bundle exec ruby -e "require_relative 'lib/coding_agent_tools'; rm = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new; result = rm.resolve_path('test-subdir', create_if_missing: true); puts File.directory?(result) rescue puts 'false'"
- [x] Implement error handling for cases when no current release exists
  > TEST: Error handling works correctly
  > Type: Action Validation
  > Assert: Method raises appropriate error when no current release exists
  > Command: cd .ace/tools && bundle exec ruby -e "require_relative 'lib/coding_agent_tools'; rm = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: '/tmp/non-existent'); begin; rm.resolve_path('tasks'); puts 'false'; rescue => e; puts e.message.include?('release'); end"

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [x] AC 1: ReleaseManager class has resolve_path method that accepts subpath and optional create_if_missing flag
- [x] AC 2: Method returns absolute paths within current release for common subdirectories (reflections, tasks, etc.)
- [x] AC 3: Method creates directories when create_if_missing flag is true
- [x] AC 4: Method handles error cases appropriately when no current release exists
- [x] AC 5: All embedded tests in the Implementation Plan pass

## Out of Scope

- ❌ Integration with nav-path or create-path tools
- ❌ Modifying existing ReleaseManager methods
- ❌ Adding CLI commands (separate task)
- ❌ Updating other tools to use this method

## References

- Current ReleaseManager: .ace/tools/lib/coding_agent_tools/organisms/taskflow_management/release_manager.rb
- Example usage pattern: resolve_path("reflections/synthesis") → "/path/to/current/release/reflections/synthesis"
- Related task: Enhance release-manager CLI with --path Option
