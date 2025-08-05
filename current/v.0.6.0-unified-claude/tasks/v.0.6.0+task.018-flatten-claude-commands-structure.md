---
id: v.0.6.0+task.018
status: pending
priority: high
estimate: 3h
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

## Technical Approach

### Architecture Pattern
- [ ] Maintain separation of concerns in source while flattening output
- [ ] Keep source organization for maintainability (custom vs generated)
- [ ] Flatten structure only during installation/integration

### Technology Stack
- [ ] Ruby-based command generation and installation tools
- [ ] Pathname and FileUtils for file operations
- [ ] YAML for metadata and configuration management
- [ ] Dry-CLI for command interface

### Implementation Strategy
- [ ] Modify output paths in existing tools rather than source reorganization
- [ ] Preserve backward compatibility during transition
- [ ] Maintain clear tracking of command origins (custom vs generated)

## File Modifications

### Modify
- dev-tools/lib/coding_agent_tools/organisms/claude_command_generator.rb
  - Changes: Update generated command output path from `_generated/` subdirectory to flat structure
  - Impact: Commands will be generated directly into the flat directory
  - Integration points: ClaudeCommandsInstaller, handbook claude generate-commands CLI

- dev-tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb
  - Changes: Simplify installation logic to handle flat target structure
  - Impact: Installation process will be streamlined, subdirectory handling removed
  - Integration points: handbook claude integrate CLI, command discovery logic

- dev-handbook/.integrations/claude/commands/
  - Changes: Restructure from subdirectory organization to flat structure
  - Impact: All command files will exist at the same level
  - Migration strategy: Move all files from _custom/ and _generated/ to parent directory

### Delete
- dev-handbook/.integrations/claude/commands/_custom/
  - Reason: Subdirectory structure being flattened
  - Dependencies: ClaudeCommandsInstaller references this path
  - Migration strategy: Move all .md files to parent commands/ directory first

- dev-handbook/.integrations/claude/commands/_generated/
  - Reason: Subdirectory structure being flattened
  - Dependencies: ClaudeCommandGenerator outputs to this path
  - Migration strategy: Move all .md files to parent commands/ directory first

## Risk Assessment

### Technical Risks
- **Risk:** Command name conflicts between custom and generated commands
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Implement conflict detection and clear error messaging
  - **Rollback:** Restore from backup created during installation

- **Risk:** Breaking existing Claude Code installations
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Installer already copies to flat structure in .claude/commands/
  - **Rollback:** Use backup functionality already present in installer

### Integration Risks
- **Risk:** Loss of command origin tracking (custom vs generated)
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Add metadata to command files indicating origin
  - **Monitoring:** Review generated commands for proper metadata

## Implementation Plan

### Planning Steps

* [x] Analyze current directory structure and file organization
  - Identified _custom/ and _generated/ subdirectories in dev-handbook/.integrations/claude/commands/
  - Confirmed installer already flattens to .claude/commands/ during installation
  - Found ClaudeCommandGenerator creates files in _generated/ subdirectory

* [x] Research impact on existing tools and workflows
  - ClaudeCommandsInstaller: Already handles flattening during copy operations
  - ClaudeCommandGenerator: Outputs to _generated/ subdirectory
  - No impact on end-user .claude/commands/ structure (already flat)

* [ ] Design metadata strategy for tracking command origins
  - Add 'origin' field to YAML frontmatter (custom/generated/workflow)
  - Preserve existing metadata injection functionality
  - Ensure backward compatibility with existing commands

### Execution Steps

- [ ] Step 1: Create backup of current command structure
  ```bash
  cp -r dev-handbook/.integrations/claude/commands dev-handbook/.integrations/claude/commands.backup
  ```

- [ ] Step 2: Update ClaudeCommandGenerator to output to flat structure
  - Modify `@generated_dir` to point to commands/ instead of commands/_generated/
  - Add origin metadata to generated files
  - Ensure no conflicts with existing custom commands
  > TEST: Command Generation Validation
  > Type: Action Validation
  > Assert: Generated commands appear directly in commands/ directory with proper metadata
  > Command: handbook claude generate-commands --dry-run

- [ ] Step 3: Migrate existing commands from subdirectories
  - Move all files from _custom/ to commands/
  - Move all files from _generated/ to commands/
  - Add appropriate origin metadata during migration
  > TEST: File Migration Verification
  > Type: Action Validation
  > Assert: All command files exist in flat structure with no subdirectories
  > Command: ls -la dev-handbook/.integrations/claude/commands/

- [ ] Step 4: Update ClaudeCommandsInstaller to handle flat source structure
  - Simplify copy_custom_commands method
  - Remove subdirectory checking logic
  - Maintain backward compatibility for projects with old structure
  > TEST: Installation Process
  > Type: Action Validation
  > Assert: Installer correctly processes flat command structure
  > Command: handbook claude integrate --dry-run --verbose

- [ ] Step 5: Remove empty subdirectories
  - Delete _custom/ directory after verification
  - Delete _generated/ directory after verification
  ```bash
  rmdir dev-handbook/.integrations/claude/commands/_custom
  rmdir dev-handbook/.integrations/claude/commands/_generated
  ```

- [ ] Step 6: Test complete workflow
  - Generate new commands
  - Run integration to verify installation
  - Verify commands.json is properly updated
  > TEST: End-to-End Validation
  > Type: Integration Test
  > Assert: Complete command workflow functions with flat structure
  > Command: handbook claude generate-commands && handbook claude integrate --dry-run

- [ ] Step 7: Update documentation
  - Update any references to subdirectory structure
  - Document new flat organization approach
  - Add migration notes for existing users

## Acceptance Criteria

- [x] AC 1: All command files exist directly in `.claude/commands/` with no subdirectories
- [ ] AC 2: All previously existing commands remain accessible via their original invocation paths
- [ ] AC 3: The `commands.json` file correctly maps all commands in the flat structure
- [ ] AC 4: Command origin tracking is preserved through metadata
- [ ] AC 5: No breaking changes for existing Claude Code installations

## Out of Scope

- ❌ Changing the end-user .claude/commands/ structure (already flat)
- ❌ Modifying command invocation paths or naming conventions
- ❌ Creating new command management features beyond flattening
- ❌ Performance optimizations unrelated to structure flattening

## References

- Feedback item #5: Commands in Claude Code should be flattened
- Current structure example: `.claude/commands/_custom/` and `.claude/commands/_generated/`
- Target structure example: `tmp/gtree/bench-against-qwen3/.claude/commands/` (flat structure)
- Related files:
  - dev-tools/lib/coding_agent_tools/organisms/claude_command_generator.rb
  - dev-tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb
  - dev-handbook/.integrations/claude/commands/