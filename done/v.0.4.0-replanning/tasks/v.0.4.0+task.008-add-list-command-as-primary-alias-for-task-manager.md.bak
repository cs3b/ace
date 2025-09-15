---
id: v.0.4.0+task.008
status: done
priority: high
estimate: 1h
dependencies: []
---

# Add list command as primary alias for task-manager

## Behavioral Specification

### User Experience
- **Input**: Users type `task-manager list` instead of `task-manager all`
- **Process**: Command executes identically to existing `all` command
- **Output**: Same task listing output as `task-manager all`

### Expected Behavior
The system should accept `list` as the primary command with `all` as an alias for the existing functionality in `task-manager`, providing users with a more intuitive CLI experience that follows common conventions.

### Interface Contract
```bash
# Primary interface (new)
task-manager list

# Alias interface (existing, maintained for compatibility)
task-manager all

# Both commands should produce identical output
```

### Success Criteria

- [ ] `task-manager list` executes successfully
- [ ] `task-manager all` continues to work as alias
- [ ] Output is identical between both commands
- [ ] No regression in existing functionality
- [ ] Documentation updated to reflect new primary command
- [ ] Help text shows both `list` and `all` options

### Validation Questions

- [ ] Verify dry-cli framework supports command aliasing?
- [ ] Confirm no breaking changes to existing automation?
- [ ] Update all references in documentation?

## Objective

Provide a more intuitive and conventional command interface for task-manager by making `list` the primary command and `all` an alias, improving user experience and CLI discoverability.

## Scope of Work

- Modify CLI command definition to make `list` primary command
- Implement `all` as alias for backward compatibility
- Update documentation and help text

### Deliverables

#### Interface Contracts
- CLI command specifications with `list` as primary
- Alias mapping for `all` command
- Help text updates

#### Behavioral Documentation
- User experience flows documented
- Success criteria definitions
- Validation question resolutions

#### Modify

- dev-tools CLI command definition files
- docs/tools.md documentation
- Help text and command descriptions

## Technical Approach

### Architecture Pattern
- ✅ ATOM Architecture Integration: Only CLI layer modification required
- ✅ dry-cli Registry: Supports multiple command registrations for same class
- ✅ Zero Impact on Business Logic: No changes to TaskManager organism or molecules

### Technology Stack
- ✅ dry-cli framework: Built-in support for command aliasing via multiple registrations
- ✅ Ruby 3.2+: No version compatibility issues
- ✅ Existing CLI structure: Follows established patterns in exe/task-manager

### File Modifications

#### Modify
- dev-tools/exe/task-manager
  - Changes: Add `register "list"` entry and reorder to make "list" primary
  - Impact: Provides both commands without breaking existing usage
  - Integration points: Uses existing CodingAgentTools::Cli::Commands::Task::All class

- docs/tools.md
  - Changes: Update task-manager documentation to show "list" as primary command
  - Impact: User documentation matches new interface behavior
  - Integration points: Maintain backward compatibility documentation

## Implementation Plan

### Planning Steps

* [x] Analyze current task-manager CLI structure and dry-cli pattern
  > TEST: Architecture Understanding Check
  > Type: Pre-condition Check
  > Assert: exe/task-manager uses dry-cli registry with direct command registration
  > Command: grep -n "register.*all" dev-tools/exe/task-manager
* [x] Verify dry-cli supports multiple command names for same class
  > TEST: Framework Capability Verification
  > Type: Research Validation
  > Assert: dry-cli allows multiple register calls for same command class
  > Command: Review dry-cli documentation and existing patterns
* [x] Confirm no impact on existing TaskManager organism business logic
  > TEST: Business Logic Isolation Check
  > Type: Impact Analysis
  > Assert: Changes only affect CLI registration, not task management logic
  > Command: Verify CodingAgentTools::Cli::Commands::Task::All remains unchanged

### Execution Steps

- [ ] Update dev-tools/exe/task-manager to add "list" as primary command
  > TEST: Primary Command Registration
  > Type: Action Validation
  > Assert: "list" command is registered and points to Task::All class
  > Command: task-manager list --help
- [ ] Maintain "all" as alias for backward compatibility
  > TEST: Backward Compatibility Verification
  > Type: Regression Prevention
  > Assert: "all" command continues to work identically
  > Command: task-manager all
- [ ] Update docs/tools.md to reflect "list" as primary command
  > TEST: Documentation Accuracy Check
  > Type: Documentation Validation
  > Assert: Tools documentation shows "list" as primary with "all" as alias
  > Command: grep -A 5 -B 5 "task-manager" docs/tools.md
- [ ] Verify help text displays both commands appropriately
  > TEST: Help Text Completeness
  > Type: User Experience Validation
  > Assert: task-manager --help shows both "list" and "all" commands
  > Command: task-manager --help | grep -E "(list|all)"
- [ ] Test functional equivalence between commands
  > TEST: Functional Equivalence Verification
  > Type: Behavioral Validation
  > Assert: Both commands produce identical output for same task set
  > Command: diff <(task-manager list) <(task-manager all)

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing automation that uses "task-manager all"
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Maintain "all" as alias, add comprehensive backward compatibility testing
  - **Rollback:** Revert exe/task-manager changes, restore original registration order

### Integration Risks
- **Risk:** dry-cli framework behavior changes with multiple registrations
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Test both command variants thoroughly
  - **Monitoring:** Verify help text shows both commands correctly

## Acceptance Criteria

- [ ] AC 1: "task-manager list" executes successfully and shows all tasks
- [ ] AC 2: "task-manager all" continues to work identically (backward compatibility)
- [ ] AC 3: Documentation updated to reflect "list" as primary command
- [ ] AC 4: Help text displays both "list" and "all" commands appropriately
- [ ] AC 5: All embedded tests in Implementation Plan pass

## Out of Scope

- ❌ Changes to TaskManager organism or underlying business logic
- ❌ Modifications to Task::All command class implementation
- ❌ Additional command features or functionality enhancements
- ❌ Performance optimization of task listing operations

## References

- Enhanced idea: dev-taskflow/backlog/ideas/20250731-0747-list-all-alias.md
- Current tools documentation: docs/tools.md
- CLI framework: dry-cli documentation
