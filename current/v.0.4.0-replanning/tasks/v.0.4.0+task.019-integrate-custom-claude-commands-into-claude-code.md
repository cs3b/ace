---
id: v.0.4.0+task.019
status: draft
priority: high
estimate: TBD
dependencies: []
needs_review: true
---

# Integrate Custom Claude Commands into Claude Code Integration Script

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Should the commands.json registration be automated or manual when adding new commands?
  - **Research conducted**: Analyzed existing commands.json structure and command patterns
  - **Similar implementations**: Found `/draft-tasks` and `/review-tasks` entries missing from commands.json
  - **Suggested default**: Manual registration with documentation updates
  - **Why needs human input**: Architecture decision - automation vs explicit control trade-off

- [ ] How should command conflicts be resolved when a command already exists in .claude/commands/?
  - **Research conducted**: No existing conflict resolution mechanism found
  - **Suggested default**: Skip with warning message, preserve existing command
  - **Why needs human input**: User experience decision for upgrade scenarios

### [MEDIUM] Enhancement Questions
- [ ] Should the integration validate that referenced workflow files exist before creating commands?
  - **Research conducted**: Current process creates commands regardless of workflow existence
  - **Suggested default**: Add validation step with clear error reporting
  - **Why needs human input**: Balance between safety and flexibility

- [ ] Should old/deprecated commands be automatically removed during integration?
  - **Research conducted**: No cleanup mechanism currently exists
  - **Suggested default**: Keep deprecated commands, add deprecation notice
  - **Why needs human input**: Backward compatibility requirements unclear

## Behavioral Specification

### User Experience
- **Input**: Users invoke Claude Code integration with access to custom task management commands
- **Process**: Commands are discovered and executed seamlessly within Claude environment
- **Output**: Task management operations (`plan-tasks`, `work-on-tasks`, `draft-tasks`, `review-tasks`) work natively in Claude Code

### Expected Behavior

Enable custom Claude commands for planning, working on, and drafting tasks to be integrated into the Claude code integration script, ensuring these commands are discoverable and usable within the `dev-handbook/.integrations/claude/install-prompts.md` system.

The system should provide AI agents and developers with seamless access to task management workflows directly within Claude Code integration, eliminating the need for manual command setup or external task management.

### Interface Contract

```bash
# Custom Commands Available Post-Integration
plan-tasks [task-criteria]         # Plan tasks based on criteria
work-on-tasks [task-id]           # Work on specific task
draft-tasks [idea-file-path]      # Draft tasks from idea files
review-tasks [tasks]

# Integration Script Behavior
install-prompts.md                # Copies custom commands from designated directory
# Commands sourced from: dev-handbook/.integrations/claude/commands/
# Target: Claude Code accessible command registry
```

**Error Handling:**
- Missing source commands: Clear error message indicating which commands are unavailable
- Copy operation failure: Detailed error with file permissions and path information
- Integration script failure: Rollback mechanism and clear error reporting

**Edge Cases:**
- Command conflicts: Strategy for handling naming collisions with existing commands
- Version mismatches: Handling of command updates and compatibility
- Partial integration: Behavior when some but not all commands integrate successfully

### Success Criteria

- [ ] **Command Registration**: Missing entries (`/draft-tasks`, `/review-tasks`) added to commands.json file
- [ ] **Command Verification**: All task management commands (`plan-tasks`, `work-on-tasks`, `draft-tasks`, `review-tasks`) properly registered and accessible
- [ ] **Documentation Update**: `install-prompts.md` updated with clear instructions for registering new commands in commands.json
- [ ] **Consistency Check**: All command files in `.claude/commands/` have corresponding entries in commands.json
- [ ] **Integration Testing**: Verify commands execute their respective workflow instructions correctly
- [ ] **Pattern Documentation**: Clear pattern documented for adding future custom commands including json registration

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

To integrate custom Claude commands for planning, working on, and drafting tasks into the Claude code integration script, ensuring these commands are discoverable and usable within the `dev-handbook/.integrations/claude/install-prompts.md` system for seamless AI agent and developer task management workflows.

## Scope of Work

### User Experience Scope
- Command integration workflow for AI agents using Claude Code
- Seamless task management command execution within Claude environment
- Standardized custom command addition process for future extensions

### System Behavior Scope
- Enhanced `install-prompts.md` script to copy custom commands
- Command discovery and registration mechanism in Claude Code
- Error handling and validation for integration operations

### Interface Scope
- Custom task management commands: `plan-tasks`, `work-on-tasks`, `draft-tasks`
- Integration script interface for command copying and registration
- Standard pattern for future custom command additions

### Deliverables

#### Behavioral Specifications
- User experience flow for command integration and usage
- System behavior specifications for script enhancement
- Interface contract definitions for all custom commands

#### Validation Artifacts
- Success criteria validation through integration testing
- Command availability verification in Claude Code environment
- Integration pattern documentation for future use

## Out of Scope

- ❌ **Implementation Details**: Specific file copying mechanisms, script internal architecture
- ❌ **Technology Decisions**: Choice of scripting language or integration framework
- ❌ **Performance Optimization**: Script execution speed or resource usage optimization
- ❌ **Future Enhancements**: Additional custom commands beyond the three specified

## References

- Source idea file: dev-taskflow/backlog/ideas/20250802-0934-claude-commands-prompts.md
- Integration script: dev-handbook/.integrations/claude/install-prompts.md
- Task management workflow documentation in dev-handbook
