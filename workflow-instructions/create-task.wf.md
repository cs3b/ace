# Create Tasks

## Goal

Transform unstructured notes, feedback, or requirements into well-structured, actionable task files. This workflow handles any type of input - whether it's user feedback, requirement documents, ideas, or file contents - and creates properly formatted tasks following project standards.

## Prerequisites

* Raw notes or requirements to process (text, files, or user feedback)
* Access to `dev-taskflow/` directory for task storage
* Higher-order navigation tools available (nav-path)

## Project Context Loading

* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`
* Load tools documentation: `docs/tools.md`

## Process Steps

1. **Gather Input Material**
   * Collect raw input from user, which could be:
     * Direct text/feedback in the conversation
     * File paths to documents containing requirements
     * Mixed input with both text and file references
   * If files are referenced, read their contents
   * Combine all inputs into a single working document

2. **Analyze and Structure Content**
   * Read through all input material comprehensively
   * Identify distinct actionable items by looking for:
     * Feature requests or enhancements
     * Bug reports or issues to fix
     * Documentation needs
     * Research or investigation requirements
     * Architecture decisions needed
     * Testing requirements
   * Group related items that form cohesive work units
   * Note any ambiguous or unclear items for clarification

3. **Create Initial Task Breakdown**
   * For each identified actionable item or group:
     * Write a clear task title (Verb + Object format)
     * Summarize the objective and why it's needed
     * Identify key deliverables (files to create/modify/delete)
     * Estimate complexity and time required
     * Note any dependencies on other tasks
     * Identify which release/version it belongs to

4. **Present for User Verification**
   * Show the user a structured list of proposed tasks:

     ```
     Proposed Tasks:
     1. [Task Title] - [Brief description]
        - Objective: [Why this is needed]
        - Estimate: [Time estimate]
        - Priority: [high/medium/low]

     2. [Next Task Title] - [Brief description]
        ...
     ```

   * Ask for confirmation or adjustments:
     * Are all items captured?
     * Is the grouping logical?
     * Are priorities correct?
     * Any missing context or requirements?

5. **Create Formal Task Files**
   * Once approved, create task files using the task template:

6. **Determine Storage Location and Create Tasks**
   * **NOTE**: Tasks can now be created efficiently in sequence. The `create-path task-new` command creates files immediately, ensuring proper ID sequencing without duplicate ID issues.
   
   * For each approved task (create one task, then wait for completion before creating the next):
     * Use `create-path task-new --title "Task Title" --priority high --estimate "4h"` to:
       * Automatically determine current release context
       * Generate unique task ID with proper sequencing
       * Create target directory structure if needed
       * Create the task file with proper naming convention
       * Return the full path for the created task file
     * File is created immediately with proper ID sequencing
     * This replaces the manual process of using `bin/rc` and `bin/tnid` separately
     * Multiple tasks can be created in sequence efficiently

8. **Ensure Task Creation Completion**
   * Verify all planned tasks have been created:
     * Cross-reference against initial task breakdown list
     * Confirm each task file exists at expected location
     * Validate task IDs are sequential and properly formatted
   * Address any missing or incomplete tasks:
     * Identify uncreated tasks from original breakdown
     * Generate missing task IDs and create remaining files
     * Resolve any file conflicts or errors
   * **Validation Checklist:**
     * [ ] All tasks from user approval list are created
     * [ ] Task files follow proper naming convention
     * [ ] All task files contain complete template content
     * [ ] Task IDs are sequential without gaps

9. **Provide Summary**
   * List all created tasks with their:
     * IDs
     * Titles
     * File paths
     * Priority and estimates
   * Suggest next steps or related workflows

## Key Guidelines

### Task Granularity

* **Ideal task size**: 4-10 hours of focused work
* **Too large**: Break into subtasks or phases
* **Too small**: Combine with related items
* **Epic threshold**: Tasks over 25h should be epics

### Task Grouping Logic

* Group by feature area or component
* Group by technical dependency
* Group by deliverable type (docs, tests, implementation)
* Keep cross-cutting concerns separate

### Priority Assessment

* **High**: Blocks other work, critical path, or urgent fixes
* **Medium**: Important features or improvements
* **Low**: Nice-to-have, optimizations, or deferrables

### Quality Checks

* Every task must have clear acceptance criteria
* Deliverables must be specific file paths
* Implementation steps should be concrete actions
* Out of scope prevents feature creep
* References maintain traceability

## Input

* Raw notes in any format:
  * User feedback or requirements in chat
  * File paths to requirement documents
  * Mixed text and file references
  * Ideas, bugs, features, or improvements

## Output / Success Criteria

* All actionable items from input are captured as formal tasks
* Tasks follow the standard template with all sections complete
* Each task has a unique ID generated automatically via nav-path
* Tasks are stored in the correct location based on release context
* User has reviewed and approved the task breakdown
* Clear traceability from original input to created tasks

## Error Handling

* **Ambiguous input**: Ask user for clarification
* **Missing context**: Request additional details
* **No current release**: Default to backlog storage
* **ID generation fails**: nav-path handles this automatically, report any issues
* **File conflicts**: Alert user and suggest alternatives

## Usage Examples

**Example 1: User feedback in chat**
> "We need to add dark mode support, fix the login timeout issue, and update the API docs"

**Example 2: Requirements document**
> "Break down the requirements in dev-taskflow/backlog/new-features.md into tasks"

**Example 3: Mixed input**
> "Create tasks for the refactoring ideas I mentioned plus what's in the technical-debt.md file"

---

This workflow handles all types of input uniformly, creating consistent, well-structured tasks regardless of the source material. For specialized inputs like PR comments, use appropriate tools to fetch the data, then process through this workflow.

## Embedded Templates

<documents>
<template path="dev-handbook/templates/release-tasks/task.template.md">---
id: <generated automatically by nav-path>
status: pending
priority: <high/medium/low>
estimate: <n>h
dependencies: [<ticket-ids>]
---

# <Verb + Object>

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Why are we doing this?

## Scope of Work

- Bullet 1 …
- Bullet 2 …

### Deliverables

#### Create

- path/to/file.ext

#### Modify

- path/to/other.ext

#### Delete

- path/to/obsolete.ext

## Phases

1. Audit
2. Extract …
3. Refactor …

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: bin/test --check-analysis-complete
- [ ] Research best practices and design approach
- [ ] Plan detailed implementation strategy

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Step 1: Describe the first implementation action.
- [ ] Step 2: Describe the second action, which produces a verifiable outcome.
  > TEST: Verify Action 2 Outcome
  > Type: Action Validation
  > Assert: The outcome of Step 2 (e.g., file created, content updated) is as expected.
  > Command: bin/test --check-something path/to/relevant_artifact_from_step_2
- [ ] ... Add more implementation steps as needed.

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: All specified deliverables created/modified.
- [ ] AC 2: Key functionalities (if applicable) are working as described.
- [ ] AC 3: All automated checks in the Implementation Plan pass.

## Out of Scope

- ❌ …

## References

```
</template>
</documents>
