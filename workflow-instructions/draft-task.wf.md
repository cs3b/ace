# Draft Task - Behavior-First Specification

## Goal

Create high-level behavioral specifications that define WHAT the system should do (UX/DX/AX) rather than HOW to implement it. This workflow transforms ideas or requirements into behavior-first draft tasks with clear interface contracts, leaving implementation details for the replan phase. The workflow also includes automated idea file management, moving original idea files to organized locations with task number prefixes for clear traceability.

## Prerequisites

* Enhanced ideas or direct requirements (optional input from capture-it)
* Understanding of user experience and interface requirements
* Access to `dev-taskflow/` directory for task storage
* Higher-order navigation tools available (nav-path)
* Load Project Context

## Project Context Loading

- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`

## Process Steps

1. **Gather Behavioral Requirements**
   * Collect input material focusing on user experience:
     * Direct behavioral requirements from user
     * Enhanced ideas from capture-it output
     * User stories or experience descriptions
     * Interface specifications or contracts
   * If files are referenced, read their contents
   * Focus on understanding WHAT users need, not HOW to build it

2. **Define Behavioral Specification**
   * For each requirement, identify:
     * User experience (input, process, output)
     * Expected system behavior
     * Success criteria (measurable outcomes)
     * Interface contracts (CLI, API, UI)
     * Validation questions and unknowns
   * Avoid implementation details like:
     * Specific file structures
     * Code organization
     * Technical architecture decisions
     * Tool or library selections

3. **Create Interface Contracts**
   * Define clear interfaces based on requirements:
     * CLI commands with arguments and flags
     * API endpoints with request/response formats
     * UI components with expected behaviors
     * Data flow and interaction patterns
   * Use examples from existing tools (like capture-it pattern)
   * Specify public contracts that implementation must satisfy

4. **Present Behavioral Draft for Verification**
   * Show the user behavior-focused task proposals:

     ```
     Proposed Behavioral Specifications:
     1. [Task Title] - [User experience summary]
        - What users experience: [UX description]
        - Interface contract: [CLI/API/UI examples]
        - Success criteria: [Measurable outcomes]
        - Status: draft (needs implementation planning)

     2. [Next Task Title] - [User experience summary]
        ...
     ```

   * Ask for confirmation focusing on behavior:
     * Is the user experience clearly defined?
     * Are interface contracts complete?
     * Are success criteria measurable?
     * Any missing behavioral requirements?

5. **Create Draft Task Files**
   * Once behavioral specifications are approved, create draft task files
   * **NOTE**: Tasks are created with `status: draft` to indicate they need implementation planning

6. **Determine Storage Location and Create Draft Tasks**
   * For each approved behavioral specification:
     * Use `task-manager create --title "Task Title" --status draft --priority high --estimate "TBD"` to:
       * Create task file with proper ID sequencing
       * Set status to "draft" automatically
       * Include behavioral specification template
       * Return full path for the created draft file
     * Focus on behavioral content, leave implementation for replan phase

7. **Complete Behavioral Specifications**
   * For each created draft task, populate with:
     * Behavioral Specification section with embedded template
     * Interface Contract definitions with examples
     * Success Criteria as mandatory requirements
     * Validation Questions highlighting unknowns
     * Integration with capture-it if applicable
   * Avoid adding implementation details

8. **Organize Source Idea Files (REQUIRED when drafting from ideas)**
   * **IMPORTANT**: When task is created from idea files, ALWAYS move them to current release:
   * Track all source idea files used for this draft task:
     * List all idea files referenced during behavioral specification
     * Note: Multiple idea files may be combined into one task
   * For EACH source idea file:
     * Extract task number from created task path: `echo "$TASK_PATH" | grep -oE "task\.([0-9]{3})" | cut -d. -f2`
     * Get current release path: `RELEASE_PATH=$(release-manager current | grep "Path:" | awk '{print $2}')`
     * Create destination directory if needed: `mkdir -p "$RELEASE_PATH/docs/ideas"`
     * Build destination filename: `$TASK_NUM-$(basename "$IDEA_FILE_PATH")`
       * For multiple files with same task: Use same prefix for all (e.g., `040-017-idea.md`, `040-018-idea.md`)
     * Execute file movement: `git-mv "$IDEA_FILE_PATH" "$RELEASE_PATH/docs/ideas/$DESTINATION_FILENAME"`
   * Update task references:
     * Update the task file's References section with new idea file locations
     * Ensure all moved files are properly tracked
   * Commit the movements:
     * Use `git-commit` to commit all idea file movements together
     * Clear commit message: "Move idea files to current release for task $TASK_NUM"
   * **Validation Requirements:**
     * [ ] All source idea files moved to current release
     * [ ] Task references updated to new locations
     * [ ] Git movements committed
   * Error handling:
     * If release-manager fails: Create files in backlog/drafts/ instead
     * If git-mv fails: Report error and manual intervention needed
   * Success indicators:
     * Report each file movement: "Moved: [old-path] -> [new-path]"
     * Confirm all source ideas organized: "All X idea files moved to current release"

9. **Ensure Draft Creation Completion**
   * Verify all behavioral specifications are captured:
     * Cross-reference against initial requirements
     * Confirm each draft file exists with correct status
     * Validate behavioral sections are complete
   * **Validation Checklist:**
     * [ ] All behavioral requirements captured as drafts
     * [ ] Task files have status: draft
     * [ ] Behavioral specifications are complete
     * [ ] Interface contracts are defined
     * [ ] Success criteria are measurable

10. **Provide Behavioral Summary**
   * List all created draft tasks with their:
     * IDs and titles
     * User experience summaries
     * Interface contracts
     * Status (draft - needs planning)
   * Suggest next step: implementation planning phase

## Key Guidelines

### Behavior-First Focus

* **What over How**: Define user experience before implementation
* **Interface Contracts**: Specify CLI/API/UI behaviors clearly
* **Success Criteria**: Measurable outcomes that define completion
* **Validation Questions**: Highlight unknowns and assumptions

### Draft Status Integration

* All tasks created have `status: draft`
* Draft indicates behavioral specification complete, implementation planning needed
* Clear handoff to replan/implementation phase
* No mixing of behavioral and implementation concerns

### Capture-It Integration

* Enhanced ideas provide structured input for behavioral specification
* Validation questions and unknowns from ideas feed into behavioral requirements
* Optional but recommended input source
* Maintains clear separation between idea enhancement and task drafting

## Input

* Enhanced ideas from capture-it (optional but recommended)
* Direct behavioral requirements or user stories
* Interface specifications or contracts
* User experience descriptions

## Output / Success Criteria

* Draft tasks with complete behavioral specifications
* Clear interface contracts for each requirement
* Measurable success criteria defined
* All tasks have status: draft
* No implementation details mixed with behavioral requirements
* Clear handoff to implementation planning phase
* **REQUIRED when drafting from ideas:**
  * All source idea files moved to current release docs/ideas/ directory
  * Task number prefixes added to moved idea files
  * Task references updated to new idea file locations
  * Git movements properly committed

## Error Handling

* **Missing behavioral context**: Ask user for experience details
* **Unclear interface requirements**: Request contract examples
* **Implementation details provided**: Redirect focus to user experience
* **No current release**: Default to backlog storage with draft status

## Usage Examples

**Example 1: Capture-it integration**
> "Draft tasks from enhanced idea: dev-taskflow/backlog/ideas/20250130-1445-oauth-authentication.md"

**Example 2: Direct behavioral requirements**
> "Create behavioral specification for: Users need secure login with OAuth support and 24-hour sessions"

**Example 3: Interface-focused requirements**
> "Draft task for CLI tool: auth-manager with login, logout, and status commands"

---

This workflow creates behavior-first specifications that serve as clear contracts for implementation, ensuring user value is defined before technical details are considered.

## Embedded Templates

<documents>
<template path="dev-handbook/templates/task-management/task.draft.template.md">---
id: {id}
status: draft
priority: {priority}
estimate: TBD
dependencies: {dependencies}
---

# {title}

## Behavioral Specification

### User Experience
- **Input**: [What users provide - data, commands, interactions]
- **Process**: [What users experience during interaction - feedback, states, flows]
- **Output**: [What users receive - results, confirmations, artifacts]

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

[Describe the desired behavior, user experience, and system responses]

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# CLI Interface (if applicable)
command-name [options] <arguments>
# Expected outputs, error messages, and status codes

# API Interface (if applicable)
GET/POST/PUT/DELETE /endpoint
# Request/response formats, error responses, status codes

# UI Interface (if applicable)
# User interactions, form behaviors, navigation flows
```

**Error Handling:**
- [Error condition 1]: [Expected system response]
- [Error condition 2]: [Expected system response]

**Edge Cases:**
- [Edge case 1]: [Expected behavior]
- [Edge case 2]: [Expected behavior]

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Behavioral Outcome 1**: [Observable user/system behavior or capability]
- [ ] **User Experience Goal 2**: [Measurable user experience improvement]
- [ ] **System Performance 3**: [Measurable system behavior or performance metric]

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [ ] **Requirement Clarity**: [Question about unclear or ambiguous requirements]
- [ ] **Edge Case Handling**: [Question about boundary conditions or unusual scenarios]
- [ ] **User Experience**: [Question about user expectations, workflows, or interactions]
- [ ] **Success Definition**: [Question about how success will be measured or validated]

## Objective

Why are we doing this? Focus on user value and behavioral outcomes.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: [Which user interactions, workflows, and experiences are included]
- **System Behavior Scope**: [Which system capabilities, responses, and behaviors are included]
- **Interface Scope**: [Which APIs, commands, or interfaces are included]

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- User experience flow definitions
- System behavior specifications
- Interface contract definitions

#### Validation Artifacts
- Success criteria validation methods
- User acceptance criteria
- Behavioral test scenarios

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: File structures, code organization, technical architecture
- ❌ **Technology Decisions**: Tool selections, library choices, framework decisions
- ❌ **Performance Optimization**: Specific performance improvement strategies
- ❌ **Future Enhancements**: Related features or capabilities not in current scope

## References

- Related capture-it output (if applicable)
- User experience requirements
- Interface specification examples
```
</template>
</documents>
