---
id: v.0.6.0+task.001
status: pending
priority: high
estimate: 2h
dependencies: []
release: v.0.6.0-unified-claude
---

# Create Claude command directory structure

## Behavioral Specification

### User Experience
- **Input**: Developer initiates organization of Claude commands within dev-handbook
- **Process**: System creates organized directory structure distinguishing custom vs generated commands
- **Output**: Clear, version-controlled directory structure ready for Claude commands

### Expected Behavior
The system should create a well-organized directory structure within dev-handbook that clearly separates custom hand-crafted commands from auto-generated ones. Developers should be able to easily locate, modify, and add new commands. The structure should support version control and make the distinction between command types immediately apparent.

### Interface Contract
```bash
# Directory structure to be created
dev-handbook/.integrations/claude/
├── agents/                       # Specialized agents (existing)
├── commands/                     # All Claude commands
│   ├── _custom/                  # Hand-crafted commands
│   ├── _generated/              # Auto-generated commands
│   └── commands.json            # Command registry
├── templates/                    # Templates for generation
│   ├── workflow-command.md.tmpl
│   └── agent-command.md.tmpl
└── install-prompts.md           # Installation guide (existing)
```

**Error Handling:**
- Directory already exists: Skip creation, report as already configured
- Permission denied: Report error with clear remediation steps

**Edge Cases:**
- Existing commands in flat structure: Preserve and report for manual migration
- Conflicting file names: Report conflicts for manual resolution

### Success Criteria
- [ ] **Directory Structure Created**: All directories exist with proper permissions
- [ ] **Template Files Created**: Command templates available for generation
- [ ] **No Data Loss**: Existing files preserved and accessible
- [ ] **Version Control Ready**: Structure supports git operations

### Validation Questions
- [ ] **Migration Strategy**: How should existing commands be handled during structure creation?
- [ ] **Naming Convention**: Should underscore prefix (_custom, _generated) be used or alternative?
- [ ] **Template Format**: What variables and structure should templates support?
- [ ] **Permissions**: What file permissions should be set for different directory types?

## Objective

Create a clear, maintainable directory structure for Claude commands that separates custom and generated content while supporting version control and easy navigation.

## Scope of Work

- **User Experience Scope**: Directory creation and organization workflow
- **System Behavior Scope**: File system operations and structure validation
- **Interface Scope**: Directory structure as documented interface

### Deliverables

#### Behavioral Specifications
- Directory structure design documentation
- Migration strategy for existing commands
- Template format specifications

#### Validation Artifacts
- Directory structure verification checklist
- Permission validation tests
- Migration success criteria

## Out of Scope
- ❌ **Implementation Details**: Specific mkdir commands or script implementation
- ❌ **Technology Decisions**: Choice of scripting language or tools
- ❌ **Performance Optimization**: Directory access optimization
- ❌ **Future Enhancements**: Additional subdirectories or reorganization

## Technical Approach

### Architecture Pattern
- File system organization following convention-over-configuration principle
- Clear separation of concerns between custom and generated content
- Template-based generation system for consistency

### Technology Stack
- Ruby for directory creation and file operations
- ERB templating for command generation templates
- JSON for command registry management

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| FileUtils (Ruby) | Directory creation | Standard library, no dependencies |
| ERB | Template processing | Built-in Ruby templating |
| JSON (Ruby) | Registry management | Standard library for JSON handling |

## File Modifications

### Create
- `dev-handbook/.integrations/claude/commands/_custom/` - Directory for hand-crafted commands
- `dev-handbook/.integrations/claude/commands/_generated/` - Directory for auto-generated commands
- `dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl` - Template for workflow commands
- `dev-handbook/.integrations/claude/templates/agent-command.md.tmpl` - Template for agent commands

### Modify
- `dev-handbook/.integrations/claude/commands/` - Reorganize existing flat structure

### Delete
- None required for initial structure creation

## Risk Assessment

### Technical Risks
- **Existing Command Migration**: Risk of breaking current integrations
  - Mitigation: Create migration script to move existing commands
- **Permission Issues**: Directory creation might fail on some systems
  - Mitigation: Check permissions before operations, provide clear error messages

### Integration Risks
- **Git Tracking**: Generated files might clutter version control
  - Mitigation: Consider .gitignore patterns for _generated directory
- **Command Discovery**: New structure might break existing discovery mechanisms
  - Mitigation: Update commands.json generation to handle new structure

## Implementation Plan

### Planning Steps

* [ ] Analyze current command structure in dev-handbook/.integrations/claude/
* [ ] Document existing commands for migration planning
* [ ] Design template variables and structure for command generation
* [ ] Determine file permission requirements for different directories

### Execution Steps

- [ ] Create base directory structure
  ```bash
  mkdir -p dev-handbook/.integrations/claude/commands/{_custom,_generated}
  mkdir -p dev-handbook/.integrations/claude/templates
  ```
  > TEST: Directory Creation Validation
  > Type: File System Check
  > Assert: All directories exist with correct permissions
  > Command: ls -la dev-handbook/.integrations/claude/commands/

- [ ] Move existing custom commands to _custom directory
  ```bash
  # Move known custom commands
  mv dev-handbook/.integrations/claude/commands/{commit,draft-tasks,plan-tasks,work-on-tasks,review-tasks,load-project-context}.md \
     dev-handbook/.integrations/claude/commands/_custom/
  ```
  > TEST: Custom Command Migration
  > Type: File Existence Check
  > Assert: Custom commands exist in _custom directory
  > Command: ls dev-handbook/.integrations/claude/commands/_custom/

- [ ] Create workflow command template
  ```erb
  # File: dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl
  read whole file and follow @dev-handbook/workflow-instructions/<%= workflow_name %>.wf.md
  
  read and run @.claude/commands/commit.md
  ```

- [ ] Create agent command template
  ```erb
  # File: dev-handbook/.integrations/claude/templates/agent-command.md.tmpl
  Use the <%= agent_name %> agent to <%= agent_purpose %>.
  Context: <%= context_description %>
  <%= additional_parameters %>
  ```

- [ ] Document migration strategy in README
  ```markdown
  # Migration Guide
  - Existing commands moved to _custom/
  - New generated commands will be in _generated/
  - Update your references if using direct paths
  ```

- [ ] Verify git tracking for new structure
  ```bash
  git status dev-handbook/.integrations/claude/
  ```
  > TEST: Version Control Validation
  > Type: Git Status Check
  > Assert: All directories are tracked, no unintended files
  > Command: git ls-files dev-handbook/.integrations/claude/

## Acceptance Criteria

- [ ] Directory structure matches specification exactly
- [ ] All existing commands preserved in appropriate locations
- [ ] Template files created and ready for use
- [ ] No data loss during migration
- [ ] Clear documentation for migration process

## References

- Current Claude integration structure
- Best practices for command organization
- Version control considerations for generated content