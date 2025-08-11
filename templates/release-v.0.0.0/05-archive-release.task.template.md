---
id: TEMPLATE-task.5 # TEMPLATE - Replace with actual task ID using task-manager generate-id
status: pending
priority: medium
estimate: 0.5h
dependencies: [TEMPLATE-task.4]
---

# TEMPLATE: Archive Completed v.0.0.0 Release

**TEMPLATE NOTE:** This is a template task file. When copying to an actual project:

1. Replace "TEMPLATE" with actual project-specific task ID (use `task-manager generate-id v.0.0.0`)
2. Replace dependency IDs with actual task IDs
3. Remove this template note section
4. Customize content for specific project needs

## Objective

Archive the completed v.0.0.0 bootstrap release by moving it from dev-taskflow/current/ to dev-taskflow/done/ and updating project status to reflect the completion of the foundational setup phase. This signals readiness to begin planning and implementing v.0.1.0 foundation release.

## Scope of Work

### Deliverables

#### Create

- None

#### Modify

- Project status indicators (if applicable)
- Release tracking documentation

#### Delete

- dev-taskflow/current/v.0.0.0-bootstrap/ (moved to done/)

## Phases

1. Completion Verification - Ensure all v.0.0.0 tasks are complete
2. Archive Preparation - Prepare release directory for archival
3. Directory Move - Transfer release from current to done
4. Status Update - Update project tracking and documentation

## Implementation Plan

### Planning Steps

- [ ] Verify all v.0.0.0 tasks are marked as complete
  > TEST: Task Completion Verification
  > Type: Pre-condition Check
  > Assert: All tasks in v.0.0.0 release are marked as done
  > Command: task-manager recent v.0.0.0 | grep -v "done" | wc -l | grep -q "^0$"
- [ ] Confirm all acceptance criteria for v.0.0.0 release are met
  > TEST: Acceptance Criteria Check
  > Type: Pre-condition Check
  > Assert: v.0.0.0 release overview shows all acceptance criteria completed
  > Command: grep -A 20 "## Acceptance Criteria" dev-taskflow/current/v.0.0.0-bootstrap/v.0.0.0-setup-docs-dev.md | grep -c "\- \[x\]"

### Execution Steps

- [ ] Update v.0.0.0 release status to "Done" in overview document
  > TEST: Release Status Update
  > Type: Action Validation
  > Assert: v.0.0.0 release overview marked as Done
  > Command: grep -q "Status.*Done" dev-taskflow/current/v.0.0.0-bootstrap/v.0.0.0-setup-docs-dev.md
- [ ] Add completion date to v.0.0.0 release information
  > TEST: Completion Date Added
  > Type: Action Validation
  > Assert: Release completion date is documented
  > Command: grep -q "Release Date.*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" dev-taskflow/current/v.0.0.0-bootstrap/v.0.0.0-setup-docs-dev.md
- [ ] Move v.0.0.0 release directory from current/ to done/
  > TEST: Directory Move Complete
  > Type: Action Validation
  > Assert: v.0.0.0 release moved to done directory
  > Command: test -d dev-taskflow/done/v.0.0.0-bootstrap && test ! -d dev-taskflow/current/v.0.0.0-bootstrap
- [ ] Update project roadmap to reflect v.0.0.0 completion
  > TEST: Roadmap Updated
  > Type: Action Validation
  > Assert: roadmap shows v.0.0.0 as completed
  > Command: grep -q "v\.0\.0\.0.*[Cc]omplete\|v\.0\.0\.0.*[Dd]one" dev-taskflow/roadmap.md
- [ ] Verify project is ready for v.0.1.0 planning
  > TEST: v.0.1.0 Readiness
  > Type: Post-condition Check
  > Assert: All prerequisites for v.0.1.0 planning are in place
  > Command: test -f dev-taskflow/roadmap.md && test -f PRD.md && test -d dev-taskflow/current

## Acceptance Criteria

- [ ] AC 1: All v.0.0.0 tasks verified as complete
- [ ] AC 2: v.0.0.0 release status updated to "Done" with completion date
- [ ] AC 3: v.0.0.0 release directory successfully moved to dev-taskflow/done/
- [ ] AC 4: Project roadmap updated to reflect v.0.0.0 completion
- [ ] AC 5: Project structure ready for v.0.1.0 foundation release planning
- [ ] AC 6: All automated tests in Implementation Plan pass

## Out of Scope

- ❌ Beginning v.0.1.0 planning or task creation
- ❌ Updating external project tracking systems
- ❌ Team notification or communication about completion
- ❌ Performance metrics or completion analysis
- ❌ Backup or additional archival processes

## References

- dev-taskflow/current/v.0.0.0-bootstrap/ (source directory)
- dev-taskflow/done/ (target directory)
- dev-taskflow/roadmap.md (roadmap update target)
- task-manager recent (task tracking utility)
- dev-handbook/guides/project-management.g.md
