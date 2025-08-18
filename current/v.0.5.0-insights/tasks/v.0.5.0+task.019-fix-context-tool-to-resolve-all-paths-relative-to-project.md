---
id: v.0.5.0+task.019
status: done
priority: high
estimate: 3h
dependencies: []
completed_at: 2025-08-18
---

# Fix context tool to resolve all paths relative to project root  

## Problem Description

The context tool currently fails when run from subdirectories because it resolves file paths and executes commands relative to the current working directory instead of the project root. This breaks the tool when invoked from anywhere except the project root.

### Current Issues

1. **Path Resolution Failures**: When running from subdirectories, file patterns fail to match
   - Example: Running from `dev-tools/`: "No files found matching pattern: docs/what-do-we-build.md"
   
2. **Command Execution Failures**: Commands that reference project paths fail
   - Example: "cd: dev-tools: No such file or directory" when not at project root

3. **Inconsistent Behavior**: Tool works from project root but fails from subdirectories

## Requirements

### 1. Project Root Detection
- [x] Use existing `ProjectRootDetector` atom to find project root during initialization
- [x] Detect root once and maintain reference throughout execution
- [x] Handle edge cases where project root cannot be detected

### 2. File Path Resolution
- [x] Resolve all file patterns relative to project root
- [x] Support both relative and absolute paths correctly
- [x] Fix glob pattern expansion to work from project root regardless of execution directory
- [x] Maintain backward compatibility with existing path specifications

### 3. Command Execution
- [x] Execute each command independently from project root directory
- [x] No state maintained between commands (each starts from clean project root context)
- [x] Support complex commands like "cd dev-tools && bundle list"
- [x] Preserve command output and error handling

### 4. Backward Compatibility
- [x] Maintain existing behavior when run from project root
- [x] No changes needed to existing context templates
- [x] Preserve all current functionality and API

## Technical Approach

### Architecture Pattern
- **Dependency Injection**: Inject project root into components that need it
- **Single Responsibility**: Each component handles its specific concern
- **Fail-Safe Design**: Graceful degradation if project root cannot be detected

### Technology Stack
- **Ruby Standard Library**: Use `File`, `Dir`, and `Pathname` for path operations
- **Open3**: For command execution with working directory support
- **Existing Atoms**: Leverage ProjectRootDetector for root detection

## File Modifications

### Files to Modify

#### `dev-tools/lib/coding_agent_tools/molecules/context/context_aggregator.rb`
- **Changes**: Add project root detection, update path resolution logic
- **Impact**: Core fix for file pattern resolution
- **Dependencies**: Will require ProjectRootDetector atom

#### `dev-tools/lib/coding_agent_tools/atoms/system_command_executor.rb`
- **Changes**: Add working_dir parameter to execute method
- **Impact**: Enables command execution from specified directory
- **Dependencies**: Uses Open3 with :chdir option

### Files to Create

#### `dev-tools/spec/integration/context_path_resolution_spec.rb`
- **Purpose**: Comprehensive integration tests for path resolution
- **Coverage**: Test from various directories, with different presets
- **Key Tests**: Subdirectory execution, path resolution, command independence

### Key Changes Needed

#### ContextAggregator Enhancement
```ruby
class ContextAggregator
  def initialize
    @project_root = ProjectRootDetector.detect_project_root
    # Use @project_root for all path operations
  end
  
  private
  
  def resolve_file_paths(patterns)
    # Resolve all patterns relative to @project_root
  end
end
```

#### SystemCommandExecutor Enhancement
```ruby
class SystemCommandExecutor
  def execute(command, working_dir: nil)
    # Execute commands from specified working directory
    # Default to project root if not specified
  end
end
```

## Testing Requirements

### Unit Tests
- [x] Test path resolution logic with various directory contexts
- [x] Test project root detection in different scenarios
- [x] Test command execution with working directory parameter
- [x] Test glob pattern expansion from different starting points

### Integration Tests
- [x] Test running context tool from project root (existing behavior)
- [x] Test running context tool from subdirectories (new behavior)
- [x] Test with various preset configurations
- [x] Test command execution independence
- [x] Test error handling when project root cannot be detected

### Test Scenarios
```ruby
describe 'Context Tool Path Resolution' do
  it 'works when run from project root' do
    # Existing behavior test
  end
  
  it 'works when run from subdirectory' do
    # New behavior test
  end
  
  it 'resolves file patterns correctly from any directory' do
    # Path resolution test
  end
  
  it 'executes commands from project root regardless of current dir' do
    # Command execution test
  end
end
```

## Bug Examples to Fix

### File Pattern Resolution
```bash
# Current behavior (fails from subdirectory):
cd dev-tools/
context --preset basic
# Error: "No files found matching pattern: docs/what-do-we-build.md"

# Expected behavior (should work):
cd dev-tools/
context --preset basic
# Success: Finds docs/what-do-we-build.md relative to project root
```

### Command Execution
```bash
# Current behavior (fails from project root when command references relative paths):
context --preset full
# Command: "cd dev-tools && bundle list"
# Error: "cd: dev-tools: No such file or directory" (when not in project root)

# Expected behavior (should work from anywhere):
cd any-directory/
context --preset full
# Success: Commands execute from project root context
```

## Acceptance Criteria

1. ✅ Context tool works identically whether run from project root or any subdirectory
2. ✅ All existing preset templates continue to work without modification
3. ✅ File patterns resolve correctly relative to project root
4. ✅ Commands execute correctly from project root context
5. ✅ Comprehensive test coverage for new behavior
6. ✅ No breaking changes to existing API or functionality
7. ✅ Clear error messages when project root cannot be detected

## Related Files

### Core Implementation
- `dev-tools/lib/coding_agent_tools/molecules/context/context_aggregator.rb`
- `dev-tools/lib/coding_agent_tools/atoms/system_command_executor.rb`
- `dev-tools/lib/coding_agent_tools/atoms/project_root_detector.rb`

### Configuration Files
- `dev-tools/presets/basic.yml`
- `dev-tools/presets/full.yml` 
- `dev-tools/presets/agents.yml`

### Test Files
- `dev-tools/spec/molecules/context/context_aggregator_spec.rb`
- `dev-tools/spec/atoms/system_command_executor_spec.rb`
- `dev-tools/spec/integration/context_tool_spec.rb`

## Implementation Plan

### Planning Steps
<!-- Research and analysis that clarify the technical approach -->

* [x] **Analyze Current Behavior**: Review how ContextAggregator currently handles paths
  > TEST: Understanding Check
  > Type: Code Review
  > Assert: Current path resolution logic is documented and understood
  > Command: bundle exec rspec spec/molecules/context/context_aggregator_spec.rb --dry-run

* [x] **Review ProjectRootDetector**: Understand the existing atom's capabilities
  > TEST: Component Validation
  > Type: Code Review
  > Assert: ProjectRootDetector correctly finds project root from any subdirectory
  > Command: ruby -e "require './lib/coding_agent_tools'; puts CodingAgentTools::Atoms::ProjectRootDetector.find_project_root"

* [x] **Design Integration Strategy**: Plan how to integrate project root detection
* [x] **Identify Test Scenarios**: Document all edge cases for testing

### Execution Steps
<!-- Concrete implementation actions that modify code -->

- [x] **Update ContextAggregator Constructor**: Add project root detection
  > TEST: Initialization Check
  > Type: Unit Test
  > Assert: ContextAggregator initializes with project root reference
  > Command: bundle exec rspec spec/molecules/context/context_aggregator_spec.rb --tag initialization

- [x] **Implement Path Resolution**: Update expand_file_pattern method
  > TEST: Path Resolution
  > Type: Unit Test
  > Assert: File patterns resolve correctly from any directory
  > Command: bundle exec rspec spec/molecules/context/context_aggregator_spec.rb --tag path_resolution

- [x] **Add Working Directory Support**: Update SystemCommandExecutor
  > TEST: Command Execution
  > Type: Unit Test
  > Assert: Commands execute with specified working directory
  > Command: bundle exec rspec spec/atoms/system_command_executor_spec.rb --tag working_dir

- [x] **Update Command Processing**: Modify process_single_command method
  > TEST: Command Independence
  > Type: Integration Test
  > Assert: Each command starts fresh from project root
  > Command: bundle exec rspec spec/molecules/context/context_aggregator_spec.rb --tag commands

- [x] **Add Automated Tests**: Create comprehensive test suite
  > TEST: Full Test Suite
  > Type: Integration Test
  > Assert: All test scenarios pass from various directories
  > Command: bundle exec rspec spec/integration/context_path_resolution_spec.rb

- [x] **Manual Testing**: Verify fix works in real usage
  > TEST: Manual Validation
  > Type: Manual Test
  > Assert: Context tool works from any project subdirectory
  > Command: cd dev-tools && exe/context --preset project --output -

## Risk Assessment

### Technical Risks
- **Risk**: Breaking existing functionality when run from project root
  - **Mitigation**: Comprehensive backward compatibility tests
  - **Monitoring**: Run existing test suite before and after changes

### Integration Risks
- **Risk**: Unexpected behavior with absolute paths in templates
  - **Mitigation**: Handle both relative and absolute paths correctly
  - **Testing**: Include absolute path scenarios in test suite

### Performance Risks
- **Risk**: Project root detection might slow down initialization
  - **Mitigation**: Cache project root detection result
  - **Monitoring**: Benchmark initialization time

## Notes

- This is a critical usability fix that affects daily development workflow
- The fix should be thoroughly tested to ensure no regressions
- Consider adding debug logging to help troubleshoot path resolution issues
- Document the change in the tool's usage documentation
- Ensure all automated tests are created as part of the implementation