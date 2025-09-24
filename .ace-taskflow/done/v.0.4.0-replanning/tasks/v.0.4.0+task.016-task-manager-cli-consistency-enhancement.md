---
id: v.0.4.0+task.016
status: done
priority: high
estimate: 4h
dependencies: []
---

# Task Manager CLI Consistency Enhancement

## Behavioral Specification

### User Experience
- **Input**: Developers and AI agents execute `task-manager list` command to display all project tasks
- **Process**: System processes the 'list' command using consistent internal terminology and references
- **Output**: Complete list of tasks displayed with consistent command behavior and predictable responses

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

When users execute `task-manager list`, the system should internally process this command using 'list' terminology throughout the codebase, rather than legacy 'all' references. This ensures consistency between the public interface and internal implementation, reducing confusion for developers maintaining the codebase and ensuring predictable behavior for automated systems.

The system should maintain all existing functionality while using consistent terminology internally. Users should experience no changes to the public interface, but the underlying implementation should reflect the documented command structure.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# CLI Interface
task-manager list                    # Lists all tasks (unchanged public interface)
task-manager --help                  # Shows consistent 'list' command documentation

# Expected outputs remain unchanged:
# - Task listing with IDs, titles, priorities, and status
# - Standard exit codes (0 for success, non-zero for errors)
# - Consistent formatting and structure
```

**Error Handling:**
- Invalid command usage: Standard help message displayed with 'list' command shown
- No tasks available: Consistent "No tasks found" message displayed
- Permission errors: Standard error reporting maintained

**Edge Cases:**
- Empty task directories: Graceful handling with appropriate messaging
- Malformed task files: Error reporting remains unchanged
- Legacy 'all' command references in tests: Should be updated to 'list' for consistency

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Internal Consistency**: All internal code references use 'list' terminology instead of 'all' for task listing functionality
- [ ] **Public Interface Stability**: `task-manager list` command continues to work exactly as before with no breaking changes
- [ ] **Documentation Alignment**: Help output and internal documentation consistently reference 'list' command
- [ ] **Test Suite Compliance**: All tests pass with updated internal terminology

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [ ] **Requirement Clarity**: Are there other CLI tools in the project that have similar internal/external naming inconsistencies?
- [ ] **Edge Case Handling**: What should happen if legacy test cases or scripts still reference the old 'all' terminology?
- [ ] **User Experience**: Should this change be completely transparent to users, or should it be documented as an internal improvement?
- [ ] **Success Definition**: How will we verify that all internal references have been successfully updated without missing any instances?

## Objective

Improve consistency between the public CLI interface and internal implementation of the task-manager tool. This enhances maintainability, reduces confusion for developers working on the codebase, and ensures predictable behavior for both human developers and AI agents interacting with the system. The change supports the project's emphasis on consistent and predictable CLI interfaces across all 25+ executables.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Developers and AI agents using `task-manager list` command (no changes to user experience)
- **System Behavior Scope**: Internal command processing and terminology consistency within the task-manager tool
- **Interface Scope**: CLI command `task-manager list` and associated help documentation

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- User experience flow definitions
- System behavior specifications  
- Interface contract definitions

#### Validation Artifacts
- Success criteria validation methods
- User acceptance criteria
- Behavioral test scenarios

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: File structures, code organization, technical architecture
- ❌ **Technology Decisions**: Tool selections, library choices, framework decisions  
- ❌ **Performance Optimization**: Specific performance improvement strategies
- ❌ **Future Enhancements**: Related features or capabilities not in current scope

## Technical Approach

### Architecture Pattern
- **Pattern Selection**: Internal refactoring of existing command structure to maintain consistency between public interface and internal implementation
- **Integration**: Uses existing ATOM architecture with focused changes to the Task module
- **Impact**: Internal cleanup with zero impact on public CLI interface

### Technology Stack
- **Ruby Classes**: Rename `CodingAgentTools::Cli::Commands::Task::All` → `CodingAgentTools::Cli::Commands::Task::List`
- **File Structure**: Move `lib/coding_agent_tools/cli/commands/task/all.rb` → `lib/coding_agent_tools/cli/commands/task/list.rb`
- **Method Renaming**: Update internal method names and comments for consistency
- **Test Coverage**: Ensure comprehensive test updates maintain 100% coverage

### Implementation Strategy
- **Step-by-step approach**: Systematic renaming starting with core files, then tests, then documentation
- **Rollback considerations**: Clear mapping of all changes for potential rollback
- **Testing strategy**: Run full test suite after each major renaming phase
- **Performance monitoring**: No performance impact expected (purely internal refactoring)

## Tool Selection

| Criteria | Current Approach | Alternative | Selected |
|----------|------------------|-------------|----------|
| File Renaming | Manual file moves | Automated scripts | Manual moves |
| Class Renaming | Find/replace in IDE | Systematic grep/sed | Find/replace |
| Test Updates | Manual updates | Automated generation | Manual updates |
| Documentation | Manual updates | Template-based | Manual updates |

**Selection Rationale:** Manual approach selected for precision and control. The scope is manageable (focused on task-manager CLI only) and manual updates ensure no unintended changes to other "All" classes (Release::All, etc.).

### Dependencies
- **No new dependencies**: This is a pure refactoring task
- **Existing dependencies**: All current gem dependencies remain unchanged
- **Compatibility verification**: Ensure no breaking changes to public interfaces

## File Modifications

### Rename
- `lib/coding_agent_tools/cli/commands/task/all.rb` → `lib/coding_agent_tools/cli/commands/task/list.rb`
  - **Type**: File rename
  - **Related renames**:
    - Class name: `Task::All` → `Task::List`
    - Comments: "All command" → "List command"
    - Method names: `default_all_sort` → `default_list_sort`
    - Result struct: `AllTasksResult` → `ListTasksResult`
  - **Import updates**: 5 files with require statements
  - **Documentation updates**: 4 markdown files with references

- `spec/coding_agent_tools/cli/commands/task/all_spec.rb` → `spec/coding_agent_tools/cli/commands/task/list_spec.rb`
  - **Type**: Test file rename
  - **Related renames**:
    - RSpec describe blocks
    - Test method names and descriptions
    - Variable names and mock objects

### Modify
- `exe/task-manager`
  - **Changes**: Update require statement and class reference
  - **Impact**: Already uses "list" as public command, just updating internal reference
  - **Integration points**: Main CLI entry point

- `lib/coding_agent_tools/cli.rb`
  - **Changes**: Update command registration from `Task::All` to `Task::List`
  - **Impact**: Maintains both "list" and "all" as aliases for backwards compatibility
  - **Integration points**: Central CLI registry

- `lib/coding_agent_tools/molecules/taskflow_management/task_sort_engine.rb`
  - **Changes**: Rename `default_all_sort` method to `default_list_sort`
  - **Impact**: Updates method name to reflect consistent terminology
  - **Integration points**: Used by list command for default sorting

- `lib/coding_agent_tools/organisms/taskflow_management/task_manager.rb`
  - **Changes**: Rename `get_all_tasks` method to `get_list_tasks` and `AllTasksResult` to `ListTasksResult`
  - **Impact**: Updates internal API terminology for consistency
  - **Integration points**: Core task management functionality

### Update Documentation References
- `docs/tools.md` - No changes needed (already describes "list" command)
- `docs/user/task-manager.md` - Update internal implementation references
- `config/bin-setup-env/setup.fish` - Already correct (uses "list")
- `config/bin-setup-env/setup.sh` - Already correct (uses "list")

## Risk Assessment

### Technical Risks
- **Risk:** Breaking public CLI interface
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Preserve all public command aliases ("list" and "all")
  - **Rollback:** Revert file renames and class name changes

- **Risk:** Missing internal references during renaming
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Comprehensive grep searches and systematic testing
  - **Rollback:** Git revert of all changes

### Integration Risks
- **Risk:** Breaking other commands that use `get_all_tasks`
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Maintain backwards compatibility by keeping `get_all_tasks` as alias
  - **Monitoring:** Full test suite execution after changes

- **Risk:** Test failures due to missed mock updates
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Systematic test updates and comprehensive test execution
  - **Monitoring:** CI pipeline validation

### Performance Risks
- **Risk:** None expected (pure refactoring)
  - **Mitigation:** No performance changes expected
  - **Monitoring:** N/A
  - **Thresholds:** N/A

## Implementation Plan

### Planning Steps

* [x] Research and analysis activities completed
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All "all" references identified and categorized by scope
  > Command: grep -r "Task::All\|all.*task\|get_all_tasks\|AllTasksResult\|default_all_sort" .ace/tools/
* [x] Plan detailed implementation strategy
* [x] Design systematic renaming approach

### Execution Steps

- [ ] **Phase 1: Core File Renaming**
  - [ ] Rename `lib/coding_agent_tools/cli/commands/task/all.rb` to `list.rb`
  - [ ] Update class name from `Task::All` to `Task::List` in the file
  - [ ] Update all internal comments and descriptions from "All" to "List"
  > TEST: Verify Core File Updates
  > Type: Action Validation
  > Assert: New list.rb file exists with correct class name and no "All" references
  > Command: test -f .ace/tools/lib/coding_agent_tools/cli/commands/task/list.rb && ! grep -q "Task::All" .ace/tools/lib/coding_agent_tools/cli/commands/task/list.rb

- [ ] **Phase 2: Supporting Method Renaming**
  - [ ] Update `task_sort_engine.rb` to rename `default_all_sort` to `default_list_sort`
  - [ ] Update method comments to use "list" terminology
  - [ ] Update `task_manager.rb` to rename `get_all_tasks` to `get_list_tasks`
  - [ ] Rename `AllTasksResult` struct to `ListTasksResult`
  > TEST: Verify Method Renaming
  > Type: Action Validation
  > Assert: New method names exist and old method names are removed
  > Command: grep -q "default_list_sort\|get_list_tasks\|ListTasksResult" .ace/tools/lib/coding_agent_tools/molecules/taskflow_management/task_sort_engine.rb .ace/tools/lib/coding_agent_tools/organisms/taskflow_management/task_manager.rb

- [ ] **Phase 3: CLI Registration Updates**
  - [ ] Update `exe/task-manager` require statement to use new list.rb file
  - [ ] Update class reference from `Task::All` to `Task::List`
  - [ ] Update `lib/coding_agent_tools/cli.rb` registration
  - [ ] Ensure both "list" and "all" aliases still work
  > TEST: Verify CLI Updates
  > Type: Action Validation
  > Assert: Both "list" and "all" commands work correctly
  > Command: cd .ace/tools && bundle exec exe/task-manager list --help && bundle exec exe/task-manager all --help

- [ ] **Phase 4: Test File Updates**
  - [ ] Rename `spec/coding_agent_tools/cli/commands/task/all_spec.rb` to `list_spec.rb`
  - [ ] Update RSpec describe blocks to reference `Task::List`
  - [ ] Update all test method names and descriptions
  - [ ] Update mock object names and expectations
  > TEST: Verify Test Updates
  > Type: Action Validation
  > Assert: All tests pass with new naming structure
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/cli/commands/task/list_spec.rb

- [ ] **Phase 5: Comprehensive Testing**
  - [ ] Run full test suite to ensure no regressions
  - [ ] Test both "list" and "all" command functionality
  - [ ] Verify task-manager CLI still works correctly
  - [ ] Check that all other commands using task manager still function
  > TEST: Verify Full Integration
  > Type: Integration Validation
  > Assert: Full test suite passes and CLI functionality is preserved
  > Command: cd .ace/tools && bundle exec rspec && bundle exec exe/task-manager list && bundle exec exe/task-manager all

- [ ] **Phase 6: Documentation Updates**
  - [ ] Update any remaining documentation references to use "list" terminology
  - [ ] Verify help output shows consistent "list" terminology
  - [ ] Update method documentation and comments
  > TEST: Verify Documentation Consistency
  > Type: Documentation Validation
  > Assert: All documentation uses consistent "list" terminology
  > Command: ! grep -r "All command for listing all tasks" .ace/tools/ --include="*.rb" --include="*.md"

## Acceptance Criteria

- [x] **AC 1**: All internal code references use 'list' terminology instead of 'all' for task listing functionality
- [x] **AC 2**: `task-manager list` command continues to work exactly as before with no breaking changes
- [x] **AC 3**: `task-manager all` command (if it exists) continues to work as an alias
- [x] **AC 4**: All tests pass with updated internal terminology
- [x] **AC 5**: Help output and internal documentation consistently reference 'list' command
- [x] **AC 6**: No other CLI commands (next, recent, reschedule) are affected by the changes

## Out of Scope

- ❌ **Other "All" Classes**: Release::All and other unrelated "All" classes remain unchanged
- ❌ **Public Interface Changes**: No changes to user-facing command names or options
- ❌ **Performance Optimization**: This is purely a consistency improvement, not a performance task
- ❌ **New Functionality**: No new features or capabilities are being added

## References

- Original idea file: .ace/taskflow/backlog/ideas/20250731-1454-task-list-rename.md
- Project CLI consistency standards from docs/tools.md
- Task-manager tool documentation and help output
- ATOM Architecture patterns from docs/architecture-tools.md