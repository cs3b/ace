# Draft Task - Behavior-First Specification

## Goal

Create high-level behavioral specifications that define WHAT the system should do (UX/DX/AX) rather than HOW to implement it. This workflow transforms ideas or requirements into behavior-first draft tasks with clear interface contracts, leaving implementation details for the replan phase.

## Prerequisites

* Enhanced ideas or direct requirements (optional input from ideas-manager)
* Understanding of user experience and interface requirements
* Access to `dev-taskflow/` directory for task storage
* Higher-order navigation tools available (nav-path)

## Project Context Loading

* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`
* Load tools documentation: `docs/tools.md`

## Process Steps

1. **Gather Behavioral Requirements**
   * Collect input material focusing on user experience:
     * Direct behavioral requirements from user
     * Enhanced ideas from ideas-manager output
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
   * Use examples from existing tools (like ideas-manager pattern)
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
     * Use `create-path task-new --title "Task Title" --priority high --estimate "TBD"` to:
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
     * Integration with ideas-manager if applicable
   * Avoid adding implementation details

8. **Ensure Draft Creation Completion**
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

9. **Provide Behavioral Summary**
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

### Ideas-Manager Integration

* Enhanced ideas provide structured input for behavioral specification
* Validation questions and unknowns from ideas feed into behavioral requirements
* Optional but recommended input source
* Maintains clear separation between idea enhancement and task drafting

## Input

* Enhanced ideas from ideas-manager (optional but recommended)
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

## Error Handling

* **Missing behavioral context**: Ask user for experience details
* **Unclear interface requirements**: Request contract examples
* **Implementation details provided**: Redirect focus to user experience
* **No current release**: Default to backlog storage with draft status

## Usage Examples

**Example 1: Ideas-manager integration**
> "Draft tasks from enhanced idea: dev-taskflow/backlog/ideas/20250130-1445-oauth-authentication.md"

**Example 2: Direct behavioral requirements**
> "Create behavioral specification for: Users need secure login with OAuth support and 24-hour sessions"

**Example 3: Interface-focused requirements**
> "Draft task for CLI tool: auth-manager with login, logout, and status commands"

---

This workflow creates behavior-first specifications that serve as clear contracts for implementation, ensuring user value is defined before technical details are considered.

## Embedded Templates

<documents>
<template path="dev-handbook/templates/release-tasks/task.template.md">---
id: {id}
status: draft
priority: {priority}
estimate: TBD
dependencies: {dependencies}
---

# {title}

## Behavioral Specification

### User Experience
- **Input**: [What users provide]
- **Process**: [What users experience during interaction]
- **Output**: [What users receive]

### Expected Behavior
[Describe WHAT the system should do, not HOW]

### Interface Contract
```bash
# CLI Interface (if applicable)
command-name [options] <arguments>

# API Interface (if applicable)
GET/POST/PUT/DELETE /endpoint
```

### Success Criteria

- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]

### Validation Questions

- [ ] Question about unclear requirements?
- [ ] Question about edge cases?  
- [ ] Question about user expectations?

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

Why are we doing this? Focus on user value and behavioral outcomes.

## Scope of Work

- Behavioral requirement 1 (user experience focused)
- Behavioral requirement 2 (interface contract focused)

### Deliverables

#### Interface Contracts
- CLI command specifications
- API endpoint definitions
- UI component behaviors

#### Behavioral Documentation
- User experience flows
- Success criteria definitions
- Validation question resolutions

## Out of Scope

- ❌ Implementation details (file structures, code organization)
- ❌ Technical architecture decisions
- ❌ Tool or library selections
- ❌ Performance optimization strategies

## References

- Related ideas-manager output (if applicable)
- User experience requirements
- Interface specification examples
```
</template>
</documents>