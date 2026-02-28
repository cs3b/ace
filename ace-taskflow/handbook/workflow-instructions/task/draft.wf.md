---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2026-02-16'
---

# Draft Task - Behavior-First Specification

## Goal

Create high-level behavioral specifications that define WHAT the system should do (UX/DX/AX) rather than HOW to implement it. This workflow transforms ideas or requirements into behavior-first draft tasks with clear interface contracts, leaving implementation details for the replan phase. The workflow also includes automated idea file management, moving original idea files to organized locations with task number prefixes for clear traceability.

## Prerequisites

* Enhanced ideas or direct requirements (optional input from ace-idea)
* Understanding of user experience and interface requirements
* Access to `.ace-taskflow/` directory for task storage
* ace-taskflow command available for task management
* Load Project Context

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## Process Steps

1. **Gather Behavioral Requirements**
   * Collect input material focusing on user experience:
     * Direct behavioral requirements from user
     * Enhanced ideas from ace-idea output
     * User stories or experience descriptions
     * Interface specifications or contracts
   * If files are referenced, read their contents
   * **Intent mapping from enhanced ideas**: When the source idea contains the
     3-Question Delegation Brief sections (`What I Hope to Accomplish`,
     `What "Complete" Looks Like`, `Success Criteria`), use them as the
     starting point for the task's Objective, Expected Behavior, and
     Success Criteria respectively. Carry the idea's framing forward -
     add behavioral specificity, don't restate from scratch.
     If the idea contains italicized gap markers, surface these as
     questions to the user during verification (step 4).
     For ideas without the 3-question structure, gather requirements
     normally (no change to current behavior).
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
   * Use examples from existing tools (like ace-idea pattern)
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

   **Detect the task structure needed before creating anything:**

   | User hint | Structure to create |
   |-----------|---------------------|
   | "one task with subtasks" | One orchestrator + N subtasks |
   | "N phases, each as a subtask" | One orchestrator + N subtask children |
   | "one task with one subtask per phase" | One orchestrator + N subtask children |
   | No structural hint | Single flat task |

   **Pattern A — Single flat task (default):**
   ```bash
   ace-task create "Task Title" --status draft --estimate "TBD"
   ```

   **Pattern B — Orchestrator with subtasks:**
   ```bash
   # 1. Create the parent task first
   ace-task create "Parent Title" --status draft --estimate "TBD"
   # Returns: v.X.Y+task.NNN

   # 2. Add each subtask with --child-of (auto-converts parent to orchestrator)
   ace-task create "Phase 1: ..." --status draft --child-of NNN
   ace-task create "Phase 2: ..." --status draft --child-of NNN
   ace-task create "Phase 3: ..." --status draft --child-of NNN
   ```
   ⚠️ Do NOT use `task move --child-of self` first — `--child-of` on both `task create` and `task move` now auto-converts the parent orchestrator.

   For each created task/subtask:
   * Create task file with proper ID sequencing
   * Set status to "draft" automatically
   * Include behavioral specification template
   * Focus on behavioral content, leave implementation for replan phase

### Spike-First Rule for Engine/Pipeline Redesigns

When an orchestrator task redesigns a core execution path (test runner, build pipeline,
deployment flow), the FIRST subtask should be a time-boxed spike that:
1. Validates the target architecture end-to-end with a single scenario
2. Identifies which existing concepts survive and which get removed
3. Produces a "concept inventory" showing what the final system looks like

Only AFTER the spike validates the end-state should remaining subtasks be drafted.
This prevents decomposing into subtasks that add concepts the spike later proves unnecessary.

**Anti-pattern**: 8 subtasks drafted upfront, each adding features, then a late subtask undoes half.
**Correct pattern**: 1 spike subtask validates the end-state, then remaining subtasks build toward it.

7. **Complete Behavioral Specifications**
   * For each created draft task, populate with:
     * Behavioral Specification section with embedded template
     * Interface Contract definitions with examples
     * Success Criteria as mandatory requirements
     * Validation Questions highlighting unknowns
     * Integration with ace-idea if applicable
   * Avoid adding implementation details

8. **Create Draft Usage Documentation (When Interfaces Change)**
   * **Applicability check** — does this task change any external API surface?
     * CLI commands (new commands, changed flags, changed output format)
     * Developer API (new/changed modules, classes, methods)
     * Agent API (new/changed workflows, protocols, slash commands)
     * Configuration (new/changed config keys, env vars)
   * If YES to any:
     * Create `ux/usage.md` in the task directory using the embedded draft-usage template
     * Populate with 2-3 concrete scenarios from the Interface Contract section
     * Each scenario: goal + command/call + expected output
     * This is the behavioral acceptance contract the implementer must satisfy
     * The full usage doc gets completed during work-on-task using `wfi://docs/update-usage`
   * If NO (internal refactoring, docs-only, test-only):
     * Skip — no `ux/usage.md` needed

9. **Organize Source Idea Files (REQUIRED when drafting from ideas)**
   * **IMPORTANT**: When task is created from idea files, ALWAYS mark them as done:
   * Track all source idea files used for this draft task:
     * List all idea files referenced during behavioral specification
     * Note: Multiple idea files may be combined into one task
   * For EACH source idea file:
     * Mark idea as done using ace-idea: `ace-idea move <id> --to archive` then `ace-idea update <id> --set status=done`
       * Use the idea ID (e.g., `8ppq7w`), not a file path
       * This moves the idea to the `_archive/` folder
       * Updates idea frontmatter with completion status
   * Update task references:
     * Update the task file's References section with new idea file locations
     * Ensure all moved files are properly tracked
   * Commit the movements:
     * Use `ace-git-commit` to commit all idea file movements together
     * Clear commit message: "Mark source ideas as done after creating task"
   * **Validation Requirements:**
     * [ ] All source idea files marked as done and moved to _archive/
     * [ ] Task references updated to new locations
     * [ ] Git movements committed
   * Error handling:
     * If ace-idea move or update fails: Report error and manual intervention needed
   * Success indicators:
     * Report each file movement: "Idea marked as done: [idea-id]"
     * Confirm all source ideas organized: "All X idea files marked as done"

10. **Ensure Draft Creation Completion**
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
     * [ ] Draft is decision-complete: no unresolved behavior choices left for implementer
     * [ ] Defaults are explicit where behavior could otherwise be ambiguous
     * [ ] Usage documentation created in `ux/usage.md` (when task changes any API surface)

11. **Run Quality Pass (Better, Not More)**
   * Perform one concise quality pass before finalizing:
     * Happy path is concrete and observable
     * At least one invalid/failure path is specified
     * Unspecified behavior has explicit defaults
     * Success criteria are directly verifiable
   * Improve clarity and precision without adding specialized sections

12. **Provide Behavioral Summary**
   * List all created draft tasks with their:
     * IDs and titles
     * User experience summaries
     * Interface contracts
     * Status (draft - needs planning)
   * Suggest next step: review-task workflow to validate and promote to pending

## Key Guidelines

### Behavior-First Focus

* **What over How**: Define user experience before implementation
* **Interface Contracts**: Specify CLI/API/UI behaviors clearly
* **Success Criteria**: Measurable outcomes that define completion
* **Validation Questions**: Highlight unknowns and assumptions

### Draft Status Integration

* All tasks created have `status: draft`
* Draft indicates behavioral specification complete, readiness validation needed
* Clear handoff to review-task for readiness validation
* No mixing of behavioral and implementation concerns

### Capture-It Integration

* Enhanced ideas provide structured input for behavioral specification
* Validation questions and unknowns from ideas feed into behavioral requirements
* Optional but recommended input source
* Maintains clear separation between idea enhancement and task drafting

## ⚠️ Implementation Prohibition

**This workflow produces specification files ONLY.**

DO NOT during this phase:
- ❌ Write or modify code files (.rb, .ts, .js, etc.)
- ❌ Create implementation directories or structures
- ❌ Run tests or builds
- ❌ Make commits to project source code

All code implementation happens during `/ace-task-work` (status: in-progress).

## Input

* Enhanced ideas from ace-idea (optional but recommended)
* Direct behavioral requirements or user stories
* Interface specifications or contracts
* User experience descriptions

## Output / Success Criteria

* Draft tasks with complete behavioral specifications
* Clear interface contracts for each requirement
* Measurable success criteria defined
* All tasks have status: draft
* No implementation details mixed with behavioral requirements
* Clear handoff to review-task for readiness validation and promotion to pending
* **REQUIRED when drafting from ideas:**
  * All source idea files marked as done and moved to ideas/done/ directory
  * Task references updated to new idea file locations
  * Git movements properly committed

## Error Handling

* **Missing behavioral context**: Ask user for experience details
* **Unclear interface requirements**: Request contract examples
* **Implementation details provided**: Redirect focus to user experience
* **No current release**: Default to backlog storage with draft status

## Usage Examples

**Example 1: Capture-it integration**
> "Draft tasks from enhanced idea: .ace-taskflow/backlog/ideas/20250130-1445-oauth-authentication.md"

**Example 2: Direct behavioral requirements**
> "Create behavioral specification for: Users need secure login with OAuth support and 24-hour sessions"

**Example 3: Interface-focused requirements**
> "Draft task for CLI tool: auth-manager with login, logout, and status commands"

---

This workflow creates behavior-first specifications that serve as clear contracts for implementation, ensuring user value is defined before technical details are considered.

## Embedded Templates

<documents>
<template path="tmpl://task-management/task.draft">---
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

Why are we doing this? If this task originated from an enhanced idea,
carry forward the idea's "What I Hope to Accomplish" - that is the
authoritative intent. Add context but don't replace the original framing.

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

### Concept Inventory (Orchestrator Only)

Track concepts introduced and removed across subtasks to detect churn:

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| _example concept_ | _subtask ref_ | — | KEPT |

**Churn threshold**: If >30% of concepts introduced by subtasks get removed by later subtasks,
the decomposition was premature. Consider consolidating remaining subtasks.

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: File structures, code organization, technical architecture
- ❌ **Technology Decisions**: Tool selections, library choices, framework decisions
- ❌ **Performance Optimization**: Specific performance improvement strategies
- ❌ **Future Enhancements**: Related features or capabilities not in current scope

## References

- Usage documentation: `ux/usage.md` (draft usage scenarios)
- Related ace-idea output (if applicable)
- User experience requirements
- Interface specification examples
```
</template>
<template path="tmpl://task-management/draft-usage">
# [Feature/Change Name] - Draft Usage

## API Surface
- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: [Primary Use Case]

**Goal**: [What the user/developer/agent achieves]

```bash
[command or API call]

# Expected output:
[output]
```

### Scenario 2: [Error / Edge Case]

**Goal**: [What happens on invalid input or boundary condition]

```bash
[command or API call]

# Expected output:
[error message or behavior]
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
</template>
</documents>
