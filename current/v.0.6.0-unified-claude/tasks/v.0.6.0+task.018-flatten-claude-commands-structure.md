---
id: v.0.6.0+task.018
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Flatten Claude commands structure

## Behavioral Specification

### User Experience
- **Input**: Users navigate to Claude Code commands in the project
- **Process**: Users look for command files in a single directory without subdirectory navigation
- **Output**: All command files are found directly in `.claude/commands/` directory

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

The Claude Code command system should present all command files in a single, flat directory structure. Users should be able to find any command file directly in the `.claude/commands/` directory without navigating through subdirectories like `_custom/` or `_generated/`. This simplifies command discovery and reduces cognitive overhead when managing commands.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# File Organization Structure
.claude/
├── commands/
│   ├── capture-idea.md
│   ├── commit.md
│   ├── create-adr.md
│   ├── draft-task.md
│   ├── ... (all other command files)
│   └── commands.json

# Commands remain invokable with same paths
/commit
/draft-task
/create-reflection-note
# etc.
```

**Error Handling:**
- Missing command file: System should provide clear error message indicating which command file is missing
- Duplicate command names: System should handle gracefully with clear error reporting

**Edge Cases:**
- Migration from existing structure: All existing commands must be preserved during flattening
- Command registry consistency: The `commands.json` must accurately reflect the flat structure

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Flat Directory Structure**: All command files exist directly in `.claude/commands/` with no subdirectories
- [ ] **Command Accessibility**: All previously existing commands remain accessible via their original invocation paths
- [ ] **Registry Consistency**: The `commands.json` file correctly maps all commands in the flat structure

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->

- [ ] **Command Naming**: Should command files retain any prefix to indicate their origin (custom vs generated)?
- [ ] **Migration Path**: How should existing projects handle the transition from subfolder to flat structure?
- [ ] **Backup Strategy**: Should the system maintain a backup of the original structure during migration?
- [ ] **Conflict Resolution**: How should the system handle potential naming conflicts between custom and generated commands?

## Objective

Simplify the Claude Code command structure to improve user experience by eliminating unnecessary directory hierarchy, making command discovery and management more straightforward.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Simplified command file navigation and discovery in Claude Code projects
- **System Behavior Scope**: Flat file organization for all Claude commands without subdirectories
- **Interface Scope**: Maintained command invocation paths with updated file organization

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- Flat directory structure specification for Claude commands
- Command file organization guidelines
- Migration path definition from subfolder to flat structure

#### Validation Artifacts
- Command accessibility verification methods
- Directory structure validation criteria
- Migration success indicators

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: Specific file manipulation commands or scripts
- ❌ **Technology Decisions**: Choice of migration tools or automation frameworks
- ❌ **Performance Optimization**: File system performance considerations
- ❌ **Future Enhancements**: Additional command management features beyond flattening

## References

- Feedback item #5: Commands in Claude Code should be flattened
- Current structure example: `.claude/commands/_custom/` and `.claude/commands/_generated/`
- Target structure example: `tmp/gtree/bench-against-qwen3/.claude/commands/` (flat structure)