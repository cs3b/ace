---
id: v.0.6.0+task.009
status: pending
priority: high
estimate: 2h
dependencies: [v.0.6.0+task.003, v.0.6.0+task.004, v.0.6.0+task.005, v.0.6.0+task.006]
release: v.0.6.0-unified-claude
---

# Create update-integration-claude meta workflow

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
- `dev-handbook/.meta/wfi/update-integration-claude.md` - Meta workflow file

### Modify
- `dev-handbook/workflow-instructions/README.md` - Add reference to new workflow

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
* [ ] Define decision tree for customization
* [ ] Plan troubleshooting section
* [ ] Design workflow verification steps

### Execution Steps

- [ ] Create meta workflow directory structure
  ```bash
  mkdir -p dev-handbook/.meta/wfi
  ```

- [ ] Create workflow file with standard header
  ```markdown
  # Update Claude Integration Meta Workflow
  
  ## Goal
  Maintain Claude Code integration using unified handbook CLI commands
  
  ## Prerequisites
  - handbook CLI with Claude commands installed
  - Access to dev-handbook submodule
  - Understanding of Claude command types
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
  
  Decision point: Should this be custom?
  - High complexity or special behavior → Create custom
  - Standard workflow reference → Use generated
  ```
  > TEST: Workflow Clarity
  > Type: Documentation Review
  > Assert: Steps are clear and actionable
  > Command: Review with team member

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

- [ ] Add troubleshooting section
  ```markdown
  ## Troubleshooting
  
  ### Common Issues
  
  **Missing commands after generation**
  - Check file permissions
  - Verify template exists
  
  **Validation failures**
  - Review timestamp mismatches
  - Check for naming conflicts
  ```

- [ ] Create verification checklist
  ```markdown
  ## Success Criteria
  
  - [ ] All workflows have commands (or are whitelisted)
  - [ ] No validation errors reported
  - [ ] Commands work in Claude Code
  - [ ] Registry is up to date
  ```

- [ ] Update workflow index
  ```bash
  # Add reference in workflow README
  echo "- [Update Claude Integration](../.meta/wfi/update-integration-claude.md) - Maintain Claude commands" >> dev-handbook/workflow-instructions/README.md
  ```
  > TEST: Workflow Discovery
  > Type: Documentation Check
  > Assert: Workflow is referenced in index
  > Command: grep "update-integration-claude" dev-handbook/workflow-instructions/README.md

## Acceptance Criteria

- [ ] Complete workflow covering all maintenance tasks
- [ ] Clear decision points for customization
- [ ] Troubleshooting for common issues
- [ ] Examples for all commands
- [ ] Verification steps included
- [ ] Referenced in workflow index