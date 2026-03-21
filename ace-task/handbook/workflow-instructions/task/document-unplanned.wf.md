---
doc-type: workflow
purpose: Document significant unplanned work
ace-docs:
  last-updated: '2026-03-21'
---

# Document Unplanned Work Workflow Instruction

## Goal

Document significant work completed during a session that wasn't part of any planned task, creating proper task records for tracking and future reference.

## Prerequisites

- Understanding of what constitutes "significant work" worthy of documentation
- Access to ace-task CLI tool for creating tasks
- Knowledge of current release cycle and task structure
- Ability to identify completed work that wasn't previously tracked

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## High-Level Execution Plan

### Planning Steps

- [ ] Review all work completed in the current session
- [ ] Identify changes that constitute "significant work"
- [ ] Determine if work relates to existing tasks or is completely unplanned
- [ ] Gather technical details, commit references, and file changes

### Execution Steps

- [ ] Create task records for each piece of unplanned work
- [ ] Document the work as completed (past tense)
- [ ] Mark all created tasks as "done" status
- [ ] Include references to commits, issues, or discussions

## Process Steps

1. **Identify Unplanned Work:**
   Review the session to identify work that:
   - Fixed bugs or issues not tracked in tasks
   - Implemented features or improvements ad-hoc
   - Resolved technical debt or refactoring
   - Updated documentation or configuration
   - Made architectural or design decisions

   **What Constitutes Significant Work:**
   - Changes that affect system behavior or architecture
   - Bug fixes that resolve user-facing issues
   - Performance improvements or optimizations
   - Security fixes or vulnerability patches
   - Documentation updates that clarify important concepts
   - Configuration changes that affect deployment or development

   **What Doesn't Need Documentation:**
   - Minor typo fixes (unless in critical documentation)
   - Code formatting or style changes
   - Temporary debugging code
   - Experimental changes that were reverted

2. **Create Task Record:**
   For each piece of significant unplanned work:

   ```bash
   ace-task create --title "[Descriptive title of work completed]" --status done
   ```

   Example:
   ```bash
   ace-task create --title "Fix invalid Claude tool specifications in command metadata" --status done
   ```

3. **Document the Completed Work:**
   Edit the created task file to document what was done:

   **Update Status and Metadata:**
   ```yaml
   ---
   id: v.X.X.X+task.NNN
   status: done  # Always "done" for completed work
   priority: [high|medium|low]  # Based on impact
   estimate: [actual time spent]
   dependencies: [list any related tasks]
   ---
   ```

   **Structure for Documenting Completed Work:**

4. **Include Technical Details:**
   Document the work with sufficient detail for future reference:

   - **Issue/Problem**: What prompted this work
   - **Root Cause**: What was discovered during investigation
   - **Solution**: What changes were made
   - **Files Modified**: List of affected files
   - **Testing**: How the fix was validated
   - **References**: Links to commits, PRs, or discussions

5. **Link Dependencies:**
   If the unplanned work relates to other tasks:
   - Add task IDs to the dependencies field
   - Note if this work blocks or unblocks other tasks
   - Reference any follow-up work needed

## Success Criteria

- All significant unplanned work from the session is documented
- Each piece of work has a corresponding task marked as "done"
- Task documentation includes:
  - Clear description of what was done
  - Technical details and file changes
  - Validation/testing performed
  - References to commits or other artifacts
- Tasks follow the project's naming and numbering conventions
- Related tasks are properly linked through dependencies

## Common Patterns

### Bug Fix Documentation

When documenting an unplanned bug fix:
1. Describe the bug symptoms
2. Explain the root cause discovered
3. Detail the fix implemented
4. List files modified
5. Include test commands or validation steps

### Feature Addition Documentation

When documenting an unplanned feature:
1. Explain why the feature was added
2. Describe the implementation approach
3. List new files created and existing files modified
4. Include usage examples
5. Note any documentation updates needed

### Refactoring Documentation

When documenting unplanned refactoring:
1. Explain what prompted the refactoring
2. Describe the before and after structure
3. List all files affected
4. Note any API or behavior changes
5. Include migration steps if applicable

## Usage Example

> "We just finished a session where we fixed two issues with the Claude integration that weren't tracked in any tasks. Document this unplanned work."

The workflow would:
1. Create two new tasks for the fixes
2. Document each fix with technical details
3. Mark both tasks as done
4. Include references to the commits made

<documents>
<template path="dev-handbook/templates/completed-work-documentation.md">
## Behavioral Context

**Issue**: [Describe the issue or need that prompted this work]

**Key Behavioral Requirements**:
- [What behavior needed to change or be fixed]
- [What the system should do after the fix]
- [Any constraints or considerations]

## Objective

[One-sentence summary of what was accomplished]

## Scope of Work

- [Bullet point summary of changes made]
- [Another change]
- [And another]

### Deliverables

#### Create
- [New files created, if any]

#### Modify
- [Files that were modified]
- [With brief description of changes]

#### Delete
- [Files removed, if any]

## Implementation Summary

### What Was Done

- **Problem Identification**: [How the issue was discovered]
- **Investigation**: [Key findings during analysis]
- **Solution**: [The approach taken to fix it]
- **Validation**: [How the fix was tested]

### Technical Details

[Include relevant code changes, configuration updates, or architectural decisions]

### Testing/Validation

```bash
# Commands used to test the fix
[test command]
```

**Results**: [What the testing showed]

## References

- Commits: [commit hashes and messages]
- Related issues: [if any]
- Documentation: [any docs updated]
- Follow-up needed: [if any]
</template>
</documents>