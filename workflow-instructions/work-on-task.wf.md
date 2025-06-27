# Work on Task Workflow Instruction

**Goal:** Initiate and guide the step-by-step implementation of a specific task, using the detailed plan embedded directly within the task's definition file.

## Prerequisites

* Task file selected with embedded implementation plan
* Understanding of the task format and structure
* Access to project files and tools

## Project Context Loading

* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`

## Process Steps

1. **Select Task File:**
   * Identify the current release directory:

     ```bash
     # Find current release directory
     ls -1 dev-taskflow/current/
     ```

   * List available tasks:

     ```bash
     ls -1 dev-taskflow/current/*/tasks/*.md
     ```

   * Review task metadata to select appropriate task:
     * Check `status: pending` (not yet started)
     * Verify `dependencies: []` are met
     * Consider `priority: high/medium/low`
   * Provide the full path to the selected task file

2. **Load Task & Validate Plan:**
   * Load the content of the selected task `.md` file
   * **Verify Task Structure:**

     ```markdown
     ---
     id: v.X.Y.Z+task.N
     status: [pending | in-progress | done | blocked]
     priority: [high | medium | low]
     estimate: Nh
     dependencies: []
     ---
     
     # Task Title
     
     ## Implementation Plan
     ### Planning Steps
     * [ ] Research/analysis steps (asterisk markers)
     ### Execution Steps  
     - [ ] Implementation actions (hyphen markers)
     ```

   * If structure is invalid, STOP and report the issue
   * Review the task's Objective to ensure understanding

3. **Update Task Status:**
   * Change task status from `pending` to `in-progress`:

     ```yaml
     status: in-progress
     ```

   * Save the updated task file

4. **Execute Task Plan Step-by-Step:**
   * Process each checklist item in order:

   **For Planning Steps (`* [ ]`):**
   * Execute research, analysis, or design work
   * Document findings inline or in separate files
   * Check for embedded tests:

     ```markdown
     * [ ] Research step
       > TEST: Pre-condition Check
       > Type: Pre-condition Check
       > Assert: What needs to be verified
       > Command: bin/test --check-something
     ```

   **For Execution Steps (`- [ ]`):**
   * Implement the concrete action
   * Follow coding standards (see embedded guidelines below)
   * Check for embedded tests:

     ```markdown
     - [ ] Implementation step
       > TEST: Action Validation
       > Type: Action Validation
       > Assert: Expected outcome
       > Command: bin/test --verify-result
     ```

   **Test Execution:**
   * Run any embedded test commands
   * If tests fail: STOP, report failure, await instructions
   * Only mark item complete (`[x]`) after tests pass

5. **Follow Coding Standards:**
   When implementing code changes, follow these principles:

   **General Principles:**
   * **Clarity**: Use meaningful names, keep functions focused
   * **Consistency**: Follow established project patterns
   * **Simplicity**: Avoid unnecessary complexity
   * **DRY**: Abstract common logic into reusable components
   * **Modularity**: Clear responsibilities, loose coupling
   * **Testability**: Design for easy testing

   **Code Quality:**
   * Use consistent indentation (2 spaces for Ruby)
   * Limit line length (100-120 characters)
   * Run linters/formatters before committing
   * Write tests for new functionality
   * Document public APIs and complex logic

   **Error Handling:**
   * Use specific, informative error classes
   * Provide context with errors
   * Handle errors appropriately for the context

6. **Handle Test Failures:**
   If tests fail during implementation:

   **Immediate Actions:**
   1. Stop processing the current step
   2. Capture the error output
   3. Report to user with:
      * Test name and type
      * Expected vs actual results
      * Full error message
      * Relevant code context

   **Diagnostic Steps:**
   * Check test assumptions
   * Verify environment setup
   * Review recent changes
   * Consider edge cases

   **Resolution Options:**
   * Fix the implementation
   * Update the test if requirements changed
   * Mark task as blocked if external help needed

7. **Final Review & Completion:**
   * Review all completed checklist items
   * Verify against Acceptance Criteria:

     ```markdown
     ## Acceptance Criteria
     - [ ] All deliverables created/modified
     - [ ] Key functionalities working
     - [ ] All automated checks pass
     ```

   * Run final validation:

     ```bash
     # Run project tests
     bin/test
     
     # Run linting
     bin/lint
     
     # Build if applicable
     bin/build
     ```

   * Update task status to `done`
   * Commit all changes with descriptive message

## Temporary File Management

When working with temporary files:
* Create in system temp directory or project-specific location
* Use descriptive names with timestamps
* Clean up after task completion
* Never commit temporary files

## Error Recovery

**If workflow is interrupted:**

1. Save all work in progress
2. Document the current step and any issues
3. Update task file with notes
4. Commit partial progress if valuable

**If blocked by dependencies:**

1. Update task status to `blocked`
2. Document the blocking issue
3. Note required resolution
4. Move to another task if possible

## Input

* Full path to the selected task file containing embedded implementation plan
* Task must have valid structure and implementation plan

## Output / Success Criteria

* All checklist items marked complete (`[x]`)
* All embedded tests pass
* Acceptance criteria met
* Task status updated to `done`
* Changes committed with appropriate message
* Code follows project standards
* Documentation updated as needed

## Common Patterns

### Task Selection Priority

1. High priority pending tasks
2. Tasks with met dependencies
3. Tasks matching current skills/context
4. Smaller tasks for quick wins

### Commit Message Format

```
type(scope): description

- Detail 1
- Detail 2

Refs: #task-id
```

Types: feat, fix, docs, style, refactor, test, chore

### Test-Driven Development

1. Write/run test first (if applicable)
2. Implement minimal code to pass
3. Refactor for quality
4. Verify all tests still pass

## Usage Example
>
> "Work on task dev-taskflow/current/v.0.3.0-workflows/tasks/v.0.3.0+task.3-refactor-workflows.md"

---

This workflow guides the systematic implementation of tasks, ensuring quality, traceability, and project consistency throughout the development process.
