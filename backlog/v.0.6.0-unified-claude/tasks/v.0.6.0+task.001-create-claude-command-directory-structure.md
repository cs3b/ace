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
  - Review existing commands directory for custom commands
  - Check for any generated commands or patterns
  - Document current file organization
* [ ] Document existing commands for migration planning
  - List all .md files in commands directory
  - Categorize as custom vs potentially generated
  - Identify any special cases or dependencies
* [ ] Design template variables and structure for command generation
  - Define workflow command template variables: workflow_name, workflow_path
  - Define agent command template variables: agent_name, agent_purpose, context_description
  - Plan additional_parameters structure for flexibility
* [ ] Determine file permission requirements for different directories
  - Standard 755 for directories
  - Standard 644 for files
  - Consider if _generated needs different permissions

### Execution Steps

- [ ] Create base directory structure
  ```bash
  mkdir -p dev-handbook/.integrations/claude/commands/{_custom,_generated}
  mkdir -p dev-handbook/.integrations/claude/templates
  ```
  > TEST: Directory Creation Validation
  > Type: File System Check
  > Assert: All directories exist with correct permissions
  > Command: ls -la dev-handbook/.integrations/claude/commands/ | grep "^d" | wc -l | grep -q "2"

- [ ] Create initial commands.json registry file
  ```bash
  echo '{"version": "1.0.0", "custom_commands": [], "generated_commands": []}' > dev-handbook/.integrations/claude/commands/commands.json
  ```
  > TEST: Registry File Creation
  > Type: File Content Check
  > Assert: Valid JSON structure exists
  > Command: jq . dev-handbook/.integrations/claude/commands/commands.json

- [ ] Move existing custom commands to _custom directory
  ```bash
  # Check for existing commands first
  if ls dev-handbook/.integrations/claude/commands/*.md 2>/dev/null; then
    # Move known custom commands
    for cmd in commit draft-tasks plan-tasks work-on-tasks review-tasks load-project-context; do
      [ -f "dev-handbook/.integrations/claude/commands/${cmd}.md" ] && \
      mv "dev-handbook/.integrations/claude/commands/${cmd}.md" \
         "dev-handbook/.integrations/claude/commands/_custom/"
    done
  fi
  ```
  > TEST: Custom Command Migration
  > Type: File Existence Check
  > Assert: Custom commands exist in _custom directory
  > Command: ls dev-handbook/.integrations/claude/commands/_custom/*.md 2>/dev/null | wc -l

- [ ] Create workflow command template
  ```bash
  cat > dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl << 'EOF'
read whole file and follow @dev-handbook/workflow-instructions/<%= workflow_name %>.wf.md

read and run @.claude/commands/commit.md
EOF
  ```
  > TEST: Workflow Template Creation
  > Type: File Content Check
  > Assert: Template contains ERB variables
  > Command: grep -q "<%=" dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl

- [ ] Create agent command template
  ```bash
  cat > dev-handbook/.integrations/claude/templates/agent-command.md.tmpl << 'EOF'
Use the <%= agent_name %> agent to <%= agent_purpose %>.
Context: <%= context_description %>
<%= additional_parameters %>
EOF
  ```
  > TEST: Agent Template Creation
  > Type: File Content Check
  > Assert: Template contains all required variables
  > Command: grep -c "<%=" dev-handbook/.integrations/claude/templates/agent-command.md.tmpl | grep -q "4"

- [ ] Create migration documentation
  ```bash
  cat > dev-handbook/.integrations/claude/commands/MIGRATION.md << 'EOF'
# Claude Commands Directory Structure Migration

## Overview
Commands are now organized into subdirectories:
- `_custom/` - Hand-crafted commands maintained manually
- `_generated/` - Auto-generated commands from workflows and agents

## Migration Steps Completed
1. Created new directory structure
2. Moved existing commands to `_custom/`
3. Created template files for command generation
4. Set up commands.json registry

## Updating References
If you have direct references to command files, update paths:
- Old: `@.claude/commands/commit.md`
- New: `@.claude/commands/_custom/commit.md`

Note: The integration system will handle path resolution automatically.
EOF
  ```
  > TEST: Migration Documentation
  > Type: File Existence Check
  > Assert: Migration guide exists
  > Command: test -f dev-handbook/.integrations/claude/commands/MIGRATION.md

- [ ] Set proper file permissions
  ```bash
  chmod 755 dev-handbook/.integrations/claude/commands/{_custom,_generated}
  chmod 755 dev-handbook/.integrations/claude/templates
  chmod 644 dev-handbook/.integrations/claude/commands/commands.json
  chmod 644 dev-handbook/.integrations/claude/templates/*.tmpl
  ```
  > TEST: Permission Validation
  > Type: Permission Check
  > Assert: Directories have 755, files have 644
  > Command: stat -f "%Lp" dev-handbook/.integrations/claude/commands/_custom 2>/dev/null || stat -c "%a" dev-handbook/.integrations/claude/commands/_custom

- [ ] Update .gitignore for generated content (if needed)
  ```bash
  # Check if .gitignore needs updating
  if ! grep -q "_generated" dev-handbook/.gitignore 2>/dev/null; then
    echo "# Auto-generated Claude commands" >> dev-handbook/.gitignore
    echo ".integrations/claude/commands/_generated/*.md" >> dev-handbook/.gitignore
  fi
  ```
  > TEST: Git Ignore Configuration
  > Type: File Content Check
  > Assert: Generated directory is properly configured
  > Command: grep -q "_generated" dev-handbook/.gitignore || echo "No .gitignore update needed"

- [ ] Verify git tracking for new structure
  ```bash
  cd dev-handbook && git add .integrations/claude/commands/ .integrations/claude/templates/
  git status --porcelain .integrations/claude/
  ```
  > TEST: Version Control Validation
  > Type: Git Status Check
  > Assert: All directories are tracked, no unintended files
  > Command: cd dev-handbook && git ls-files .integrations/claude/ | grep -E "(commands/|templates/)" | wc -l

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