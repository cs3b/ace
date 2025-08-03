---
id: v.0.4.0+task.019
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Integrate Custom Claude Commands into Claude Code Integration Script

## Review Questions (Resolved)

### [HIGH] Critical Implementation Questions
- [x] Should the commands.json registration be automated or manual when adding new commands?
  - **Answer**: Automated (maintaining existing pattern)
  - **Implementation**: Script should automatically add entries to commands.json

- [x] How should command conflicts be resolved when a command already exists in .claude/commands/?
  - **Answer**: Skip existing commands, only add new ones
  - **Implementation**: Check existence before creating, preserve user modifications

### [MEDIUM] Enhancement Questions
- [x] Should the integration validate that referenced workflow files exist before creating commands?
  - **Answer**: No validation needed
  - **Implementation**: Create commands regardless of workflow file existence

- [x] Should old/deprecated commands be automatically removed during integration?
  - **Answer**: No, preserve all existing commands
  - **Rationale**: Users may have created custom commands or modified existing ones

## Behavioral Specification

### User Experience
- **Input**: Users invoke Claude Code integration with access to custom task management commands
- **Process**: Commands are discovered and executed seamlessly within Claude environment
- **Output**: Task management operations (`plan-tasks`, `work-on-tasks`, `draft-tasks`, `review-tasks`) work natively in Claude Code

### Expected Behavior

The `dev-handbook/.integrations/claude/install-prompts.md` script should be enhanced to automatically:
1. Scan `dev-handbook/workflow-instructions/*.wf.md` files
2. Generate corresponding command files in `.claude/commands/`
3. Automatically update `.claude/commands/commands.json` with new command entries
4. Skip existing commands to preserve user modifications
5. Provide clear output showing which commands were created/skipped

This automation ensures all workflow instructions are immediately available as Claude Code commands without manual intervention.

### Interface Contract

```bash
# Script Execution
./install-prompts.sh              # Run the automated installation script
# OR
claude-integrate                  # Alternative command name

# Script Behavior
- Scans: dev-handbook/workflow-instructions/*.wf.md
- Creates: .claude/commands/[workflow-name].md (if not exists)
- Updates: .claude/commands/commands.json (adds missing entries)
- Preserves: Existing commands and user modifications

# Output Example
Installing Claude Code commands...
✓ Created: draft-task.md
✓ Created: plan-task.md
✗ Skipped: work-on-task.md (already exists)
✓ Updated: commands.json (2 new entries added)
Installation complete: 2 created, 1 skipped
```

**Error Handling:**
- File permission issues: Clear error with suggested chmod/chown commands
- JSON parsing errors: Backup original commands.json before modification
- Write failures: Transaction-like approach with rollback on failure

**Edge Cases:**
- Existing commands: Skip and report (preserve user modifications)
- Custom templates: Use template from install-prompts.md if defined
- Special characters in filenames: Sanitize workflow names for command files
- Empty workflow directory: Report "No workflows found" gracefully

### Success Criteria

- [ ] **Automation Script Created**: Executable script that automates the entire command installation process
- [ ] **Command Generation**: Script automatically creates command files from workflow instructions
- [ ] **JSON Registration**: Script automatically updates commands.json with new entries
- [ ] **Preservation Logic**: Script skips existing commands to preserve user modifications
- [ ] **Status Reporting**: Script provides clear output showing created/skipped/updated items
- [ ] **Documentation Update**: install-prompts.md updated to reference the automation script
- [ ] **Integration Testing**: All generated commands execute their workflow instructions correctly

### Validation Questions

- [x] **Script Analysis**: What is the exact structure and copying mechanism of `dev-handbook/.integrations/claude/install-prompts.md`?
  - **Answer found through research**: The install-prompts.md file provides a template-based approach for creating commands. Each workflow file (*.wf.md) maps to a command file in .claude/commands/. The script uses a simple template: "read whole file and follow @dev-handbook/workflow-instructions/[workflow-name].wf.md" followed by "/commit".

- [x] **Command Location**: Where should custom command markdown files be placed for script discovery?
  - **Answer found through research**: Commands should be placed in `.claude/commands/` directory at the project root, with corresponding entries in `.claude/commands/commands.json`.

- [x] **Integration Method**: How does the script register commands with Claude Code integration?
  - **Answer found through research**: Commands are registered via the `commands.json` file in `.claude/commands/`. Each command has an entry with its name (e.g., "/draft-task") and optional configuration for workspace restrictions and tool permissions.

- [ ] **Update Process**: How are command modifications and versioning handled in the integration workflow?
  - **Partial answer through research**: No versioning mechanism found. Commands appear to be overwritten when updated.
  - **Still needs clarification**: Should there be a versioning strategy for command updates?

## Research Findings

### Current State Analysis
- **Commands Directory**: `.claude/commands/` contains 26 command files including complex multi-task commands
- **Registration File**: `commands.json` manages command registration with optional workspace restrictions
- **Existing Task Commands**: Found `draft-tasks.md`, `plan-tasks.md`, `work-on-tasks.md`, `review-tasks.md` already exist
- **Registration Gap**: `/draft-tasks` and `/review-tasks` commands exist but are missing from commands.json
- **Template Pattern**: Commands follow consistent pattern referencing workflow files with `@` prefix
- **Custom Templates**: Some commands (commit.wf.md, load-project-context.wf.md) have custom templates in install-prompts.md

### Implementation Clarity Achieved
- **Command Creation Process**: Well-documented in install-prompts.md with clear mapping rules
- **File Structure**: Commands use `.md` extension, workflows use `.wf.md` extension
- **Command Format**: Simple reference pattern with `/commit` suffix for most commands
- **Integration Mechanism**: Manual creation of command files and json registration

### Remaining Ambiguities
- **Automation vs Manual**: No clear guidance on whether command creation should be automated
- **Conflict Resolution**: No documented strategy for handling existing commands during updates
- **Version Management**: No versioning system for command updates or migrations
- **Validation Requirements**: No validation that referenced workflow files exist

## Objective

To create an automated script that generates Claude Code commands from workflow instructions, eliminating manual command creation and ensuring all workflows are immediately accessible as Claude commands with proper JSON registration and user modification preservation.

## Scope of Work

### User Experience Scope
- One-command installation of all workflow commands
- Clear feedback on installation progress and results
- Preservation of user customizations during updates

### System Behavior Scope
- Automated scanning of workflow instruction files
- Intelligent command file generation with template support
- Automatic JSON registration with conflict detection
- Status reporting and error handling

### Interface Scope
- Single executable script for command installation
- Command-line interface with progress indicators
- JSON file management with backup capabilities

### Deliverables

#### Automation Script
- Executable script for automated command installation
- Support for both initial setup and incremental updates
- Clear output and error reporting

#### Command Management
- Automatic generation of command files from workflows
- Automatic registration in commands.json
- Preservation of existing user modifications

#### Documentation
- Updated install-prompts.md referencing automation
- Usage instructions for the installation script
- Pattern documentation for future enhancements

## Out of Scope

- ❌ **Command Content Modification**: Changing how existing commands work internally
- ❌ **Workflow Creation**: Creating new workflow instruction files
- ❌ **Claude Code Internal Changes**: Modifying Claude Code's command execution mechanism
- ❌ **Complex Versioning System**: Git-based versioning or command history tracking

## References

- Source idea file: dev-taskflow/backlog/ideas/20250802-0934-claude-commands-prompts.md
- Integration script: dev-handbook/.integrations/claude/install-prompts.md
- Task management workflow documentation in dev-handbook
