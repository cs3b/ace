---
id: v.0.6.0+task.013
status: pending
priority: high
estimate: 2h
dependencies: []
---

# Remove update-registry command functionality

## Behavioral Specification

### User Experience
- **Input**: Users attempting to use `handbook claude update-registry` command
- **Process**: Command no longer available in the system
- **Output**: Clear error message indicating the command has been removed

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

The `handbook claude update-registry` command will be completely removed from the system. When users attempt to use this command, they will receive a clear error message indicating that the command no longer exists. All documentation will be updated to remove references to this command and the associated commands.json functionality. The system will continue to function normally without this removed feature.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# CLI Interface (removed)
handbook claude update-registry
# Expected output: Error: Unknown command 'update-registry'

# File System Interface (removed)
# .claude/commands/commands.json will no longer exist
```

**Error Handling:**
- Attempting to use removed command: Error message indicating command not found
- References to commands.json in documentation: Will be removed or updated

**Edge Cases:**
- Existing scripts using update-registry: Will fail with clear error message
- Documentation links to update-registry: Will be removed or redirected

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Command Removal**: The `handbook claude update-registry` command no longer exists in the system
- [ ] **Documentation Cleanup**: All references to update-registry and commands.json are removed from documentation
- [ ] **File Cleanup**: The .claude/commands/commands.json file is deleted from the repository
- [ ] **System Stability**: The handbook command and other functionality continue to work normally

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [x] **Requirement Clarity**: Is the complete removal of update-registry functionality confirmed?
- [x] **Edge Case Handling**: Should we provide migration guidance for users who were using this command?
- [x] **User Experience**: Is a simple error message sufficient, or should we provide alternative suggestions?
- [x] **Success Definition**: Is the removal of all traces (code, tests, docs, files) the complete definition of success?

## Objective

Remove the unnecessary update-registry command functionality from the handbook tool, as neither users nor Claude Code require this feature. This simplifies the codebase and reduces maintenance burden.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Remove all user-facing interfaces for the update-registry command
- **System Behavior Scope**: Eliminate all backend functionality related to update-registry and commands.json
- **Interface Scope**: Remove CLI command and associated file system artifacts

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- Command removal specification
- Error message behavior for removed functionality
- Documentation update requirements

#### Validation Artifacts
- Verification that command no longer exists
- Confirmation of clean documentation
- System stability validation

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: Specific code removal strategies or refactoring approaches
- ❌ **Technology Decisions**: How to handle the removal at the code level
- ❌ **Performance Optimization**: Any performance improvements during removal
- ❌ **Future Enhancements**: Alternative command implementations or replacements

## References

- Feedback item #0: Remove update-registry command and commands.json
- Original idea source: User feedback indicating the command is unnecessary

## Technical Approach

### Architecture Pattern
- [x] Command removal pattern - standard removal of CLI subcommand
- [x] No architectural changes needed - simple command deletion
- [x] No impact on system design - command was never fully implemented

### Technology Stack
- [x] Ruby/dry-cli command structure
- [x] RSpec test suite for command testing
- [x] No external dependencies to remove

### Implementation Strategy
- [x] Remove command registration from CLI
- [x] Delete command implementation file
- [x] Remove/update related tests
- [x] Clean up any references in documentation
- [x] Remove commands.json functionality from ClaudeCommandsInstaller

## File Modifications

### Delete
- dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/update_registry.rb
  - Reason: Command implementation no longer needed
  - Dependencies: Registered in cli.rb
  - Migration strategy: Clean removal, no user data affected

- dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/update_registry_spec.rb
  - Reason: Tests for removed command
  - Dependencies: None
  - Migration strategy: Clean deletion

### Modify
- dev-tools/lib/coding_agent_tools/cli.rb
  - Changes: Remove update-registry command registration from register_handbook_commands method
  - Impact: Command will no longer be available in CLI
  - Integration points: handbook claude subcommands

- dev-tools/exe/handbook
  - Changes: Remove update-registry command registration
  - Impact: Command removed from handbook executable
  - Integration points: Handbook CLI interface

- dev-tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb
  - Changes: Remove commands.json update functionality
  - Impact: Installer will no longer create/update commands.json
  - Integration points: integrate command workflow

- dev-tools/spec/integrations/claude_commands_installer_spec.rb
  - Changes: Remove tests related to commands.json functionality
  - Impact: Test suite simplified
  - Integration points: ClaudeCommandsInstaller testing

- dev-tools/spec/support/claude_test_helpers.rb
  - Changes: Remove create_command_registry helper method
  - Impact: Test helpers simplified
  - Integration points: Test support utilities

- dev-tools/spec/integration/handbook_claude_cli_spec.rb
  - Changes: Remove update-registry from command list test
  - Impact: CLI integration tests updated
  - Integration points: CLI testing

- docs/tools.md (if it contains update-registry reference)
  - Changes: Remove any mention of update-registry command
  - Impact: Documentation stays accurate
  - Integration points: User documentation

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing workflows that use update-registry
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Command was never fully implemented, only printed "Not yet implemented"
  - **Rollback:** Can be restored from git history if needed

- **Risk:** ClaudeCommandsInstaller might fail without commands.json logic
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Carefully remove only commands.json-related code, keep command copying functionality
  - **Rollback:** Test thoroughly before merging

### Integration Risks
- **Risk:** Other commands might depend on commands.json
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Research shows no other commands actively use commands.json
  - **Monitoring:** Run full test suite to verify

## Implementation Plan

### Planning Steps

* [x] Analyze update-registry command implementation
  - Command is a stub that only prints "Not yet implemented"
  - Registered in cli.rb and handbook executable
  - Has basic test coverage showing it's not implemented

* [x] Research commands.json usage in codebase
  - Used by ClaudeCommandsInstaller#update_commands_json method
  - Referenced in tests and documentation
  - No active functionality depends on it

* [x] Identify all files requiring modification
  - 8 files need modification or deletion
  - No user-facing features will be broken

### Execution Steps

- [ ] Remove update-registry command registration from dev-tools/lib/coding_agent_tools/cli.rb
  > TEST: Command Registration Removed
  > Type: Action Validation
  > Assert: update-registry not registered in CLI
  > Command: cd dev-tools && bundle exec rspec spec/integration/handbook_claude_cli_spec.rb

- [ ] Remove update-registry registration from dev-tools/exe/handbook

- [ ] Delete dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/update_registry.rb

- [ ] Delete dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/update_registry_spec.rb

- [ ] Remove commands.json functionality from ClaudeCommandsInstaller
  - Remove update_commands_json method
  - Remove commands.json-related instance variables
  - Update run method to skip commands.json update
  - Remove json_registry_entry and registry_differs? methods

- [ ] Update ClaudeCommandsInstaller tests
  - Remove "updates commands.json" test
  - Remove "with existing commands.json" context
  - Update integration expectations

- [ ] Remove create_command_registry from claude_test_helpers.rb

- [ ] Update handbook_claude_cli_spec.rb to remove update-registry from expected commands

- [ ] Search and remove any remaining references to update-registry or commands.json in documentation
  > TEST: Documentation Cleanup
  > Type: Action Validation
  > Assert: No references to update-registry remain
  > Command: grep -r "update-registry" docs/ || echo "No references found"

- [ ] Run full test suite to ensure nothing is broken
  > TEST: Full Test Suite
  > Type: Integration Test
  > Assert: All tests pass
  > Command: cd dev-tools && bundle exec rspec

## Acceptance Criteria

- [x] The `handbook claude update-registry` command no longer exists in the system
- [x] All references to update-registry and commands.json are removed from documentation
- [x] The .claude/commands/commands.json file is no longer created or updated by the system
- [x] The handbook command and other functionality continue to work normally

## Out of Scope

- ❌ **Implementation Details**: Specific code removal strategies or refactoring approaches
- ❌ **Technology Decisions**: How to handle the removal at the code level
- ❌ **Performance Optimization**: Any performance improvements during removal
- ❌ **Future Enhancements**: Alternative command implementations or replacements