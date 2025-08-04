---
id: v.0.6.0+task.009
status: pending
priority: high
estimate: 2h
dependencies: [v.0.6.0+task.003, v.0.6.0+task.004, v.0.6.0+task.005, v.0.6.0+task.006]
release: v.0.6.0-unified-claude
needs_review: true
---

# Create update-integration-claude meta workflow

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Should the meta workflow be created as a .wf.md file or use a different naming convention?
  - **Research conducted**: Examined existing workflow patterns in dev-handbook/workflow-instructions/
  - **Found pattern**: All workflows use .wf.md extension (e.g., update-blueprint.wf.md)
  - **Suggested default**: Create as update-integration-claude.wf.md in .meta/wfi/ directory
  - **Why needs human input**: Confirm meta workflow naming convention and placement

- [ ] How should the workflow handle first-time setup vs maintenance updates?
  - **Research conducted**: Dependencies show generate, validate, and integrate subcommands
  - **Current design**: Commands assume existing setup based on interface examples
  - **Suggested default**: Add prerequisite check step with setup guidance if .claude/ missing
  - **Why needs human input**: Need clear separation between initialization and update flows

### [MEDIUM] Enhancement Questions
- [ ] Should the workflow include automated backup of existing Claude integration?
  - **Research conducted**: No backup patterns found in current workflows
  - **Integration commands**: Support --dry-run but no explicit backup
  - **Suggested default**: Add optional backup step before integrate command
  - **Why needs human input**: Safety vs simplicity trade-off

- [ ] What should be the recommended frequency for running this workflow?
  - **Research conducted**: Validation question asks about frequency but no answer provided
  - **Similar workflows**: update-blueprint has no fixed schedule
  - **Suggested default**: Run when adding new workflows or after major handbook updates
  - **Why needs human input**: Balance between staying current and workflow overhead

- [ ] Should the workflow include a step to test generated commands in Claude Code?
  - **Research conducted**: Success criteria mentions "Test commands in Claude Code"
  - **Current spec**: Verification step exists but lacks detail
  - **Suggested default**: Add specific test examples for common command types
  - **Why needs human input**: Level of testing detail needed in workflow

### [LOW] Future Enhancement Questions
- [ ] Should the workflow support team synchronization features?
  - **Research conducted**: Validation question mentions "team sharing"
  - **Current scope**: Out of scope section excludes "team sharing"
  - **Suggested default**: Document as future enhancement, not in v1
  - **Why needs human input**: Confirm this remains out of initial scope

## Behavioral Specification

### User Experience
- **Input**: Developer follows the workflow to maintain Claude integration
- **Process**: Guided steps through validation, generation, and installation
- **Output**: Fully updated and synchronized Claude integration

### Expected Behavior
The workflow should guide developers through the complete process of maintaining Claude integration, from checking current status through generating missing commands to final installation. It should leverage the new unified handbook CLI commands and provide clear decision points for when to generate vs customize commands. The workflow should be repeatable and help maintain consistency.

### Interface Contract
```markdown
# Workflow steps presented to user:

1. **Check Current Status**
   - Run: `handbook claude list`
   - Run: `handbook claude validate`
   - Review findings and decide on actions

2. **Generate Missing Commands**
   - Run: `handbook claude generate-commands --dry-run`
   - Review proposed generations
   - Run: `handbook claude generate-commands`
   - Customize generated commands if needed

3. **Update Registry**
   - Run: `handbook claude update-registry`
   - Verify JSON validity

4. **Install to Project**
   - Run: `handbook claude integrate --dry-run`
   - Review installation plan
   - Run: `handbook claude integrate`

5. **Verify Installation**
   - Test commands in Claude Code
   - Run validation again to confirm
```

**Error Handling:**
- Command not found: Direct to setup instructions
- Validation failures: Provide remediation steps
- Installation issues: Rollback guidance

**Edge Cases:**
- First-time setup: Additional initialization steps
- Major version upgrades: Migration guidance
- Conflicting customizations: Decision framework

### Success Criteria
- [ ] **Complete Workflow**: All maintenance tasks covered
- [ ] **Clear Decision Points**: When to customize vs generate
- [ ] **Tool Integration**: Uses new handbook claude commands
- [ ] **Repeatable Process**: Can be run regularly
- [ ] **Error Recovery**: Handles common issues gracefully

### Validation Questions
- [ ] **Frequency**: How often should this workflow be run?
- [ ] **Automation**: Which parts could be automated?
- [ ] **Customization**: When should users create custom commands?
- [ ] **Team Usage**: How to share customizations across team?

## Objective

Create a comprehensive meta workflow that guides developers through maintaining their Claude Code integration using the new unified handbook CLI commands.

## Scope of Work

- **User Experience Scope**: Step-by-step workflow guidance
- **System Behavior Scope**: Integration with new CLI commands
- **Interface Scope**: Workflow documentation format

### Deliverables

#### Behavioral Specifications
- Workflow step documentation
- Decision tree for customization
- Common scenarios and solutions

#### Validation Artifacts
- Workflow completeness checklist
- Command sequence validation
- Success criteria verification

## Out of Scope
- ❌ **Implementation Details**: Specific command implementations
- ❌ **Technology Decisions**: Workflow automation tools
- ❌ **Performance Optimization**: Workflow execution speed
- ❌ **Future Enhancements**: CI/CD integration, team sharing

## References

- Existing workflow instruction patterns
- New handbook claude commands
- Current update workflows in dev-handbook

## Technical Approach

### Architecture Pattern
- Meta workflow following established .wf.md format
- Step-by-step guidance with command examples
- Decision trees for customization choices

### Technology Stack
- Markdown for workflow documentation
- Embedded command examples
- Template structure for consistency

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| Markdown | Workflow format | Standard for all workflows |
| handbook CLI | Command execution | New unified interface |
| Template embedding | Consistency | Reusable patterns |

## File Modifications

### Create
- `dev-handbook/.meta/wfi/update-integration-claude.wf.md` - Meta workflow file
  - Note: Using .wf.md extension to match workflow instruction pattern
  - Location: .meta/wfi/ for meta workflow instructions

### Modify
- `dev-handbook/workflow-instructions/README.md` - Add reference to new workflow
  - Add link in meta workflows section (create if doesn't exist)
  - Format: `- [Update Claude Integration](../.meta/wfi/update-integration-claude.wf.md)`

### Delete
- None required

## Risk Assessment

### Technical Risks
- **Command Changes**: CLI interface might evolve
  - Mitigation: Version-specific documentation
- **Workflow Complexity**: Too many steps might overwhelm
  - Mitigation: Clear sections and optional steps

### Integration Risks
- **Tool Dependencies**: Requires all subcommands working
  - Mitigation: Add prerequisite checks
- **User Confusion**: When to use this vs individual commands
  - Mitigation: Clear use case documentation

## Implementation Plan

### Planning Steps

* [ ] Review existing meta workflow patterns
  - Study update-blueprint.wf.md structure and format
  - Analyze workflow instruction template patterns
  - Identify common sections: Goal, Prerequisites, Process Steps
* [ ] Define decision tree for customization
  - When to use generated vs custom commands
  - How to identify workflows needing custom implementation
  - Criteria for command metadata selection
* [ ] Plan troubleshooting section
  - Common validation errors and fixes
  - Permission issues with .claude directory
  - Handling missing dependencies or subcommands
* [ ] Design workflow verification steps
  - Command execution testing
  - Registry JSON validation
  - Installation success criteria

### Execution Steps

- [ ] Create meta workflow directory structure
  ```bash
  mkdir -p dev-handbook/.meta/wfi
  ```
  > Note: .meta/wfi directory for meta workflow instructions

- [ ] Create workflow file with standard header
  ```markdown
  # Update Claude Integration Meta Workflow
  
  ## Goal
  Maintain Claude Code integration using unified handbook CLI commands
  
  ## Prerequisites
  - handbook CLI with Claude commands installed (v0.6.0+)
  - Access to dev-handbook submodule
  - Understanding of Claude command types (custom vs generated)
  - Write access to .claude/ directory in project root
  
  ## When to Use This Workflow
  - After adding new workflow instructions
  - When Claude commands are out of sync
  - During major handbook version updates
  - For periodic integration maintenance
  ```

- [ ] Document status checking phase
  ```markdown
  ## Process Steps
  
  ### 1. Check Current Status
  
  First, understand the current state of your Claude integration:
  
  ```bash
  # List all commands and their status
  handbook claude list
  
  # Validate coverage and consistency  
  handbook claude validate
  ```
  
  Review the output to identify:
  - Missing commands that need generation
  - Outdated commands that need updates
  - Duplicate commands that need resolution
  ```

- [ ] Add command generation guidance
  ```markdown
  ### 2. Generate Missing Commands
  
  For workflows without commands:
  
  ```bash
  # Preview what would be generated
  handbook claude generate-commands --dry-run
  
  # Generate missing commands
  handbook claude generate-commands
  ```
  
  **Decision Tree: Custom vs Generated Commands**
  
  Should this workflow have a custom command?
  
  1. Does it require special tools or model selection?
     - YES → Create custom command with metadata
     - NO → Continue to next question
  
  2. Does it have complex multi-step operations?
     - YES → Consider custom command for clarity
     - NO → Continue to next question
  
  3. Is it a simple workflow reference?
     - YES → Use generated command
     - NO → Evaluate custom needs
  
  Examples:
  - `commit.md` → Custom (git operations, special formatting)
  - `capture-idea.wf.md` → Generated (simple workflow reference)
  - `load-project-context.md` → Custom (complex initialization)
  ```
  > TEST: Decision Tree Clarity
  > Type: Documentation Review
  > Assert: Decision criteria are clear and examples help
  > Command: Test with sample workflows

- [ ] Document registry and installation steps
  ```markdown
  ### 3. Update Registry
  
  ```bash
  handbook claude update-registry
  ```
  
  ### 4. Install to Project
  
  ```bash
  # Preview installation
  handbook claude integrate --dry-run
  
  # Perform installation
  handbook claude integrate
  ```
  ```

- [ ] Add comprehensive troubleshooting section
  ```markdown
  ## Troubleshooting
  
  ### Common Issues and Solutions
  
  **Missing commands after generation**
  - Check file permissions in dev-handbook/.integrations/claude/
  - Verify template exists at correct location
  - Ensure workflow files have .wf.md extension
  - Run with --verbose flag for detailed output
  
  **Validation failures**
  - Review content hash mismatches (outdated commands)
  - Check for naming conflicts between custom and generated
  - Verify JSON registry syntax is valid
  - Look for duplicate command definitions
  
  **Installation errors**
  - Ensure .claude/ directory exists and is writable
  - Check if commands are being flattened correctly
  - Verify no path conflicts during copy
  - Run with --dry-run first to preview changes
  
  **Command not working in Claude Code**
  - Verify YAML front-matter syntax is correct
  - Check that workflow path references are absolute
  - Ensure @.claude/commands/commit.md reference exists
  - Test with simpler command first
  
  ### Diagnostic Commands
  
  ```bash
  # Check current state
  handbook claude list --verbose
  
  # Validate with detailed output
  handbook claude validate --format json
  
  # Test specific workflow
  handbook claude generate-commands --workflow capture-idea
  ```
  ```

- [ ] Create comprehensive verification checklist
  ```markdown
  ## Verification Checklist
  
  ### Pre-Integration Checks
  - [ ] All workflows have commands (custom or generated)
  - [ ] No validation errors reported
  - [ ] Registry JSON is valid and complete
  - [ ] Dry-run shows expected changes
  
  ### Post-Integration Verification
  - [ ] Commands appear in .claude/commands/
  - [ ] Agents appear in .claude/agents/ (if applicable)
  - [ ] Test basic command: `@load-project-context`
  - [ ] Test workflow command: `@capture-idea "test idea"`
  - [ ] Verify commit command works: `@commit`
  
  ### Quality Checks
  - [ ] YAML front-matter validates correctly
  - [ ] Command descriptions are meaningful
  - [ ] Tool restrictions are appropriate
  - [ ] Model preferences are set where needed
  
  ## Success Criteria
  
  The workflow is successful when:
  - All workflows have corresponding Claude commands
  - Validation passes without errors
  - Commands execute properly in Claude Code
  - Registry accurately reflects current state
  - No duplicate or conflicting commands exist
  ```

- [ ] Update workflow index
  ```bash
  # Add reference in workflow README under meta workflows section
  # Note: May need to create "Meta Workflows" section if it doesn't exist
  echo "- [Update Claude Integration](../.meta/wfi/update-integration-claude.wf.md) - Maintain Claude commands" >> dev-handbook/workflow-instructions/README.md
  ```
  > TEST: Workflow Discovery
  > Type: Documentation Check
  > Assert: Workflow is referenced in index
  > Command: grep "update-integration-claude.wf.md" dev-handbook/workflow-instructions/README.md

## Acceptance Criteria

- [ ] Complete workflow covering all maintenance tasks
- [ ] Clear decision points for customization
- [ ] Troubleshooting for common issues
- [ ] Examples for all commands
- [ ] Verification steps included
- [ ] Referenced in workflow index