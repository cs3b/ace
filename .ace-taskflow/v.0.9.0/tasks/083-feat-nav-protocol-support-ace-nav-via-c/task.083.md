---
id: v.0.9.0+task.083
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Add task:// Protocol Support to ace-nav via Command Delegation

## Behavioral Specification

### User Experience
- **Input**: `ace-nav task://[task-ref]` with any valid task reference format (018, task.018, v.0.9.0+task.018)
- **Process**: Seamless navigation to task resources through unified ace-nav interface that delegates to ace-taskflow
- **Output**: Task information displayed (path, content, tree) matching ace-taskflow task command output

### Expected Behavior

Users should be able to navigate to tasks using the task:// protocol through ace-nav, providing a unified interface for all resource navigation. The protocol delegates to the underlying ace-taskflow task command, preserving all functionality while maintaining consistency with other ace-nav protocols (wfi://, guide://, tmpl://).

This creates a single entry point for developers: ace-nav handles all resource types including tasks, workflows, guides, and templates. The command delegation pattern ensures ace-nav doesn't duplicate ace-taskflow's task management logic, instead acting as a smart router.

### Interface Contract

```bash
# Core Task Navigation (v1 - Single Task Lookup)
ace-nav task://018                     # Delegates to: ace-taskflow task 018
ace-nav task://task.018                # Delegates to: ace-taskflow task task.018
ace-nav task://v.0.9.0+task.018        # Delegates to: ace-taskflow task v.0.9.0+task.018
ace-nav task://backlog+025             # Delegates to: ace-taskflow task backlog+025

# Display Options (pass-through to ace-taskflow)
ace-nav task://018 --path              # Delegates to: ace-taskflow task 018 --path
ace-nav task://018 --content           # Delegates to: ace-taskflow task 018 --content
ace-nav task://018 --tree              # Delegates to: ace-taskflow task 018 --tree

# Expected Output
# Returns whatever ace-taskflow task would return
# Exit codes match ace-taskflow behavior (0 for success, 1 for errors)
```

**Error Handling:**
- Task not found: Delegates to ace-taskflow which returns appropriate error message
- Invalid reference format: Delegates to ace-taskflow for validation and error reporting
- ace-taskflow not available: "Error: ace-taskflow command not found. Install ace-taskflow gem."
- Invalid options: Pass through to ace-taskflow for validation

**Edge Cases:**
- Next task (no ref): `ace-nav task://` → delegates to `ace-taskflow task` (shows next task)
- Ambiguous references: Let ace-taskflow handle disambiguation
- Multiple matching tasks: ace-taskflow's lookup logic handles this
- Cross-release references: Fully supported via delegation (v.0.9.0+task.018, backlog+025)

### Success Criteria

- [ ] **Protocol Resolution**: task:// URIs correctly resolve to ace-taskflow task commands
- [ ] **Argument Pass-through**: All flags (--path, --content, --tree) correctly delegate to ace-taskflow
- [ ] **Reference Format Support**: All ace-taskflow reference formats work (018, task.018, v.0.9.0+task.018, backlog+025)
- [ ] **Error Handling**: Errors from ace-taskflow are properly surfaced to users
- [ ] **Exit Codes**: Exit codes match ace-taskflow behavior (0 success, 1 failure)
- [ ] **Command Delegation Pattern**: Implemented using reusable "cmd" type for future protocol delegations

### Validation Questions

- [ ] **Configuration Location**: Where should cmd-delegation protocol configs live? `.ace/nav/protocols/` or `.ace/nav/cmd-types/`?
- [ ] **Command Detection**: Should ace-nav verify ace-taskflow is available before delegation, or let the shell handle command-not-found?
- [ ] **Future Extensibility**: Should cmd-delegation support other commands beyond ace-taskflow (e.g., release:// → ace-taskflow release)?
- [ ] **Option Filtering**: Should ace-nav filter known options or pass everything through to delegated command?

## Objective

Provide a unified navigation interface across all ACE resources by adding task:// protocol support to ace-nav. This maintains consistency with existing protocols (wfi://, guide://, tmpl://) while delegating actual task management to ace-taskflow's specialized functionality.

**User Value**: Single command for all resource navigation - users don't need to remember whether to use ace-nav or ace-taskflow for different resource types.

## Scope of Work

### User Experience Scope
- Task lookup via task:// protocol with all ace-taskflow reference formats
- Pass-through of display options (--path, --content, --tree)
- Consistent error messaging and exit codes
- Next task lookup (ace-nav task:// with no reference)

### System Behavior Scope
- Protocol resolution for task:// URIs
- Command delegation to ace-taskflow task
- Argument and flag pass-through
- Error handling and propagation

### Interface Scope
- task:// protocol recognition and parsing
- Command delegation mechanism (new "cmd" type)
- Configuration for cmd-delegation protocols

### Deliverables

#### Behavioral Specifications
- task:// protocol usage patterns and examples
- Command delegation behavior documentation
- Error handling and edge case specifications

#### Validation Artifacts
- Success criteria validation tests
- Protocol resolution verification
- Argument pass-through validation

## Out of Scope

- ❌ **Pattern Listing**: `ace-nav 'task://*nav*' --list` requires ace-taskflow tasks enhancement first
- ❌ **Task Creation**: Use ace-taskflow task create directly
- ❌ **Task Status Updates**: Use ace-taskflow task start/done directly
- ❌ **Task Management**: ace-nav is for navigation only, not management operations
- ❌ **Implementation Details**: Specific code structure, file organization, class design
- ❌ **Performance Optimization**: Caching, pre-validation, or other optimizations
- ❌ **Other Delegation Protocols**: Focus on task:// only; release://, idea:// are future enhancements

## References

- Source idea files (marked as done after task creation):
  - `.ace-taskflow/v.0.9.0/ideas/done/20251001-003505-bashace-nav-wfiwork-on-task.md`
  - `.ace-taskflow/v.0.9.0/ideas/done/20251018-151553-ace-nav-add-support-for-task-protocol-see-examp.md`
- Historical context: Task 018 (ace-nav creation) - task:// was designed but never implemented
- Related commands:
  - `ace-taskflow task --help` for reference format documentation
  - `ace-nav wfi://` for existing protocol delegation patterns
