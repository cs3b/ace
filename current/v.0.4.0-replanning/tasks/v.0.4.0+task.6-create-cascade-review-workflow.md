---
id: v.0.4.0+task.6
status: draft
priority: medium
estimate: 6h
dependencies: [v.0.4.0+task.4]
---

# Create replan-cascade-task Workflow for Dependency Impact Analysis

## Objective

Create the `replan-cascade-task.wf.md` workflow that handles manual dependency impact analysis after task completion. This workflow reviews downstream tasks to identify necessary updates based on completed work, implementing the Joiner function from the planning agent architecture.

## What: Behavioral Specification

### User Experience
- **Trigger**: Manually run after task completion
- **Process**: Review dependent tasks in dependency order
- **Output**: Updated downstream tasks with impact notes or modifications

### Expected Behavior
1. Identify all tasks dependent on the completed task
2. Process dependencies in topological order
3. For draft tasks: Add impact notes at the beginning
4. For pending tasks: Review and update implementation details
5. Generate new ideas for discovered needs
6. Commit each task update separately for rollback capability

### Impact Handling Rules
- **Draft tasks**: Add notes section with impacts, preserve draft status
- **Pending tasks**: Update implementation plan based on changes
- **In-progress tasks**: Flag for developer attention only
- **No automatic status changes**: Maintain human control

## How: Implementation Plan

### Planning Steps
* [ ] Research dependency graph traversal patterns
* [ ] Design impact note format for draft tasks
* [ ] Plan rollback strategy for updates
* [ ] Define boundaries for cascade scope

### Execution Steps
- [ ] Create replan-cascade-task.wf.md workflow
- [ ] Define dependency identification process
- [ ] Document topological sort requirement
- [ ] Add draft task impact note template
- [ ] Add pending task update guidelines
- [ ] Include commit strategy for each update
- [ ] Add cycle detection warnings
- [ ] Create examples of cascade scenarios
- [ ] Document when NOT to run cascade
- [ ] Add manual intervention points

## Scope of Work

### Deliverables

#### Create
- dev-handbook/workflow-instructions/replan-cascade-task.wf.md
- dev-handbook/templates/tasks/impact-note.template.md

#### Modify
- dev-handbook/workflow-instructions/README.md

## Acceptance Criteria

- [ ] Workflow handles dependency graph traversal
- [ ] Draft tasks get impact notes without status change
- [ ] Pending tasks get implementation updates
- [ ] Each update is separately committable
- [ ] Cycle detection is documented
- [ ] Manual control points are clear

## Out of Scope

- ❌ Automatic cascade execution
- ❌ Status transitions
- ❌ Complex dependency resolution
- ❌ Integration with CI/CD
- ❌ Automated testing of cascades

## References

- Joiner function from planning agent research
- Dependency management best practices
- Git commit strategies