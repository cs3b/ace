---
id: v.0.6.0+task.013
status: draft
priority: high
estimate: TBD
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