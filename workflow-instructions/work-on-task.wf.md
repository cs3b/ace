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

## Quick Start

For experienced users, here's the condensed workflow:

1. **Read linked documents** - Load project context and workflow instructions
2. **Select task** - Use `bin/tn` to get next task or specify task path
3. **Mark in-progress** - Update task status to `in-progress`
4. **Execute plan** - Work through planning and execution steps autonomously
5. **Validate completion** - Verify all subtasks and acceptance criteria are done
6. **Autonomous work** - Continue until user feedback is needed, then ask and proceed

## Detailed Process Steps

1. **Select Task File:**
   * Use automated task selection tool:

     ```bash
     # Get next task to work on
     bin/tn
     ```

   * Alternatively, manually select by listing available tasks:

     ```bash
     # Find current release directory
     ls -1 dev-taskflow/current/

     # List available tasks
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
   * Process each checklist item in order
   * **Work autonomously** - Continue implementing until user feedback is needed
   * If user input is required, ask and continue with the feedback

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
   * Run linters/formatters during development
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
   * **Ensure all subtasks are done** - Mark each as complete
   * **Verify all acceptance criteria** - Mark them as done:

     ```markdown
     ## Acceptance Criteria
     - [x] All deliverables created/modified
     - [x] Key functionalities working
     - [x] All automated checks pass
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
   * Work is complete and ready for review

## Task Documentation Organization

When creating task-related documentation and deliverables:

### Document Placement Rules

* **Task-specific documentation**: Create in `dev-taskflow/current/v.X.Y.Z-release/docs/`
* **Task-specific naming**: Prefix documents with task number (e.g., `25-validation-criteria-checklist.md`)
* **Analysis documents**: Research findings, compliance reports, validation results
* **Planning documents**: Implementation plans, action plans, design specifications
* **Process documentation**: Procedures, guidelines, validation criteria

### Examples

* **Analysis Report**: `dev-taskflow/current/v.0.3.0-workflows/docs/25-workflow-compliance-report.md`
* **Action Plan**: `dev-taskflow/current/v.0.3.0-workflows/docs/25-workflow-compliance-fixes.md`
* **Process Guide**: `dev-taskflow/current/v.0.3.0-workflows/docs/25-validation-criteria-checklist.md`

### Documentation Standards

* **Clear naming**: Use descriptive names that explain the document purpose
* **Task reference**: Always prefix with task number for traceability
* **Structured content**: Include headers, sections, and clear organization
* **Actionable content**: Provide concrete steps, criteria, or recommendations

## Codemod and Script Management

When creating scripts to manipulate text or files (codemods):

* **Location**: Create all codemods in the current release directory: `dev-taskflow/current/v.X.Y.Z-release/codemods/`
* **Purpose**: Scripts that automate text transformations, file modifications, or batch operations
* **Naming**: Use descriptive names reflecting the transformation (e.g., `convert-templates.sh`, `migrate-yaml-format.rb`)
* **Documentation**: Include comments explaining the transformation logic
* **Testing**: Test on small samples before applying to entire codebase
* **Cleanup**: Keep codemods for release documentation and future reference

## Temporary File Management

When working with temporary files:

* Create in system temp directory or project-specific location
* Use descriptive names with timestamps
* Clean up after task completion
* Never commit temporary files

## Error Handling

### Common Issues

**Missing Dependencies:**

**Symptoms:**

* Task dependencies not completed (`dependencies: [task-ids]`)
* Required tools or files not available
* Prerequisite project state not established

**Recovery Steps:**

1. Check dependency task status:

   ```bash
   # Find and check dependency tasks
   find dev-taskflow/current -name "*task.X*.md" | xargs grep "status:"
   ```

2. Verify required tools are available:

   ```bash
   which git
   which npm
   ls -la bin/test bin/lint
   ```

3. For blocking dependencies:
   * Update task status to `blocked`
   * Document specific blocking issue
   * Note what needs to be resolved
   * Move to unblocked task if possible
4. For missing tools, ask user to install or provide alternatives
5. Document missing prerequisites for future task execution

**Prevention:**

* Validate dependencies before starting task
* Check tool availability in prerequisites
* Verify project context documents are accessible

**Test Failures:**

**Symptoms:**

* `bin/test` returns non-zero exit code
* Embedded test commands fail
* Quality checks (lint, format) fail

**Recovery Steps:**

1. Run specific failing tests to understand scope:

   ```bash
   bin/test --verbose
   bin/lint
   ```

2. For embedded test failures:
   * Read test assertion carefully
   * Verify expected vs actual state
   * Check if test command exists and is valid
3. For quality failures:
   * Fix lint/formatting issues: `bin/lint --fix`
   * Address code style violations
   * Update tests if requirements changed
4. If tests are flaky, retry once before escalating
5. For persistent failures, STOP and report to user with:
   * Test name and type
   * Expected vs actual results
   * Full error message
   * Relevant code context

**Prevention:**

* Run `bin/test` before starting task to establish baseline
* Understand test requirements and coverage expectations
* Make small, incremental changes with test validation

**File System Issues:**

**Symptoms:**

* Cannot read task file or related documents
* Template files missing or corrupted
* Permission denied on file operations

**Recovery Steps:**

1. Verify task file exists and is readable:

   ```bash
   ls -la path/to/task.md
   cat path/to/task.md | head -20
   ```

2. Check project context document availability:

   ```bash
   ls -la docs/what-do-we-build.md docs/architecture.md docs/blueprint.md
   ```

3. For missing templates, check submodule status:

   ```bash
   git submodule status
   git submodule update --init --recursive
   ```

4. For permission issues, check directory ownership and permissions
5. Ask user to resolve file system issues if they persist

**Prevention:**

* Verify file existence before operations
* Check submodule initialization
* Use absolute paths when possible

**Invalid Task Structure:**

**Symptoms:**

* Task file missing required metadata (id, status, priority)
* Implementation plan structure is malformed
* Checklist items use wrong markers

**Recovery Steps:**

1. Validate task file structure against template:

   ```yaml
   ---
   id: v.X.Y.Z+task.N
   status: [pending | in-progress | done | blocked]
   priority: [high | medium | low]
   estimate: Nh
   dependencies: []
   ---
   ```

2. Check Implementation Plan structure:
   * Planning steps use asterisk markers (`* [ ]`)
   * Execution steps use hyphen markers (`- [ ]`)
3. For malformed tasks:
   * Report structure issues to user
   * Ask for task file correction
   * Use manual checklist if structure is unfixable
4. Document structure problems for task creation improvements

**Prevention:**

* Validate task structure before starting work
* Understand task template requirements
* Report task template issues early

**Context Loading Failures:**

**Symptoms:**

* Cannot load project context documents
* Missing project structure information
* Unclear project objectives or architecture

**Recovery Steps:**

1. Check for alternative project documentation:

   ```bash
   find . -name "README*" -o -name "*architecture*" -o -name "*blueprint*"
   ```

2. Load available context documents partially
3. Use task description and objectives as primary context
4. Ask user for project context if critical information missing
5. Proceed with limited context, documenting assumptions

**Prevention:**

* Verify project context documents exist before starting
* Have fallback documentation sources ready
* Understand minimum context requirements for task execution

**Task State Inconsistencies:**

**Symptoms:**

* Task status doesn't match actual progress
* Checklist items marked complete but work not done
* Duplicate task assignments or conflicts

**Recovery Steps:**

1. Review actual task progress vs. checklist status
2. Check what work has genuinely been completed:

   ```bash
   git status
   git log --oneline -5
   ```

3. Update task status to match reality:
   * Uncheck items that aren't actually done
   * Mark completed items correctly
   * Update status field appropriately
4. Identify and resolve any task conflicts or duplicates
5. Synchronize with user on actual project state

**Prevention:**

* Update task status immediately after changes
* Mark checklist items complete only after validation
* Use consistent task tracking practices

**Tool Command Failures:**

**Symptoms:**

* `bin/test --check-something` commands don't exist
* Embedded test commands are aspirational/invalid
* Project-specific tools not working

**Recovery Steps:**

1. Check if test command exists and is valid:

   ```bash
   ls -la bin/test
   bin/test --help
   ```

2. For non-existent commands:
   * Skip the test with documentation
   * Use alternative validation approach
   * Ask user about correct command syntax
3. For aspirational test commands (defined in task but not implemented):
   * Note that test is not yet available
   * Use manual validation where possible
   * Continue with task execution
4. Document tool availability issues for future improvement

**Prevention:**

* Verify tool commands before execution
* Understand which tests are implemented vs. planned
* Have manual validation fallbacks ready

**Large or Complex Tasks:**

**Symptoms:**

* Task has too many checklist items (>20)
* Estimated time is very large (>25h)
* Multiple unrelated concerns in one task

**Recovery Steps:**

1. Break down task into smaller, manageable chunks
2. Focus on core objectives first
3. Create subtasks or follow-up tasks for secondary concerns
4. Complete task in phases with intermediate validation
5. Ask user about task scope reduction if overwhelming

**Prevention:**

* Understand task complexity before starting
* Plan for phased execution of large tasks
* Suggest task breakdown when appropriate

### Recovery Framework for Task Execution

When errors occur during task execution:

1. **Immediate Response:**
   * Stop current operation if it might cause damage
   * Document error details and current state
   * Assess whether task can continue with workarounds

2. **Recovery Strategy:**
   * Try alternative approaches where possible
   * Use manual validation when automated tests fail
   * Continue with partial completion if beneficial
   * Update task status to reflect actual progress

3. **Escalation Guidelines:**
   * **Immediate escalation**: Data loss risks, security issues, destructive operations
   * **Document and continue**: Tool failures with workarounds, non-critical limitations
   * **Standard escalation**: Environment issues, missing dependencies, unclear requirements

4. **State Management:**
   * Save all work in progress before escalation
   * Update task file with current status and issues
   * Commit partial progress if valuable
   * Document next steps clearly for continuation

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
* Work completed with proper validation
* Code follows project standards
* Documentation updated as needed

## Common Patterns

### Task Selection Priority

1. High priority pending tasks
2. Tasks with met dependencies
3. Tasks matching current skills/context
4. Smaller tasks for quick wins

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
