---
id: v.0.6.0+task.011
status: pending
priority: medium
estimate: 3h
dependencies: [v.0.6.0+task.002, v.0.6.0+task.003, v.0.6.0+task.004, v.0.6.0+task.005, v.0.6.0+task.006, v.0.6.0+task.007]
release: v.0.6.0-unified-claude
---

# Update documentation for new Claude integration

## Behavioral Specification

### User Experience
- **Input**: Developer seeks information about Claude integration
- **Process**: Navigates to relevant documentation sections
- **Output**: Clear, comprehensive guidance on using new Claude commands

### Expected Behavior
All documentation should be updated to reflect the new unified handbook CLI approach for Claude integration. This includes the main integration guide, command references, workflow instructions, and any examples. Documentation should guide users from initial setup through advanced usage, with clear migration paths from the old system.

### Interface Contract
```markdown
# Documentation Structure
dev-handbook/.integrations/claude/
├── README.md                    # Main integration guide
├── install-prompts.md          # Updated installation instructions
├── MIGRATION.md                # Migration from old system
└── commands/
    └── README.md               # Command structure explanation

dev-tools/docs/
├── tools.md                    # Add Claude commands section
└── development/
    └── claude-integration.md   # Developer guide

# Example documentation snippets:

## Installing Claude Integration
Use the unified handbook CLI:
```bash
handbook claude integrate
```

## Generating Missing Commands
```bash
handbook claude generate-commands
```

## Command Structure
- Custom commands in `_custom/`
- Generated commands in `_generated/`
```

**Error Handling:**
- Broken links: Validate all internal references
- Outdated examples: Update to new syntax
- Missing sections: Add comprehensive coverage

**Edge Cases:**
- Users with old installation: Migration guide
- First-time users: Quick start guide
- Advanced users: Customization guide

### Success Criteria
- [ ] **Complete Coverage**: All new commands documented
- [ ] **Migration Guide**: Clear path from old to new system
- [ ] **Examples Updated**: All code examples use new syntax
- [ ] **Cross-References**: Links between related docs work
- [ ] **Searchability**: Key terms and commands findable

### Validation Questions
- [ ] **Documentation Style**: Follow existing conventions?
- [ ] **Example Depth**: How many examples per command?
- [ ] **Version Notes**: How to mark deprecated features?
- [ ] **Visual Aids**: Should we include diagrams?

## Objective

Update all documentation to comprehensively cover the new unified Claude integration system, ensuring developers can easily adopt and use the new handbook CLI commands.

## Scope of Work

- **User Experience Scope**: Documentation navigation and clarity
- **System Behavior Scope**: Accurate command descriptions
- **Interface Scope**: Consistent documentation format

### Deliverables

#### Behavioral Specifications
- Documentation structure plan
- Content update checklist
- Cross-reference matrix

#### Validation Artifacts
- Link validation results
- Example code testing
- User feedback incorporation

## Out of Scope
- ❌ **Implementation Details**: Internal code documentation
- ❌ **Technology Decisions**: Documentation tooling changes
- ❌ **Performance Optimization**: Documentation build process
- ❌ **Future Enhancements**: Interactive tutorials, videos

## Technical Approach

### Architecture Pattern
- Hierarchical documentation structure
- Progressive disclosure (basic → advanced)
- Task-oriented organization

### Technology Stack
- Markdown for all documentation
- Code blocks with syntax highlighting
- Cross-reference links

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| Markdown | Documentation format | Standard across project |
| markdownlint | Quality control | Existing tool |
| Link checker | Validation | Prevent broken references |

## File Modifications

### Create
- `dev-handbook/.integrations/claude/MIGRATION.md` - Migration guide
- `dev-handbook/.integrations/claude/commands/README.md` - Command structure docs
- `dev-tools/docs/development/claude-integration.md` - Developer guide

### Modify
- `dev-handbook/.integrations/claude/README.md` - Update main guide
- `dev-handbook/.integrations/claude/install-prompts.md` - New installation process
- `dev-tools/docs/tools.md` - Add Claude commands section
- `dev-tools/README.md` - Update feature list

### Delete
- References to old `claude-integrate` script

## Risk Assessment

### Technical Risks
- **Documentation Drift**: Docs becoming outdated
  - Mitigation: Add to release checklist
- **Example Breakage**: Code examples stop working
  - Mitigation: Test examples in CI

### Integration Risks
- **User Confusion**: During transition period
  - Mitigation: Clear deprecation notices
- **Search Results**: Old docs ranking higher
  - Mitigation: Update meta descriptions

## Implementation Plan

### Planning Steps

* [ ] Audit existing documentation
* [ ] Create documentation outline
* [ ] Identify all references to old system
* [ ] Plan example scenarios

### Execution Steps

- [ ] Update main integration guide
  ```markdown
  # Claude Code Integration
  
  The Coding Agent Workflow Toolkit provides unified CLI commands for managing Claude Code integration.
  
  ## Quick Start
  
  ```bash
  # Install Claude commands
  handbook claude integrate
  
  # Check status
  handbook claude list
  handbook claude validate
  ```
  ```

- [ ] Create migration guide
  ```markdown
  # Migrating from claude-integrate Script
  
  ## What's Changed
  
  The standalone `claude-integrate` script has been replaced with unified `handbook claude` commands.
  
  ## Migration Steps
  
  1. Update to latest dev-tools
  2. Use new commands:
     - `claude-integrate` → `handbook claude integrate`
     - Manual generation → `handbook claude generate-commands`
  ```
  > TEST: Migration Clarity
  > Type: Documentation Review
  > Assert: Steps are clear and complete
  > Command: Review with users of old system

- [ ] Document command structure
  ```markdown
  # Command Organization
  
  Commands are organized in two directories:
  
  ## _custom/
  Hand-crafted commands with special behavior:
  - commit.md - Intelligent git commit
  - draft-tasks.md - Multi-task creation
  
  ## _generated/
  Auto-generated from workflows:
  - Standard workflow references
  - Consistent format
  ```

- [ ] Update tools.md
  ```markdown
  ### Claude Integration Commands
  
  | Command | Purpose | Example |
  |---------|---------|---------|
  | `handbook claude list` | Show all commands | `handbook claude list --verbose` |
  | `handbook claude validate` | Check coverage | `handbook claude validate --strict` |
  | `handbook claude generate-commands` | Create missing | `handbook claude generate-commands --dry-run` |
  | `handbook claude update-registry` | Update JSON | `handbook claude update-registry --backup` |
  | `handbook claude integrate` | Install commands | `handbook claude integrate --force` |
  ```

- [ ] Add examples for common scenarios
  ```markdown
  ## Common Workflows
  
  ### First-time Setup
  ```bash
  # 1. Check what's available
  handbook claude list
  
  # 2. Generate missing commands
  handbook claude generate-commands
  
  # 3. Install everything
  handbook claude integrate
  ```
  
  ### Regular Maintenance
  ```bash
  # Run the meta workflow
  handbook claude validate
  handbook claude generate-commands
  handbook claude integrate
  ```
  ```

- [ ] Validate all links
  ```bash
  # Check for broken links
  find . -name "*.md" -exec grep -l "claude-integrate" {} \;
  
  # Validate cross-references
  markdownlint docs/**/*.md
  ```
  > TEST: Link Validation
  > Type: Automated Check
  > Assert: No broken links
  > Command: Link checker tool

- [ ] Update feature lists
  ```markdown
  ## Features
  - ✅ Unified Claude integration via `handbook claude` commands
  - ✅ Automatic command generation from workflows
  - ✅ Smart command categorization (custom vs generated)
  - ✅ Comprehensive validation and coverage checking
  ```

## Acceptance Criteria

- [ ] All documentation updated with new commands
- [ ] Migration guide helps users transition
- [ ] Examples work when copy-pasted
- [ ] No references to old system remain
- [ ] Cross-references are valid
- [ ] Documentation follows style guide
- [ ] Code examples are tested

## References

- Current documentation structure
- Documentation style guide
- User feedback on old documentation