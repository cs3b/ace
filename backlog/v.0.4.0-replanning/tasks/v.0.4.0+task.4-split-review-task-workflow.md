---
id: v.0.4.0+task.4
status: draft
priority: high
estimate: 8h
dependencies: [v.0.4.0+task.3]
---

# Split review-task into Behavior Review and Implementation Planning

## Objective

Refactor the existing `review-task.wf.md` workflow to clearly separate behavioral review (validating WHAT) from implementation planning (defining HOW). Create a new `replan-task.wf.md` workflow for detailed implementation planning while keeping review-task focused on behavioral validation.

## What: Behavioral Specification

### User Experience
- **review-task**: Validates behavioral specification and interface contracts
- **replan-task**: Plans implementation details, tools, and file modifications
- **Iteration**: Both workflows can be run multiple times as understanding evolves

### Expected Behavior

#### review-task.wf.md (Behavioral Validation)
1. Load task and verify behavioral specification completeness
2. Validate interface contracts and success criteria
3. Check alignment with project goals and architecture
4. Identify missing behavioral requirements
5. Update task with clarifications but maintain draft status

#### replan-task.wf.md (Implementation Planning)
1. Start with validated behavioral specification
2. Research implementation approaches
3. Select appropriate tools and patterns
4. Define file modifications and dependencies
5. Create detailed execution steps
6. Promote from draft to pending when ready

### Key Separation
- **review-task**: WHAT validation, interface verification, goal alignment
- **replan-task**: HOW planning, tool selection, technical decisions

## How: Implementation Plan

### Planning Steps
* [ ] Analyze current review-task.wf.md mixed concerns
* [ ] Design clear boundaries between workflows
* [ ] Define handoff format between review and planning
* [ ] Research implementation planning best practices

### Execution Steps
- [ ] Refactor review-task.wf.md to focus on behavioral validation
  - Remove implementation planning sections
  - Add interface contract validation
  - Focus on success criteria verification
- [ ] Create replan-task.wf.md for implementation planning
  - Add tool selection guidelines
  - Include dependency analysis
  - Define file modification planning
  - Add rollback strategy section
- [ ] Update both workflows with clear cross-references
- [ ] Add examples showing the separation of concerns
- [ ] Document when to use each workflow
- [ ] Update workflow README with new structure

## Scope of Work

### Deliverables

#### Create
- dev-handbook/workflow-instructions/replan-task.wf.md

#### Modify
- dev-handbook/workflow-instructions/review-task.wf.md
- dev-handbook/workflow-instructions/README.md

## Acceptance Criteria

- [ ] Clear separation of WHAT and HOW concerns
- [ ] review-task validates behavior without implementation
- [ ] replan-task handles all implementation planning
- [ ] Workflows can iterate independently
- [ ] Examples demonstrate proper usage
- [ ] Integration with task states documented

## Out of Scope

- ❌ Automatic workflow chaining
- ❌ Tool implementation changes
- ❌ Task execution concerns
- ❌ Cascade review functionality

## References

- Planner concept from research
- Current review-task.wf.md
- Separation of concerns principle