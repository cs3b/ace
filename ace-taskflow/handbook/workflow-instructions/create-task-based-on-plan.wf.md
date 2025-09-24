# Create Task Based on Plan Workflow Instruction

**Goal:** Create a new task from an existing plan, following the draft and plan task workflows systematically.

## Prerequisites

* Existing plan or specification to base the task on
* Access to ace-taskflow command
* Understanding of task structure and requirements

## Process Steps

1. **Draft the Task:**
   * Follow the task drafting workflow to create initial task structure
   * Use the plan as the basis for task requirements
   * Ensure proper metadata (id, status, priority, estimate, dependencies)
   * Create clear behavioral specification from the plan

2. **Plan the Task:**
   * Apply task planning workflow to the drafted task
   * Break down requirements into actionable steps
   * Create both Planning Steps (research/analysis) and Execution Steps (implementation)
   * Add acceptance criteria based on plan objectives

## Implementation

### Step 1: Draft Task from Plan

Create a new task using the plan as input:
```bash
# Create task with title from plan
ace-taskflow task create "Task Title from Plan"
```

Structure the task with:
- Clear behavioral specification
- User experience description
- Interface contract
- Success criteria from plan

### Step 2: Plan Task Implementation

Enhance the drafted task with detailed implementation plan:
- Planning Steps (marked with `* [ ]`)
  - Research requirements
  - Analyze dependencies
  - Design approach

- Execution Steps (marked with `- [ ]`)
  - Implementation actions
  - Testing steps
  - Documentation tasks

### Step 3: Validate Task

Ensure the task:
- Has complete metadata
- Contains clear implementation plan
- Includes acceptance criteria
- Is ready for execution

## Quick Reference

1. Draft task using plan as specification source
2. Plan task with detailed implementation steps
3. Validate task completeness before starting work

## Output / Success Criteria

* Task created with proper structure and metadata
* Implementation plan derived from original plan/specification
* Task ready for execution with clear steps
* All plan requirements captured as acceptance criteria