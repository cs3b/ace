---
id: v.0.6.0+task.009
status: done
priority: high
estimate: 2h
dependencies: [v.0.6.0+task.003, v.0.6.0+task.004, v.0.6.0+task.005, v.0.6.0+task.006]
release: v.0.6.0-unified-claude
needs_review: false
---

# Create update-integration-claude meta workflow

## Review Summary

**Review Date**: 2025-08-04

**Questions Resolved**: All 6 questions have been answered by the user:
- Workflow will use .wf.md extension in .meta/wfi/ directory
- Default behavior creates only missing files/directories (no overwrites unless requested)
- No backup needed (Git provides version control)
- Workflow will be run manually by users
- Verification will provide summary of changes rather than testing in Claude Code
- Team synchronization remains out of scope

**Implementation Updates Based on Answers**:
- Prerequisites now include check for .claude/ directory structure
- Process steps updated to handle missing directories/files creation
- Removed backup step from implementation plan
- Changed verification approach to summary generation
- Clarified manual execution pattern in workflow guidance

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
   - Review summary of changes/unchanged items
   - Run validation again to confirm
   - Check for any errors or warnings
```

**Error Handling:**
- Command not found: Direct to setup instructions
- Validation failures: Provide remediation steps
- Installation issues: Rollback guidance
- Missing directories: Create automatically (no overwrite by default)

**Edge Cases:**
- First-time setup: Create missing .claude/ directories automatically
- Major version upgrades: Migration guidance
- Conflicting customizations: Decision framework
- Existing files: Skip by default unless --overwrite flag used

### Success Criteria
- [ ] **Complete Workflow**: All maintenance tasks covered
- [ ] **Clear Decision Points**: When to customize vs generate
- [ ] **Tool Integration**: Uses new handbook claude commands
- [ ] **Repeatable Process**: Can be run regularly
- [ ] **Error Recovery**: Handles common issues gracefully

### Validation Questions
- [x] **Frequency**: Run manually when adding new workflows or after handbook updates
- [ ] **Automation**: Which parts could be automated?
- [ ] **Customization**: When should users create custom commands?
- [x] **Team Usage**: Team synchronization out of scope for initial version

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
  - Note: Using .wf.md extension to match workflow instruction pattern (confirmed)
  - Location: .meta/wfi/ for meta workflow instructions (confirmed)
  - Behavior: Will handle creation of missing .claude/ directories

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

* [x] Review existing meta workflow patterns
  - Study update-blueprint.wf.md structure and format
  - Analyze workflow instruction template patterns
  - Identify common sections: Goal, Prerequisites, Process Steps
* [x] Define decision tree for customization
  - When to use generated vs custom commands
  - How to identify workflows needing custom implementation
  - Criteria for command metadata selection
* [x] Plan troubleshooting section
  - Common validation errors and fixes
  - Permission issues with .claude directory
  - Handling missing dependencies or subcommands
* [x] Design workflow verification steps
  - Command execution testing
  - Registry JSON validation
  - Installation success criteria

### Execution Steps

- [x] Create meta workflow directory structure
  ```bash
  mkdir -p dev-handbook/.meta/wfi
  ```
  > Note: .meta/wfi directory for meta workflow instructions

- [x] Create workflow file with standard header
  ```markdown
  # Update Claude Integration Meta Workflow

  ## Goal
  Maintain Claude Code integration using unified handbook CLI commands

  ## Prerequisites
  - handbook CLI with Claude commands installed (v0.6.0+)
  - Access to dev-handbook submodule
  - Understanding of Claude command types (custom vs generated)
  - Write access to project root (for .claude/ directory creation)
  - Git repository for version control

  ## When to Use This Workflow
  - After adding new workflow instructions
  - When Claude commands are out of sync
  - During major handbook version updates
  - For periodic integration maintenance
  ```

- [x] Document status checking phase
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

- [x] Add command generation guidance
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

- [x] Document registry and installation steps
  ```markdown
  ### 3. Update Registry

  ```bash
  handbook claude update-registry
  ```

  ### 4. Install to Project

  ```bash
  # Preview installation
  handbook claude integrate --dry-run

  # Perform installation (creates missing directories/files by default)
  handbook claude integrate
  
  # Force overwrite existing files if needed
  handbook claude integrate --overwrite
  ```
  ```

- [x] Add comprehensive troubleshooting section
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

- [x] Create comprehensive verification checklist
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
  - [ ] Review installation summary for changes/unchanged items
  - [ ] Check for any errors or warnings in output
  - [ ] Verify no unintended overwrites occurred

  ### Quality Checks
  - [ ] YAML front-matter validates correctly
  - [ ] Command descriptions are meaningful
  - [ ] Tool restrictions are appropriate
  - [ ] Model preferences are set where needed

  ## Success Criteria

  The workflow is successful when:
  - All workflows have corresponding Claude commands
  - Validation passes without errors
  - Installation summary shows expected changes
  - Registry accurately reflects current state
  - No duplicate or conflicting commands exist
  - Missing directories/files created automatically
  ```

- [x] Update workflow index
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

- [x] Complete workflow covering all maintenance tasks
- [x] Clear decision points for customization
- [x] Troubleshooting for common issues
- [x] Examples for all commands
- [x] Verification steps included
- [x] Referenced in workflow index
