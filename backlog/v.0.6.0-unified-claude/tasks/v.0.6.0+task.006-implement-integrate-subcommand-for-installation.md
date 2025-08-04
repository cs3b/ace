---
id: v.0.6.0+task.006
status: draft
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.002, v.0.6.0+task.004]
release: v.0.6.0-unified-claude
---

# Implement integrate subcommand for installation

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude integrate` to install commands into .claude/
- **Process**: System copies all commands and agents to project's .claude/ directory
- **Output**: Confirmation of successful installation with statistics

### Expected Behavior
The system should copy all Claude commands from the dev-handbook structure to the project's .claude/ directory, flattening the _custom and _generated structure. It should also copy agents and update the commands.json registry. The process should be idempotent, handle existing files gracefully, and provide clear feedback about what was installed.

### Interface Contract
```bash
# Full integration
handbook claude integrate
# Output:
Installing Claude commands...

Copying commands:
  ✓ Copied 6 custom commands
  ✓ Copied 19 generated commands
  ✓ Copied 2 agents
  ✓ Updated commands.json

Installation complete:
  Location: .claude/
  Commands: 25
  Agents: 2
  
Run 'claude code' to use the new commands

# Dry run
handbook claude integrate --dry-run
# Output:
Would install:
  Commands:
    - commit.md (custom)
    - draft-tasks.md (custom)
    - capture-idea.md (generated)
    [... list all ...]
  Agents:
    - feature-research.md
    - git-commit-manager.md
  
No changes made

# Integration with backup
handbook claude integrate --backup
# Output:
✓ Backed up existing .claude/ to .claude.backup.20250130-1545/
[Normal installation output]

# Force overwrite
handbook claude integrate --force
# Output:
⚠ Force mode: overwriting existing files
[Normal installation output]

# Integration from custom path
handbook claude integrate --source dev-handbook/.integrations/claude
# Output:
Installing from custom source: dev-handbook/.integrations/claude
[Normal installation output]
```

**Error Handling:**
- Missing source directories: Clear error about what's missing
- Permission denied: Error with sudo suggestion if appropriate
- Disk space issues: Error before starting copy
- Corrupted files: Skip with warning, continue

**Edge Cases:**
- No .claude directory: Create it automatically
- Existing files: Skip unless --force
- Symbolic links: Preserve or resolve based on flag
- Mixed permissions: Handle gracefully

### Success Criteria
- [ ] **Complete Installation**: All commands and agents copied
- [ ] **Registry Update**: commands.json properly updated
- [ ] **Idempotent**: Running twice is safe
- [ ] **Backup Support**: Can preserve existing setup
- [ ] **Clear Feedback**: User knows what was installed

### Validation Questions
- [ ] **File Permissions**: What permissions for installed files?
- [ ] **Symbolic Links**: Should we use symlinks or copies?
- [ ] **Partial Failure**: How to handle mid-install failures?
- [ ] **Version Tracking**: Should we track installed version?

## Objective

Provide a seamless installation experience that copies all Claude integration files from dev-handbook to the project's .claude/ directory, making commands immediately available in Claude Code.

## Scope of Work

- **User Experience Scope**: Installation workflow and feedback
- **System Behavior Scope**: File copying and registry management
- **Interface Scope**: CLI options and installation report

### Deliverables

#### Behavioral Specifications
- Installation process documentation
- File organization rules
- Backup strategy specification

#### Validation Artifacts
- Installation verification tests
- Idempotency tests
- Backup/restore tests

## Out of Scope
- ❌ **Implementation Details**: File copy methods, permission handling
- ❌ **Technology Decisions**: Copy vs symlink implementation
- ❌ **Performance Optimization**: Parallel copying, compression
- ❌ **Future Enhancements**: Incremental updates, versioning

## References

- Claude Code command structure requirements
- File system best practices
- Existing claude-integrate script behavior