---
name: task-plan
allowed-tools: Bash, Read
description: Create a cache-backed implementation plan artifact with freshness checks and anchored execution checklist output
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2026-03-03'
---

# Plan Task Workflow Instruction

## Goal

Create a JIT (just-in-time) implementation plan for a pending task. The plan is returned as inline output. The calling system handles caching and persistence. It does NOT modify task spec files or change task status. Focus exclusively on the HOW (technical implementation approach) rather than the WHAT (behavioral requirements).

## Planning Phase Context

**This workflow produces a complete implementation plan as inline output.**

- The calling system handles persistence (cache artifacts, pointers, freshness)
- Does NOT modify task specification files
- Does NOT change task status
- Plan is consumed by the next phase (work-on-task) or by the developer

This workflow can be invoked standalone for ad-hoc planning or as a phase within ace-assign.

## Output Contract

Output the complete plan as your response. Do NOT write files, use Bash, or attempt cache operations.

The plan will be consumed by a separate execution agent that has no access to this system prompt or project context. Therefore the plan must be:
- **Complete**: Fill out ALL applicable templates (Technical Approach, File Modifications, Anchored Checklist)
- **Self-contained**: Include all file paths, code references, and context needed for execution

## Prerequisites

- Task file exists with **pending** status (validated by review-task)
- Task must have clear behavioral requirements from draft-task workflow
- Understanding of project context and architecture
- Access to recent git history and project status
- Load project context

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## Task Type Considerations

**Code Implementation Tasks** (Full workflow applies including test planning):
- New features with business logic
- API endpoints and services
- Data processing and transformation
- Authentication and authorization systems
- Integration with external services

**Documentation/Workflow Tasks** (Skip test planning steps):
- Creating or updating documentation
- Workflow instruction development
- Guide and template creation
- Process documentation
- Configuration documentation

**Mixed Tasks** (Apply test planning selectively):
- Configuration with validation logic
- CLI tools with complex functionality
- Templates with embedded logic
- Build and deployment scripts


## Process Steps

1. **Load and Analyze Pending Task:**
   - **Task Selection:**
     - If specific task provided: Use the provided task path
     - If no task specified: Run `ace-task list --status pending` to get pending tasks
     - Document the selected task path for reference
   - **Load Task Content:**
     - Read the task file from the identified path
     - Verify task has `status: pending`
     - Parse the structure and extract:
       - Behavioral specification (User Experience, Interface Contract, Success Criteria)
       - Existing scope and deliverables
       - Any existing implementation notes
   - **Capture Freshness Inputs:**
     - Build the freshness input set from the task file and loaded context files (`bundle.files`, plus optional usage/docs/research files read during planning)
     - If any freshness input is missing, flag the plan as stale with an explicit gap note
     - If any freshness input mtime is newer than the candidate plan, treat the plan as stale
     - Default stale behavior: automatically regenerate (no interactive prompt)
   - **Load Usage Context (if present):**
     - Check for `ux/usage.md` in the task directory
     - If it exists, read it as additional behavioral context — usage scenarios serve as acceptance criteria for the implementation plan
   - **Plan Against Behavioral Spec Structure:**
     - Treat the behavioral spec as the planning checklist, not background context
     - Explicitly cover each section in the plan: Interface Contract, Error Handling, Edge Cases, Success Criteria
     - Ensure the plan covers operating modes defined by the spec (dry-run, force, verbose, quiet) when relevant
     - If the spec omits information needed for implementation, add a `Behavioral Gaps` section at the end of the plan rather than silently working around omissions
   - **Enumerate Paths Separately for Shared-Behavior Specs:**
     - If the spec says "same behavior" across multiple paths, list each path explicitly in the plan
     - Note per-path divergences (guard logic, dry-run interaction, error handling differences, parameter differences)
     - Do not assume one path's implementation automatically generalizes to all others

2. **Technical Research Phase:**

   **Architecture Pattern Analysis:**
   - Review existing project patterns and identify best fit
   - Analyze how this feature integrates with current architecture
   - Document architectural decisions and rationale

   **Technology Stack Research:**
   - Research available libraries, frameworks, and tools
   - Evaluate performance implications and compatibility
   - Consider version requirements and dependencies

   **Implementation Approach Investigation:**
   - Research industry best practices for this type of feature
   - Analyze similar implementations in the codebase
   - Identify proven patterns and anti-patterns

   **Naming Consistency Analysis:**
   - For rename/refactoring tasks, analyze comprehensive scope:
     - Search for all files and directories containing the old name
     - Identify library structure patterns that need renaming
     - Check test file naming conventions and related test assets
     - Review module and class naming throughout the codebase
   - Document the full renaming scope to prevent partial migrations

   **Cross-Package Reference Audit:**
   - For rename/namespace/migration tasks that change URIs, paths, or identifiers:
     - Run `ace-search "old-pattern" --content --hidden` for each pattern being changed (e.g., `wfi://lint`, `skill://as-lint-run`, file paths)
     - Group results by package to understand cross-package impact
     - Count total references: flag as **HIGH RISK** if >20 references across >3 packages
     - Include all reference-update work in subtask decomposition — do not treat as follow-up
   - For interface changes (CLI flags, config keys, method signatures):
     - Search for all consumers: `ace-search "method_or_key_name" --content --hidden`
     - List consumer packages that will need coordinated updates
   - Document the full downstream scope before implementation begins

   **Document Research Findings:**
   - Summarize key technical insights
   - Note recommended approaches with pros/cons
   - Identify potential technical risks and mitigation strategies

3. **Tool Selection:**

   Evaluate tools/libraries against: performance requirements, integration with existing stack, maintenance considerations, and team expertise.

   **Tool Decision:** Selected tool/library, rationale, and key trade-offs.

   **Dependency Analysis:**
   - List all new dependencies required
   - Verify compatibility with existing dependencies
   - Document any potential conflicts or risks

4. **File Modification Planning:**

   **Create Files:**
   - List all new files to be created with purpose and key components
   - Define file structure and organization
   - Plan directory structure if needed

   **Modify Files:**
   - Identify existing files requiring changes
   - Document specific modifications and their impact
   - Plan integration points and interfaces

   **Delete Files:**
   - Identify obsolete files to be removed
   - Document reasons for removal
   - Check dependencies before deletion

   **Naming Consistency Analysis:**
   - When renaming commands, tools, or components, identify ALL related items:
     - Executable/command files
     - Library directory structures (e.g., `lib/.../old_name/` to `lib/.../new_name/`)
     - Test file patterns (e.g., `old_name_spec.rb` to `new_name_spec.rb`)
     - Test fixture/cassette directories
     - Module and class names in code
     - Import/require statements throughout codebase
     - Documentation references in markdown files
     - Configuration file references

5. **Test Case Planning:** *(For code implementation tasks only)*

   **Note:** This step applies when the task involves code implementation (new features, APIs, business logic, etc.). Skip for documentation, workflow, or configuration-only tasks.

   **Analyze Testing Requirements:**
   - Review behavioral specification for testable components
   - Identify input validation rules, business logic flows, output expectations
   - Determine error scenarios and integration points
   - Consider performance and security requirements

   **Scenario Identification:**

   **Happy Path Scenarios:**
   - Standard expected usage patterns
   - Primary user workflows and interactions

   **Edge Case Scenarios:**
   - Boundary values (minimum/maximum limits)
   - Empty, null, or missing inputs
   - Special characters and unusual data formats

   **Error Condition Scenarios:**
   - Invalid input validation failures
   - Missing required data or parameters
   - External service failures or unavailability

   **Test Prioritization:**
   - **High Priority:** Core business logic, security-critical features, user-facing functionality
   - **Medium Priority:** Secondary features, admin functions, performance optimizations
   - **Low Priority:** Nice-to-have features, rare edge cases, internal utilities

6. **Implementation Steps Planning:**

   **Detailed Step Breakdown:**
   - Create specific, actionable implementation steps
   - Order steps logically with dependencies
   - Include validation and testing at each step
   - Integrate test implementation alongside code implementation

   **Embedded Test Planning:**
   - Design test blocks for critical operations using planned test scenarios
   - Plan verification commands for each step based on test case analysis
   - Include test execution validation at key implementation points
   - Include rollback verification where needed

7. **Risk Assessment:**

   **Primary Risk:** Description of the most significant risk
   - **Mitigation:** Strategy to reduce or avoid the risk
   - **Rollback:** Steps to undo if the risk materializes

   Include additional risks only if they are significant and distinct from the primary risk.

8. **Implementation Plan Assembly:**

   Assemble the complete plan output covering:
   - Technical approach and architecture decisions
   - File modification plan
   - Implementation steps with embedded tests
   - Risk assessment with mitigation
   - Test strategy (for code tasks)

   Output the assembled plan following the REPORT section format below.

   **Plan Output Schema (Anchored Checklist)**
   - Each step has a stable ID (for example: `STEP-01`)
   - Each step includes at least one `path:line` anchor back to the behavioral spec
   - Each step includes explicit dependencies (`depends_on: []` when none)
   - Each step includes one or more verification commands
   - Include a freshness summary that lists tracked input files and stale/fresh determination

   **UX/Usage Documentation Note**
   For user-facing features (commands, CLI tools, APIs, workflows), draft usage documentation (`ux/usage.md`) with key scenarios is created during the draft phase. The full usage documentation is completed during implementation (work-on-task phase) using `wfi://docs/update-usage`.

## Implementation Planning Templates

The following templates may be used when structuring planning output:

### Technical Approach Template

```markdown
## Technical Approach

### Architecture Pattern
- [ ] Pattern selection and rationale
- [ ] Integration with existing architecture
- [ ] Impact on system design

### Technology Stack
- [ ] Libraries/frameworks needed
- [ ] Version compatibility checks
- [ ] Performance implications
- [ ] Security considerations
```

### File Modification Template

```markdown
## File Modifications

### Create
- path/to/new/file.ext
  - Purpose: [why this file]
  - Key components: [what it contains]
  - Dependencies: [what it depends on]

### Modify
- path/to/existing/file.ext
  - Changes: [what to modify]
  - Impact: [effects on system]
  - Integration points: [how it connects]

### Delete
- path/to/obsolete/file.ext
  - Reason: [why removing]
  - Dependencies: [what depends on this]
  - Migration strategy: [how to handle removal]

### Rename (for comprehensive migrations)
- old/path/name.ext → new/path/name.ext
  - Type: [file/directory/both]
  - Related renames:
    - Library directories: `lib/old_name/` → `lib/new_name/`
    - Test files: `*old_name*.rb` → `*new_name*.rb`
    - Module/class names: `OldName` → `NewName`
  - Import updates: [number of files with require/import statements]
  - Documentation updates: [number of markdown files with references]
```

## Content Transformation Guidelines

When planning from a behavioral spec:

**Input (WHAT concerns from behavioral spec):**
- User experience requirements
- Interface contracts
- Success criteria
- Validation questions and answers

**Output (HOW concerns for implementation):**
- Technical approach analysis
- Implementation strategy with steps
- Tool and library selection
- File modification planning
- Risk assessment and mitigation
- Test strategy

## Output / Success Criteria

- Complete plan is returned as inline response following the REPORT format
- NO task file modifications
- NO status changes
- Complete technical implementation plan with specific steps
- All tools and libraries selected with rationale
- File modification plan with detailed impact analysis
- Risk assessment with mitigation strategies
- Embedded tests for critical operations
- Clear integration with existing architecture
- Anchored checklist format includes step IDs, `path:line` anchors, dependencies, and verification commands
- Freshness metadata includes task file + loaded context files

## Common Patterns

### New Feature Implementation
- Start with architecture integration analysis
- Focus on data flow and state management
- Plan comprehensive testing strategy
- Consider performance implications early

### Refactoring Implementation
- Document current state thoroughly
- Plan incremental transformation steps
- Emphasize backward compatibility
- Create extensive rollback procedures

### Integration Implementation
- Focus on interface compatibility
- Plan configuration management
- Emphasize error handling and recovery
- Document external dependencies

## Usage Example

**Input:** Pending task with validated behavioral specification
> "Plan implementation for task .ace-tasks/v.0.9.0/tasks/task-dir/task.s.md (status: pending)"

**Process:** Technical research, tool selection, implementation planning

**Output:** Complete implementation plan as inline response (no file writes)

---

This workflow creates JIT implementation plans that guide the work-on-task phase, returning complete inline plans without modifying task specifications or changing task status.

## REPORT

Your response IS the plan artifact. Output it directly — do not write files or use tools.

This plan will be passed to a separate execution agent that has NO access to:
- This system prompt
- The project context
- The task specification (unless you include relevant parts)

Therefore the plan MUST be **complete and self-contained**:

### Required sections

Use these exact markdown headings in this order:

1. **`## Task Summary`** — what is being implemented and why (brief, from the spec)
2. **`## Execution Context`** — minimum project context the work agent needs:
   - Key conventions and patterns relevant to THIS task
   - Relevant architectural constraints
   - Package/gem boundaries crossed
   - Non-obvious project rules affecting this work
3. **`## Technical Approach`** — fill out the Technical Approach template (architecture, stack, strategy)
4. **`## File Modifications`** — fill out the File Modification template (Create/Modify/Delete with paths, purpose, impact)
5. **`## Plan Checklist`** — anchored checklist (STEP-01, STEP-02...) with:
   - `path:line` anchors to relevant source files
   - Explicit dependencies (`depends_on: []`)
   - Verification commands per step
6. **`## Test Plan`** — test scenarios and files (for code tasks; skip for docs/workflow tasks)
7. **`## Risk Assessment`** — primary risk, mitigation, rollback
8. **`## Freshness Summary`** — tracked input files and their state

If needed, add **`## Behavioral Gaps`** only after `## Freshness Summary`.

### Format rules

- Use the embedded templates from `<documents>` section to structure each part
- Every implementation step must be actionable without additional context
- Include exact file paths, method names, and line references where applicable
- Do not summarize or abbreviate — the execution agent needs full detail
- Never ask for permissions/approvals or output escalation requests
- Never return status-only text such as "plan delivered" without the required sections

<documents>
    <template path="tmpl://task-management/task.technical-approach">## Technical Approach

### Architecture Pattern
- [ ] Pattern selection and rationale
- [ ] Integration with existing architecture
- [ ] Impact on system design

### Technology Stack
- [ ] Libraries/frameworks needed
- [ ] Version compatibility checks
- [ ] Performance implications
- [ ] Security considerations

### Implementation Strategy
- [ ] Step-by-step approach
- [ ] Rollback considerations
- [ ] Testing strategy
- [ ] Performance monitoring
</template>

    <template path="tmpl://task-management/task.file-modification-checklist">## File Modifications

### Create
- path/to/new/file.ext
  - Purpose: [why this file]
  - Key components: [what it contains]
  - Dependencies: [what it depends on]

### Modify
- path/to/existing/file.ext
  - Changes: [what to modify]
  - Impact: [effects on system]
  - Integration points: [how it connects]

### Delete
- path/to/obsolete/file.ext
  - Reason: [why removing]
  - Dependencies: [what depends on this]
  - Migration strategy: [how to handle removal]

### Rename (for comprehensive migrations)
- old/path/name.ext → new/path/name.ext
  - Type: [file/directory/both]
  - Related renames:
    - Library directories: `lib/old_name/` → `lib/new_name/`
    - Test files: `*old_name*.rb` → `*new_name*.rb`
    - Module/class names: `OldName` → `NewName`
  - Import updates: [number of files with require/import statements]
  - Documentation updates: [number of markdown files with references]
</template>

    <template path="tmpl://task-management/task.plan-anchored-checklist">## Plan Checklist

### STEP-01
- **Anchor**: path/to/task.s.md:42
- **Depends On**: []
- **Action**: [what to implement]
- **Verification**:
  - `ace-lint path/to/file`

### STEP-02
- **Anchor**: path/to/task.s.md:58
- **Depends On**: [STEP-01]
- **Action**: [next implementation action]
- **Verification**:
  - `ace-test path/to/test_file.rb`
</template>

</documents>
