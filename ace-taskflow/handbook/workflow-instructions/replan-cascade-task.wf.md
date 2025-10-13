---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2025-09-25'
---

# Replan Cascade Task Workflow Instruction

**Goal:** Review and update downstream tasks after completing a task with dependencies, implementing manual dependency impact analysis with robust graph traversal and controlled cascade operations.

## Prerequisites

* Completed task ID that has dependent tasks
* Understanding of task dependency structure
* Access to current release task files
* Git configured for individual commits

## Process Steps

1. **Identify Source Task:**
   * Provide the completed task ID (e.g., `v.0.4.0+task.4`)
   * Verify task exists and is marked as done
   * Load task content to understand what was implemented

2. **Build Dependency Graph:**
   * Scan all tasks in current release directory
   * Find tasks that have source task in their `dependencies:` array
   * Build full transitive dependency tree using DFS traversal
   * Track visited tasks to prevent infinite loops in circular dependencies
   * Report any circular dependencies found during traversal

3. **Order Tasks for Processing:**
   * Use topological sort (DFS-based) for dependency order
   * Process tasks from least dependent to most dependent
   * Ensure parent updates happen before child updates
   * Handle cycles gracefully with visited-set tracking

4. **Process Each Dependent Task:**

   **For Draft Tasks:**
   * Load current task content
   * Prepend impact notes after YAML metadata
   * Set `needs_review: true` in metadata
   * Preserve draft status (no automatic transitions)
   * Commit with descriptive message including source task ID

   **For Pending Tasks:**
   * Review implementation plan for needed updates
   * Update planning/execution steps based on changes
   * Set `needs_review: true` in metadata
   * Maintain pending status
   * Commit with impact rationale

   **For In-Progress/Done Tasks:**
   * Only set `needs_review: true` flag
   * Do not modify content or status
   * Alert developer to manual review need

5. **Commit Strategy:**
   * Create individual commits per task update
   * Use descriptive commit messages:
     ```
     task.N: Impact from task.M - brief description
     
     Detailed explanation of changes made
     ```
   * Include source task ID in every commit message
   * Enable easy rollback of individual changes

6. **Display Summary:**
   * Show total tasks reviewed and updated
   * List tasks needing manual review
   * Report any circular dependencies found
   * Display needs_review count prominently

## Manual Override Points

1. **Preview Mode:**
   * Option to run in dry-run mode first
   * Show what changes would be made
   * Allow selective task updates

2. **Confirmation Gates:**
   * Confirm before each task update
   * Option to skip specific tasks
   * Ability to abort cascade at any point

3. **Scope Control:**
   * Limit to current release only
   * Optional max-depth parameter
   * Exclude patterns for task IDs

## Embedded Templates

<documents>
    <template path="tmpl://tasks/impact-note">## Impact Notes from {source_task_id} Completion

**Generated**: {date}
**Source Task**: {source_task_title}

### Summary of Changes
{impact_summary}

### Required Actions
{action_items}

### Dependencies Updated
- This task now needs review due to upstream changes
- Review the implementation plan below for accuracy
- Update any assumptions that have changed

---

</template>
</documents>

## Usage Example

```bash
# Run cascade review after completing task 4
ace-taskflow task v.0.4.0+004
# Verify task is complete

# Execute cascade review
replan-cascade-task v.0.4.0+task.4

# Preview mode first
replan-cascade-task v.0.4.0+task.4 --preview

# Limit cascade depth
replan-cascade-task v.0.4.0+task.4 --max-depth 2
```

## Error Handling

### Circular Dependencies
- Continue processing with visited tracking
- Report all cycles at end of workflow
- Do not abort on cycle detection
- Mark all cycle participants for review

### Missing Dependencies
- Skip tasks with invalid dependency references
- Log warnings for missing tasks
- Continue with valid dependencies

### Git Conflicts
- Resolve conflicts before continuing
- Option to stash and reapply changes
- Clear rollback instructions provided

## Input
* Completed task ID (e.g., `v.0.4.0+task.4`)
* Optional parameters:
  - `--preview`: Dry-run mode
  - `--max-depth N`: Limit transitive depth
  - `--confirm`: Require confirmation for each update

## Output / Success Criteria
* All dependent tasks reviewed and updated appropriately
* Individual commits created for each change
* Clear audit trail of cascade impacts
* Needs review flags set on impacted tasks
* Summary report of all changes made
* Circular dependencies reported clearly

---

This workflow enables systematic impact analysis after task completion, ensuring downstream tasks remain aligned with implemented changes while maintaining human oversight and control.
