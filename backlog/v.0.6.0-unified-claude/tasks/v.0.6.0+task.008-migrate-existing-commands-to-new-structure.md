---
id: v.0.6.0+task.008
status: pending
priority: medium
estimate: 3h
dependencies: [v.0.6.0+task.001]
release: v.0.6.0-unified-claude
---

# Migrate existing commands to new structure

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

## Implementation Plan

### Planning Steps

* [ ] Inventory all existing command files
* [ ] Identify custom vs generated commands
* [ ] Search codebase for hardcoded paths
* [ ] Plan migration timing with team

### Execution Steps

- [ ] Create migration checklist
  ```markdown
  # Migration Checklist
  - [ ] All team members notified
  - [ ] No active PRs modifying commands
  - [ ] Full backup created
  - [ ] Git status clean
  ```

- [ ] Perform pre-migration inventory
  ```bash
  find dev-handbook/.integrations/claude/commands -name "*.md" | sort > pre-migration.txt
  wc -l pre-migration.txt
  ```
  > TEST: File Count Verification
  > Type: Manual Check
  > Assert: Count matches expected number
  > Command: wc -l pre-migration.txt

- [ ] Create directory structure (if not exists)
  ```bash
  mkdir -p dev-handbook/.integrations/claude/commands/{_custom,_generated}
  ```

- [ ] Migrate custom commands with git
  ```bash
  cd dev-handbook/.integrations/claude
  git mv commands/commit.md commands/_custom/
  git mv commands/draft-tasks.md commands/_custom/
  git mv commands/plan-tasks.md commands/_custom/
  git mv commands/work-on-tasks.md commands/_custom/
  git mv commands/review-tasks.md commands/_custom/
  git mv commands/load-project-context.md commands/_custom/
  ```
  > TEST: Git History Preservation
  > Type: Git Log Check
  > Assert: History follows file
  > Command: git log --follow commands/_custom/commit.md

- [ ] Migrate remaining commands to _generated
  ```bash
  for file in commands/*.md; do
    if [ -f "$file" ]; then
      git mv "$file" commands/_generated/
    fi
  done
  ```

- [ ] Verify migration completeness
  ```bash
  find dev-handbook/.integrations/claude/commands -name "*.md" | sort > post-migration.txt
  diff pre-migration.txt post-migration.txt
  ```
  > TEST: Migration Completeness
  > Type: File Comparison
  > Assert: All files accounted for
  > Command: diff pre-migration.txt post-migration.txt

- [ ] Update any hardcoded references
  ```bash
  # Search for old paths
  grep -r "commands/commit.md" . --include="*.rb" --include="*.md"
  # Update found references
  ```

- [ ] Create migration report
  ```markdown
  # Migration Report - [Date]
  
  ## Summary
  - Custom commands moved: 6
  - Generated commands moved: X
  - Total files migrated: Y
  
  ## Custom Commands
  - commit.md
  - draft-tasks.md
  - plan-tasks.md
  - work-on-tasks.md  
  - review-tasks.md
  - load-project-context.md
  
  ## Issues
  - None encountered
  
  ## Verification
  - Git history preserved: ✓
  - All files accounted for: ✓
  - No broken references: ✓
  ```

## Acceptance Criteria

- [ ] All .md files moved to appropriate subdirectories
- [ ] Git history preserved for all files
- [ ] No files lost during migration
- [ ] Migration report generated
- [ ] All tests pass after migration
- [ ] No broken references in codebase

## References

- Git mv documentation
- Current command inventory
- Version control best practices