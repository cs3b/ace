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

## Example

### Scenario: Task Validation and Planning Workflow

Starting with a draft task that needs behavioral validation and implementation planning:

```bash
# Initial task state: draft
# Task: dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md
```

#### Step 1: Behavioral Review
```bash
review-task dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md
```

**review-task.wf.md workflow performs:**
1. Validates behavioral specification completeness
   - Checks user experience description
   - Verifies interface contracts are defined
   - Ensures success criteria are measurable
2. Validates alignment with project architecture
   - Reviews against existing patterns
   - Checks dependency compatibility
   - Validates scope boundaries
3. Updates task with behavioral clarifications
   - Adds missing interface details
   - Clarifies success criteria
   - Maintains draft status for further planning

**Result:** Task updated with validated behavioral specification, still in draft status.

#### Step 2: Implementation Planning
```bash
replan-task dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md
```

**replan-task.wf.md workflow performs:**
1. Analyzes validated behavioral specification
2. Researches implementation approaches
   - Evaluates existing search patterns
   - Selects appropriate tools and libraries
   - Defines technical architecture
3. Creates detailed execution plan
   - Lists specific files to modify
   - Defines implementation steps
   - Identifies rollback strategies
4. Promotes task from draft to pending

**Result:** Task promoted to pending status with complete implementation plan.

### Iterative Refinement Example

```bash
# Run review-task multiple times as understanding evolves
review-task dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md

# After behavioral updates, re-run planning
replan-task dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md

# Task state transitions: draft → (review) → draft → (replan) → pending
```

### Clear Separation Demonstration

**What review-task.wf.md validates:**
- WHAT: Search functionality must support fuzzy matching
- WHAT: Interface must return structured results
- WHAT: Performance must handle 10k+ items

**What replan-task.wf.md plans:**
- HOW: Use fuse.js library for fuzzy search
- HOW: Implement SearchService class in src/services/
- HOW: Add search endpoint to existing API controller

## Out of Scope

- ❌ Automatic workflow chaining
- ❌ Tool implementation changes
- ❌ Task execution concerns
- ❌ Cascade review functionality

## References

- Planner concept from research
- Current review-task.wf.md
- Separation of concerns principle