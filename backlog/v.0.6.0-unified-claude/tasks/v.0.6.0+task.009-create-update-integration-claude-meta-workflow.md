---
id: v.0.6.0+task.009
status: draft
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