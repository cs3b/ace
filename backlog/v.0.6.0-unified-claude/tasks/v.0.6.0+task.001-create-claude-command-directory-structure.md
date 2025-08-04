---
id: v.0.6.0+task.001
status: pending
priority: high
estimate: 2h
dependencies: []
release: v.0.6.0-unified-claude
needs_review: true
---

# Create Claude command directory structure

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Which location should be the primary directory for Claude commands?
  - **Research conducted**: Found two existing locations with Claude commands:
    - `/Users/michalczyz/Projects/CodingAgent/handbook-meta/.claude/commands/` (33 commands)
    - `/Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-handbook/.integrations/claude/commands/` (6 commands)
  - **Suggested default**: Use `.claude/commands/` at project root as primary location
  - **Why needs human input**: Two existing structures conflict - need decision on consolidation strategy

  > the primary is dev-handbook/.integrations/claude/commands/, .claude/commands/ its just duplication from shared project dev-handbook

- [ ] Should we consolidate commands from both locations or maintain dual structure?
  - **Research conducted**: Root `.claude/commands/` has more complete set; dev-handbook location has subset
  - **Suggested default**: Consolidate all commands into root `.claude/commands/` with new subdirectory structure
  - **Why needs human input**: Architectural decision affecting all future Claude integration

  > we are maintaining dev-handbook (installation script will allow to duplicate them for the project purpose)

- [ ] How should existing commands.json be migrated to support the new structure?
  - **Research conducted**: Current commands.json uses flat structure with path-based keys
  - **Current format**: `{"/command-name": {config}}`
  - **Suggested default**: Add `type: "custom"|"generated"` field to each command entry
  - **Why needs human input**: Breaking change to existing format needs approval

  > command.json should be only in .claude directory (its part of installing commands to claude) we don't need info custom or generated

### [MEDIUM] Enhancement Questions
- [ ] Should generated commands be tracked in version control or added to .gitignore?
  - **Research conducted**: No current .gitignore patterns for Claude directories
  - **Suggested default**: Add `.claude/commands/_generated/` to .gitignore
  - **Why needs human input**: Version control strategy affects collaboration

> we do not create folder .claude/commands/_generated/ - we only modify dev-handbook (and yes all the files are tracked there by github)

- [ ] What naming convention should distinguish custom vs generated commands in commands.json?
  - **Research conducted**: Current commands use simple slash-prefixed names
  - **Suggested default**: Keep existing names, add metadata field for type
  - **Why needs human input**: Affects command discovery and tooling

> no (command is command, sync script that is responsibility of task-003 will take care about it)

### [LOW] Implementation Details
- [ ] Should we preserve the dev-handbook/.integrations/claude structure for backward compatibility?
  - **Research conducted**: Only 6 commands in this location vs 33 in root
  - **Suggested default**: Deprecate but preserve with symlinks to new location
  - **Why needs human input**: Migration timeline and compatibility requirements

> yes we should keep evertything that is related to claude integration in this directory

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
  - **Resolved through research**: Commands exist in two locations; need consolidation
- [ ] **Naming Convention**: Should underscore prefix (_custom, _generated) be used or alternative?
  - **Resolved through research**: Underscore prefix appropriate for directory sorting
- [ ] **Template Format**: What variables and structure should templates support?
  - **Partially resolved**: Basic variables identified (workflow_name, agent_name, etc.)
- [ ] **Permissions**: What file permissions should be set for different directory types?
  - **Resolved through research**: Standard 755 for directories, 644 for files

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
- `.claude/commands/_custom/` - Directory for hand-crafted commands (PRIMARY LOCATION)
- `.claude/commands/_generated/` - Directory for auto-generated commands
- `.claude/templates/workflow-command.md.tmpl` - Template for workflow commands
- `.claude/templates/agent-command.md.tmpl` - Template for agent commands
- **Alternative if dev-handbook preferred**:
  - `dev-handbook/.integrations/claude/commands/_custom/` - Directory for hand-crafted commands
  - `dev-handbook/.integrations/claude/commands/_generated/` - Directory for auto-generated commands
  - `dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl` - Template for workflow commands
  - `dev-handbook/.integrations/claude/templates/agent-command.md.tmpl` - Template for agent commands

### Modify
- `.claude/commands/` - Reorganize existing flat structure (33 files to migrate)
- `.claude/commands/commands.json` - Update registry format to support command types
- `dev-handbook/.integrations/claude/commands/` - Deprecate or create symlinks

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

* [x] Analyze current command structure in dev-handbook/.integrations/claude/
  - **Completed Research**: Found 6 commands in dev-handbook location
  - Commands: commit.md, draft-tasks.md, load-project-context.md, plan-tasks.md, review-tasks.md, work-on-tasks.md
  - All appear to be custom hand-crafted commands
* [x] Document existing commands for migration planning
  - **Root .claude/commands/**: 33 command files plus commands.json registry
  - **dev-handbook location**: 6 command files (subset of root)
  - All current commands appear to be custom (no generated commands yet)
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
  # Primary location at project root
  mkdir -p .claude/commands/{_custom,_generated}
  mkdir -p .claude/templates
  # OR if using dev-handbook location:
  # mkdir -p dev-handbook/.integrations/claude/commands/{_custom,_generated}
  # mkdir -p dev-handbook/.integrations/claude/templates
  ```
  > TEST: Directory Creation Validation
  > Type: File System Check
  > Assert: All directories exist with correct permissions
  > Command: ls -la dev-handbook/.integrations/claude/commands/ | grep "^d" | wc -l | grep -q "2"

- [ ] Update existing commands.json registry format
  ```bash
  # Backup existing registry first
  cp .claude/commands/commands.json .claude/commands/commands.json.bak
  # Update structure to support command types (requires manual JSON transformation)
  # New format should include type field for each command
  ```
  > TEST: Registry File Creation
  > Type: File Content Check
  > Assert: Valid JSON structure exists
  > Command: jq . dev-handbook/.integrations/claude/commands/commands.json

- [ ] Move existing custom commands to _custom directory
  ```bash
  # Move all 33 commands from root location
  cd .claude/commands/
  for cmd in *.md; do
    [ -f "$cmd" ] && mv "$cmd" _custom/
  done

  # Handle dev-handbook location (deprecate or symlink)
  # Option 1: Create symlinks for backward compatibility
  cd dev-handbook/.integrations/claude/commands/
  for cmd in *.md; do
    ln -s ../../../../.claude/commands/_custom/"$cmd" .
  done
  ```
  > TEST: Custom Command Migration
  > Type: File Existence Check
  > Assert: Custom commands exist in _custom directory
  > Command: ls dev-handbook/.integrations/claude/commands/_custom/*.md 2>/dev/null | wc -l

- [ ] Create workflow command template
  ```bash
  cat > .claude/templates/workflow-command.md.tmpl << 'EOF'
read whole file and follow @dev-handbook/workflow-instructions/<%= workflow_name %>.wf.md

read and run @.claude/commands/_custom/commit.md
EOF
  ```
  > TEST: Workflow Template Creation
  > Type: File Content Check
  > Assert: Template contains ERB variables
  > Command: grep -q "<%=" dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl

- [ ] Create agent command template
  ```bash
  cat > .claude/templates/agent-command.md.tmpl << 'EOF'
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
  cat > .claude/commands/MIGRATION.md << 'EOF'
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
  chmod 755 .claude/commands/{_custom,_generated}
  chmod 755 .claude/templates
  chmod 644 .claude/commands/commands.json
  chmod 644 .claude/templates/*.tmpl
  ```
  > TEST: Permission Validation
  > Type: Permission Check
  > Assert: Directories have 755, files have 644
  > Command: stat -f "%Lp" dev-handbook/.integrations/claude/commands/_custom 2>/dev/null || stat -c "%a" dev-handbook/.integrations/claude/commands/_custom

- [ ] Update .gitignore for generated content (if needed)
  ```bash
  # Add to main .gitignore
  if ! grep -q "_generated" .gitignore 2>/dev/null; then
    echo "# Auto-generated Claude commands" >> .gitignore
    echo ".claude/commands/_generated/" >> .gitignore
  fi
  ```
  > TEST: Git Ignore Configuration
  > Type: File Content Check
  > Assert: Generated directory is properly configured
  > Command: grep -q "_generated" dev-handbook/.gitignore || echo "No .gitignore update needed"

- [ ] Verify git tracking for new structure
  ```bash
  git add .claude/commands/_custom/ .claude/templates/
  git status --porcelain .claude/
  ```
  > TEST: Version Control Validation
  > Type: Git Status Check
  > Assert: All directories are tracked, no unintended files
  > Command: git ls-files .claude/ | grep -E "(commands/|templates/)" | wc -l

## Acceptance Criteria

- [ ] Directory structure matches specification exactly
- [ ] All existing commands preserved in appropriate locations
- [ ] Template files created and ready for use
- [ ] No data loss during migration
- [ ] Clear documentation for migration process

## Research Notes

### Current State Analysis
- **Two Claude command locations discovered**:
  1. Root: `.claude/commands/` with 33 command files and commands.json registry
  2. Dev-handbook: `dev-handbook/.integrations/claude/commands/` with 6 command files
- **No existing generated commands** - all current commands are custom/hand-crafted
- **Existing agents location**: Both locations have `agents/` directory
- **No current .gitignore patterns** for Claude directories

### Implementation Readiness
- **Blocked on location decision**: Need to choose between root `.claude/` or `dev-handbook/.integrations/claude/`
- **Migration complexity**: 33 files to reorganize plus registry format update
- **Backward compatibility concern**: Some tools may reference old paths

## References

- Current Claude integration structure
- Best practices for command organization
- Version control considerations for generated content
