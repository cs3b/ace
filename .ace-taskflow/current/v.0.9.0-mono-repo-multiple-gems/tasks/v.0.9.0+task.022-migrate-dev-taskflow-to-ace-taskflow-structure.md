---
id: v.0.9.0+task.022
status: in-progress
priority: high
estimate: 1d
dependencies: [v.0.9.0+task.019]
---

# Migrate dev-taskflow to .ace-taskflow with Improved Structure

## Behavioral Specification

### User Experience
- **Input**: Existing dev-taskflow directory with current/backlog/done structure and long file names
- **Process**: Automated migration preserving git history while reorganizing to cleaner, more navigable structure
- **Output**: New .ace-taskflow directory with simplified paths, organized task folders, and descriptive naming

### Expected Behavior

The migration provides users with a cleaner, more intuitive directory structure:

1. **Simplified Paths**: Release at root level (v.0.9.0 instead of current/v.0.9.0-mono-repo-multiple-gems)
2. **Organized Tasks**: Each task in its own folder (t/NNN/) with descriptive file names
3. **Preserved History**: Full git history maintained through git mv operations
4. **Descriptive Naming**: Files use human-readable names instead of generic "task.md"
5. **Backward Compatible**: ace-taskflow commands continue working with new structure

### Interface Contract

```bash
# Directory structure after migration:
.ace-taskflow/
├── v.0.9.0/                    # Active release at root
│   ├── mono-repo-multiple-gems.md  # Descriptive release doc
│   └── t/
│       ├── 001/
│       │   └── create-minimal-ace-core-gem.md
│       └── 019/
│           ├── implement-ace-taskflow-release-and-task-management-commands.md
│           └── ux.md

# Command compatibility:
ace-taskflow task                    # Works with new structure
ace-taskflow release                 # Finds v.0.9.0 at root
ace-taskflow tasks --all            # Lists from t/NNN/ folders

# File access patterns:
cat .ace-taskflow/v.0.9.0/t/001/create-minimal-ace-core-gem.md
cat .ace-taskflow/v.0.9.0/mono-repo-multiple-gems.md
```

### Success Criteria

- [ ] **Structure Migration**: dev-taskflow successfully moved to .ace-taskflow
- [ ] **Git History**: All file history preserved through git mv operations
- [ ] **Task Organization**: All tasks in t/NNN/ folders with descriptive names
- [ ] **Command Functionality**: ace-taskflow commands work with new structure
- [ ] **No Data Loss**: All files, folders, and metadata preserved
- [ ] **Improved Navigation**: Descriptive names make files easier to find

### Validation Questions

- [ ] Should we update ace-taskflow to prefer descriptive names or keep task.md convention?
- [ ] How to handle future backward compatibility if structure changes again?
- [ ] Should migration script be reusable for done/ releases?

## Objective

Transform the existing dev-taskflow directory structure into the new .ace-taskflow format with improved organization, shorter paths, and descriptive file naming while preserving all git history and ensuring ace-taskflow compatibility.

## Scope of Work

- **Migration Scope**: Complete dev-taskflow directory with focus on current release first
- **Structure Scope**: Reorganize to .ace-taskflow/v.X.Y.Z/t/NNN/ pattern
- **Naming Scope**: Use descriptive file names instead of generic task.md
- **Tool Scope**: Update ace-taskflow to support new naming conventions

### Deliverables

#### Migration Artifacts
- Migration script (migrate-taskflow.sh) with rollback capability
- Updated .ace-taskflow directory structure
- Preserved git history for all files

#### Tool Updates
- Modified ace-taskflow to support descriptive file names
- Updated configuration for new structure
- Backward compatibility layer if needed

## Out of Scope

- ❌ **Content Modification**: No changes to task content, only structure
- ❌ **Task Renumbering**: Keep existing task numbers (001-021+)
- ❌ **Immediate Done Migration**: Focus on current first, done/ releases later
- ❌ **External References**: Don't update references in other documentation yet

## Technical Approach

### Architecture Pattern
Shell script automation using git mv commands in batches to preserve history while reorganizing structure. Modular approach allows partial rollback if issues occur.

### Technology Stack
- Git for version control operations
- Bash scripting for automation
- Ruby for ace-taskflow updates
- File system operations for structure changes

### Implementation Strategy
Three-phase approach:
1. Move entire directory with git mv
2. Reorganize internal structure
3. Update tools for compatibility

## File Modifications

### Create
- migrate-taskflow.sh
  - Purpose: Automate the migration process
  - Key components: Git mv commands, error handling, rollback capability
  - Dependencies: Git, bash, file system access

### Modify
- ace-taskflow/lib/ace/taskflow/molecules/task_loader.rb
  - Changes: Support loading any .md file from task directories, not just task.md
  - Impact: Enables descriptive file names
  - Integration points: Path resolution, file discovery

- ace-taskflow/lib/ace/taskflow/atoms/path_builder.rb
  - Changes: Handle descriptive file names in path construction
  - Impact: Supports new naming convention
  - Integration points: Task reference resolution

- .ace/taskflow.yml
  - Changes: Update root configuration to .ace-taskflow
  - Impact: Points tools to new location
  - Integration points: All ace-taskflow commands

## Risk Assessment

### Technical Risks
- **Risk:** Git history loss during migration
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Use git mv exclusively, test on branch first
  - **Rollback:** Keep backup branch, can reset if needed

### Integration Risks
- **Risk:** ace-taskflow incompatibility with new structure
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Update gem before migration, extensive testing
  - **Monitoring:** Run test suite after each phase

## Implementation Plan

### Planning Steps

* [x] Analyze current dev-taskflow structure
  - Document all directories and special cases
  - Identify tasks with subfolders (018, 019, 021)
  - Plan naming conventions

* [x] Design target .ace-taskflow structure
  - Define path patterns
  - Choose descriptive naming approach
  - Plan backward compatibility

* [x] Create migration sequence
  - Order operations for atomic commits
  - Plan error handling
  - Design rollback strategy

### Execution Steps

- [ ] Create migration script
  - [ ] Write phase 1: Full directory move
  - [ ] Write phase 2: Release reorganization
  - [ ] Write phase 3: Task restructuring
  - [ ] Add error handling and validation
  > TEST: Script dry run
  > Type: Shell execution
  > Assert: All paths resolve correctly
  > Command: ./migrate-taskflow.sh --dry-run

- [ ] Update ace-taskflow gem
  - [ ] Modify task_loader for flexible file names
  - [ ] Update path_builder patterns
  - [ ] Add configuration options
  - [ ] Test with sample structure
  > TEST: Gem functionality
  > Type: Ruby unit tests
  > Assert: Commands work with new structure
  > Command: bundle exec rake test

- [ ] Execute migration
  - [ ] Create backup branch
  - [ ] Run phase 1: Move dev-taskflow
  - [ ] Run phase 2: Reorganize releases
  - [ ] Run phase 3: Restructure tasks
  - [ ] Verify file locations
  > TEST: Migration validation
  > Type: File system check
  > Assert: All files present at new locations
  > Command: find .ace-taskflow -name "*.md" | wc -l

- [ ] Post-migration validation
  - [ ] Test ace-taskflow commands
  - [ ] Verify git history preserved
  - [ ] Check for broken references
  - [ ] Update documentation
  > TEST: Command functionality
  > Type: Integration test
  > Assert: All commands work
  > Command: ace-taskflow task && ace-taskflow release

## Acceptance Criteria

- [ ] Migration completes without errors
- [ ] All files accessible at new locations with descriptive names
- [ ] Git history fully preserved (verify with git log --follow)
- [ ] ace-taskflow commands functional with new structure
- [ ] No broken references or missing files
- [ ] Documentation updated to reflect new structure
- [ ] Rollback procedure documented and tested

## References

- Current dev-taskflow structure analysis
- ace-taskflow implementation (task 019)
- Git mv documentation for history preservation
- Shell scripting best practices for migration scripts