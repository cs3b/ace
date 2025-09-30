---
id: v.0.9.0+task.024
status: done
priority: high
estimate: 4h
dependencies: []
---

# Migrate Taskflow Workflows to ace-taskflow Gem

## Behavioral Specification

### User Experience
Enable users to access taskflow-related workflows directly from the installed ace-taskflow gem. Workflows will be discoverable through the wfi-sources protocol system, and all task and release management workflows will work seamlessly with ace-taskflow commands.

### Interface Contract

Users interact with workflows via ace-taskflow commands:
```bash
# Task management
ace-taskflow task create "Task Title"       # Creates task and returns path
ace-taskflow task [id]                      # Navigate to task (supports task.021, v.0.9.0+021, 021)
ace-taskflow tasks --status pending         # List tasks

# Release management
ace-taskflow release create                 # Create new release
ace-taskflow release                        # Show current release

# Idea capture
ace-taskflow idea "New idea"               # Capture ideas
```

### Success Criteria

- [x] All 12 workflow files successfully moved to ace-taskflow/handbook/workflow-instructions/
- [x] Workflows discoverable via wfi-sources protocol with type: gem
- [x] All path references updated from dev-taskflow/ to .ace-taskflow/
- [x] All command references updated to use ace-taskflow equivalents
- [x] Workflows remain self-contained per ADR-001
- [x] Tests pass with new workflow locations
- [x] Git-commit from dev-tools still works
- [x] Standard git commands (mv, push) work correctly

## Validation Questions

- [ ] Should we implement `ace-taskflow reflection create` for reflection workflows?
- [ ] How should create-path file creation be handled in the new structure?
- [ ] Should nav-path functionality be fully integrated into ace-taskflow task command?
- [ ] Do we need to maintain backward compatibility with old commands during transition?

## Workflows to Migrate

1. capture-idea.wf.md - Idea capture workflow
2. create-reflection-note.wf.md - Reflection note creation
3. draft-release.wf.md - Release drafting
4. draft-task.wf.md - Task drafting
5. plan-task.wf.md - Task planning
6. publish-release.wf.md - Release publication
7. replan-cascade-task.wf.md - Cascade task replanning
8. review-code.wf.md - Code review
9. review-questions.wf.md - Question review
10. review-task.wf.md - Task review
11. work-on-task.wf.md - Task execution
12. create-task-based-on-plan.md - Task creation from plan (from .integrations/claude/commands/_custom/)
    - Note: This workflow needs expansion from its current minimal form
    - Should be converted to full .wf.md format during migration

## Implementation Plan

### Phase 1: Setup Directory Structure
1. Create handbook directory hierarchy in ace-taskflow:
   ```bash
   mkdir -p ace-taskflow/handbook/workflow-instructions
   mkdir -p ace-taskflow/.ace.example/protocols/wfi-sources
   ```

### Phase 2: Create Protocol Configuration
2. Create wfi-sources protocol file:
   - Path: `ace-taskflow/.ace.example/protocols/wfi-sources/ace-taskflow.yml`
   - Set type: gem for proper discovery
   - Configure path to handbook/workflow-instructions/

### Phase 3: Move Workflow Files
3. Use git mv to relocate all 12 workflow files:
   ```bash
   # Move the 11 main workflow files
   git mv dev-handbook/workflow-instructions/{capture-idea,create-reflection-note,draft-release,draft-task,plan-task,publish-release,replan-cascade-task,review-code,review-questions,review-task,work-on-task}.wf.md ace-taskflow/handbook/workflow-instructions/

   # Move the custom command workflow
   git mv dev-handbook/.integrations/claude/commands/_custom/create-task-based-on-plan.md ace-taskflow/handbook/workflow-instructions/create-task-based-on-plan.wf.md
   ```

### Phase 4: Update Path References
4. Global find/replace in all moved workflows:
   - `dev-taskflow/` → `.ace-taskflow/`
   - `dev-taskflow/backlog/` → `.ace-taskflow/backlog/`
   - `dev-taskflow/current/` → `.ace-taskflow/current/`
   - `dev-taskflow/done/` → `.ace-taskflow/done/`

### Phase 5: Update Command References
5. Replace tool commands systematically:

   **Task Management:**
   - `task-manager create --release v.X.Y.Z --title "Task"` → `ace-taskflow task create "Task"`
   - `task-manager next` → `ace-taskflow task`
   - `task-manager list` → `ace-taskflow tasks`
   - `nav-path file v.0.4.0+task.4` → `ace-taskflow task v.0.4.0+004`
   - `nav-path file task.21` → `ace-taskflow task 021`

   **Release Management:**
   - `release-manager draft` → `ace-taskflow release create`
   - `release-manager current` → `ace-taskflow release`

   **Idea Management:**
   - `capture-it "idea"` → `ace-taskflow idea "idea"`

   **Git Operations (keep existing):**
   - `git-commit -i` remains unchanged (from dev-tools)
   - `git-mv` → `git mv` (standard git)
   - `git-push` → `git push` (standard git)

   **File Operations:**
   - `create-path file "path" --template` → Direct file creation (future ace-taskflow feature)
   - `create-path file:reflection-new` → Note for future `ace-taskflow reflection create`

### Phase 6: Documentation
6. Create supporting documentation:
   - `ace-taskflow/handbook/README.md` - Overview and usage guide
   - Document command mappings
   - Note integration points with dev-tools

### Phase 7: Testing
7. Validate migration:
   - Test ace-taskflow command discovery
   - Verify wfi-sources protocol works
   - Confirm git-commit from dev-tools still functions
   - Run workflow execution tests

## Technical Architecture

### Files to Create:
- `ace-taskflow/handbook/workflow-instructions/` (directory)
- `ace-taskflow/.ace.example/protocols/wfi-sources/ace-taskflow.yml`
- `ace-taskflow/handbook/README.md`

### Files to Modify:
- All 12 workflow .wf.md files (path and command updates)

### Files to Delete:
- Original workflow files in dev-handbook (via git mv)

## Risk Assessment

### Low Risk:
- Directory structure creation
- Git mv operations (reversible)
- Documentation updates

### Medium Risk:
- Command reference updates (may miss some occurrences)
- Path reference updates (systematic search required)
- Template embedding preservation

### High Risk:
- Breaking existing workflows if commands not properly mapped
- Missing integration points with dev-tools

### Mitigation Strategy:
1. Create comprehensive test checklist
2. Test each workflow individually after migration
3. Keep backup of original structure
4. Implement in phases with validation between each

## Rollback Procedure

If issues arise:
1. `git reset --hard` to previous commit
2. Restore original workflow locations
3. Document specific failure points
4. Adjust migration plan based on findings

## Dependencies

- ace-taskflow gem must be functional
- dev-tools git-commit must remain available
- .ace/protocols/wfi-sources system must be active

## Testing Strategy

Since this is a workflow/documentation task, traditional code testing doesn't apply. Instead:

### Validation Tests:
1. Verify all files moved successfully
2. Test workflow discovery via wfi-sources
3. Execute sample commands from each workflow
4. Confirm ace-taskflow commands work as expected
5. Validate git-commit integration remains functional

### Integration Tests:
1. Run a complete task lifecycle (draft → plan → work → complete)
2. Test release creation and management
3. Verify idea capture workflow
4. Test reflection note creation (if implemented)
