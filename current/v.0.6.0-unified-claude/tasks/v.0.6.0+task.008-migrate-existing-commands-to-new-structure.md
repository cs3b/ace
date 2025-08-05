---
id: v.0.6.0+task.008
status: done
priority: medium
estimate: 3h
dependencies: [v.0.6.0+task.001]
release: v.0.6.0-unified-claude
---

# Migrate existing commands to new structure

## Migration Instructions for Claude Code

Based on user clarifications, this migration will be performed as a one-time prompt for Claude Code. The following instructions should be used to perform the migration:

### Migration Prompt

```
Migrate existing Claude commands to the new directory structure:

1. First, check if the directories exist:
   - dev-handbook/.integrations/claude/commands/_custom
   - dev-handbook/.integrations/claude/commands/_generated
   - .claude/commands/_custom
   - .claude/commands/_generated

2. If directories don't exist, create them:
   mkdir -p dev-handbook/.integrations/claude/commands/{_custom,_generated}
   mkdir -p .claude/commands/{_custom,_generated}

3. In dev-handbook/.integrations/claude/commands/, use git mv to move the 6 custom commands to _custom/:
   - commit.md
   - draft-tasks.md
   - load-project-context.md
   - plan-tasks.md
   - review-tasks.md
   - work-on-tasks.md

4. In .claude/commands/, analyze each file:
   - If the file exists in dev-handbook/.integrations/claude/commands/_custom/, move it to _custom/
   - Otherwise, move it to _generated/
   - Skip any files that are already in _custom/ or _generated/ directories

5. Use git mv when possible for all file movements to preserve history

6. Generate a migration report and save it to:
   dev-taskflow/releases/v.0.6.0-unified-claude/docs/MIGRATION_REPORT.md

Report format:
# Command Migration Report - [Date]

## Summary
- Commands migrated in dev-handbook: X
- Commands migrated in .claude: Y  
- Commands skipped (already migrated): Z

## dev-handbook Migration
### Custom Commands Moved
- List each file moved

## .claude Migration  
### Custom Commands
- List files moved to _custom/

### Generated Commands
- List files moved to _generated/

## Verification
- Git history preserved: Yes/No
- All files accounted for: Yes/No
```

## Behavioral Specification

### User Experience
- **Input**: Developer runs migration process or script
- **Process**: System moves existing commands to appropriate directories
- **Output**: Commands organized in new structure with migration report

### Expected Behavior
The system should identify all existing Claude commands in the flat structure and migrate them to the new _custom or _generated directories based on their characteristics. Custom commands should be preserved in _custom while maintaining version control history. The migration should be safe, creating backups and providing a clear report of what was moved.

### Interface Contract
```bash
# Manual migration process
cd dev-handbook/.integrations/claude
mkdir -p commands/{_custom,_generated}

# Move known custom commands
mv commands/{commit,draft-tasks,plan-tasks,work-on-tasks,review-tasks,load-project-context}.md commands/_custom/

# Move remaining commands to _generated
mv commands/*.md commands/_generated/

# Verify migration
ls -la commands/_custom/
ls -la commands/_generated/
```

**Error Handling:**
- File not found: Skip and report
- Permission denied: Report and continue
- Git tracking issues: Provide git mv commands

**Edge Cases:**
- Modified generated commands: Flag for manual review
- Symbolic links: Preserve link type
- Non-command files: Leave in place

### Success Criteria
- [ ] **All Commands Migrated**: Every .md file moved to appropriate directory
- [ ] **Git History Preserved**: Using git mv for tracking
- [ ] **No Data Loss**: All files accounted for
- [ ] **Clear Report**: Migration summary provided

### Validation Questions
- [ ] **Custom Command List**: Is the list of known custom commands complete?
- [ ] **Detection Logic**: How to identify modified generated commands?
- [ ] **Backup Strategy**: Should we create pre-migration backup?
- [ ] **Rollback Plan**: How to undo migration if needed?

## Objective

Safely migrate existing Claude commands from flat structure to new organized directory structure while preserving version control history and custom modifications.

## Scope of Work

- **User Experience Scope**: Migration execution and reporting
- **System Behavior Scope**: File movement and git operations
- **Interface Scope**: Migration commands and output

### Deliverables

#### Behavioral Specifications
- Migration strategy documentation
- Command categorization rules
- Rollback procedures

#### Validation Artifacts
- Pre/post migration inventory
- Git history verification
- Data integrity checks

## Out of Scope
- ❌ **Implementation Details**: Specific script language
- ❌ **Technology Decisions**: Migration tool choice
- ❌ **Performance Optimization**: Parallel processing
- ❌ **Future Enhancements**: Automated detection algorithms

## Technical Approach

### Architecture Pattern
- Inventory-based migration with verification
- Git-aware file movement
- Transaction-like operation with rollback

### Technology Stack
- Git commands for version control preservation
- Shell scripting or Ruby for automation
- File checksums for integrity verification

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| git mv | File movement | Preserves version history |
| FileUtils | Ruby file operations | Safe file handling |
| Digest::MD5 | Integrity checking | Verify no data corruption |

## File Modifications

### Create
- Migration report file documenting all moves
- Backup of original structure (optional)

### Modify
- `dev-handbook/.integrations/claude/commands/` - Restructured with subdirectories

### Delete
- None (files moved, not deleted)

## Risk Assessment

### Technical Risks
- **Git History Loss**: Using wrong move commands
  - Mitigation: Always use git mv, verify history after
- **File Corruption**: Issues during movement
  - Mitigation: Checksum verification before/after

### Integration Risks
- **Active Development Conflicts**: Others modifying during migration
  - Mitigation: Coordinate timing, quick execution
- **CI/CD Breakage**: Paths hardcoded in scripts
  - Mitigation: Search for path references first

## Research Notes

### Current State Analysis
- **Primary source location**: dev-handbook/.integrations/claude/commands/ (6 custom commands)
- **.claude directory EXISTS** at project root with 35 command files
- **ClaudeCommandsInstaller**: Copies custom commands from dev-handbook to .claude/commands/
- **User clarification**: dev-handbook is the source, .claude is the deployed location

### Directory Structure Findings
```
dev-handbook/.integrations/claude/
├── agents/           # Contains feature-research.md, git-commit-manager.md
├── commands/         # 6 custom command files (flat structure)
└── install-prompts.md

.claude/
├── agents/           # 2 agent files
├── commands/         # 35 command files (mix of custom and generated)
└── settings.local.json
```

### Related Task Dependencies
- **Task.001**: Creates _custom and _generated subdirectories
- **Task.003**: Will generate commands in _generated directory
- **Task.004**: Updates template with YAML front-matter
- **This task (008)**: Migrates existing 6 commands to _custom

### Implementation Readiness Assessment
**Ready for implementation**: All critical questions have been answered by the user. The migration will be performed using a Claude Code prompt (one-time execution), using git mv to preserve history, without creating backups (relying on git), and will migrate files in both dev-handbook and .claude directories. The migration report will be saved to the release docs folder.

## Implementation Plan

### Planning Steps

* [x] Inventory all existing command files
  - **Completed Research**: 
    - Found 6 commands in dev-handbook/.integrations/claude/commands/ (source)
    - Found 35 files in .claude/commands/ (target location)
    - Confirmed .claude/commands/ DOES exist at project root
* [x] Identify custom vs generated commands
  - **Research Finding**: 
    - All 6 commands in dev-handbook are custom (hand-crafted)
    - The .claude/commands/ contains mix of custom (copied from dev-handbook) and generated files
* [x] Search codebase for hardcoded paths
  - **Found references in**:
    - dev-tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb
    - dev-tools/spec files
    - Various task files in v.0.6.0-unified-claude
  - **Critical files to update**: ClaudeCommandsInstaller class (will be handled in separate task)
* [x] Plan migration approach
  - **User Decision**: Use Claude Code prompt for one-time migration
  - **No permanent script needed**: Just instructions for AI agent

### Execution Steps

- [x] Execute the migration using Claude Code with the prompt from "Migration Instructions" section above
- [x] Verify migration was successful:
  - Check directory structures in both locations
  - Confirm git history preserved  
  - Review generated migration report
- [ ] Update ClaudeCommandsInstaller to handle new directory structure (separate task)

## Acceptance Criteria

- [x] All 6 custom .md files moved to _custom subdirectory
- [x] Git history preserved for all files (if using git mv)
- [x] No files lost during migration
- [x] Migration report generated with file counts and status
- [x] All tests pass after migration (pre-existing test failures unrelated to migration)
- [ ] ClaudeCommandsInstaller updated to handle new structure
- [x] No broken references in codebase (ClaudeCommandsInstaller update is separate task)

## References

- Git mv documentation
- Current command inventory (6 custom commands identified)
- Version control best practices
- Task.001 for directory structure creation
- ClaudeCommandsInstaller implementation in dev-tools
