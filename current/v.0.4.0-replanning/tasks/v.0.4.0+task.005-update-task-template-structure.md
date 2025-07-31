---
id: v.0.4.0+task.5
status: pending
priority: high
estimate: 4h
dependencies: [v.0.4.0+task.3, v.0.4.0+task.4]
---

# Update Task Template with Clear What/How Sections

## Objective

Redesign the task template (`task.template.md`) to clearly separate behavioral specification (WHAT) from implementation details (HOW), supporting the new
specification cycle architecture. The template should guide users to think behavior-first and defer implementation planning.

## What: Behavioral Specification

### User Experience

* **Template Users**: Developers and AI agents creating tasks
* **Structure**: Clear sections that enforce behavior-first thinking
* **Guidance**: Inline comments explaining what belongs in each section

### Expected Behavior

1.  Template starts with behavioral specification sections
2.  Success criteria and interface contracts come before implementation
3.  Clear separation between WHAT and HOW sections
4.  Implementation sections can be left empty in draft state
5.  Inline guidance helps users fill sections correctly

### New Template Structure

```markdown
## What: Behavioral Specification
### Expected Behavior
### Interface Contract  
### Success Criteria

## How: Implementation Plan
### Planning Steps
### Execution Steps
```

## Technical Approach

### Architecture Pattern
- [ ] Template restructuring approach: Move from implementation-first to behavior-first design
- [ ] Integration with specification cycle: Draft -> Review -> Plan workflow phases
- [ ] Impact on system design: Clear separation between behavioral specification and technical implementation

### Technology Stack
- [ ] Markdown template format with embedded comments for guidance
- [ ] Template inheritance compatibility with existing task.pending.template.md structure
- [ ] Version control preservation through backup creation
- [ ] Documentation synchronization with handbook sync-templates command

### Implementation Strategy
- [ ] Phase 1: Analysis and backup of current template
- [ ] Phase 2: Restructure template with What/How separation
- [ ] Phase 3: Add inline guidance and examples
- [ ] Phase 4: Test with sample task creation and validation

## Tool Selection

| Criteria | Current Template | New What/How Template | Selected |
|----------|------------------|----------------------|----------|
| Behavior-First | Poor | Excellent | New Template |
| Implementation Planning | Good | Excellent | New Template |
| User Guidance | Fair | Excellent | New Template |
| Workflow Integration | Good | Excellent | New Template |
| Incremental Usage | Poor | Excellent | New Template |

**Selection Rationale:** The new What/How template enforces behavior-first thinking, provides better user guidance, and supports incremental task creation aligned with the specification cycle architecture.

### Dependencies
- [ ] Current task.pending.template.md as baseline structure
- [ ] Template synchronization system (handbook sync-templates)
- [ ] Backup directory structure in dev-handbook/templates/task-management/

## File Modifications

### Create
- dev-handbook/templates/task-management/task.template.md
  - Purpose: New behavior-first task template with What/How sections
  - Key components: Behavioral specification sections, implementation planning sections, inline guidance
  - Dependencies: Based on task.pending.template.md structure

### Modify
- N/A (creating new template rather than modifying existing)

### Delete
- N/A (preserving existing templates as alternatives)

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work.*

### Planning Steps

*Research, analysis, and design activities that help clarify the approach before implementation begins.*

- [ ] Analyze current task.pending.template.md structure and identify reusable components
  > TEST: Template Analysis Complete
  > Type: Pre-condition Check
  > Assert: Current template structure documented and reusable components identified
  > Command: grep -E "^##|^###" dev-handbook/templates/task-management/task.pending.template.md
- [ ] Research behavioral specification best practices from software engineering
- [ ] Design section hierarchy prioritizing behavioral specification over implementation
- [ ] Create inline documentation strategy with examples and guidance comments
- [ ] Plan template testing approach with sample task scenarios

### Execution Steps

*Concrete implementation actions that modify code, create files, or change the system state.*

- [ ] Create new task.template.md based on task.pending.template.md structure
- [ ] Restructure template with "What: Behavioral Specification" as primary section
  > TEST: What Section Structure
  > Type: Action Validation
  > Assert: Template contains What section with Expected Behavior, Interface Contract, Success Criteria subsections
  > Command: grep -A 10 "## What:" dev-handbook/templates/task-management/task.template.md
- [ ] Add "Expected Behavior" subsection with inline guidance and examples
- [ ] Add "Interface Contract" subsection with API/interface specification guidance
- [ ] Move "Objective" content into What section as behavioral context
- [ ] Restructure "How: Implementation Plan" section with Planning and Execution subsections
- [ ] Add inline comments explaining the purpose of each section
- [ ] Include example content demonstrating proper usage patterns
- [ ] Add template validation checklist as comments
- [ ] Test template by creating sample authentication feature task
  > TEST: Template Functionality
  > Type: Action Validation
  > Assert: Sample task created successfully demonstrates behavior-first approach
  > Command: test -f dev-handbook/templates/task-management/sample-auth-task.md

## Risk Assessment

### Technical Risks
- **Risk:** Template structure incompatibility with existing workflow tools
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Base new template on proven task.pending.template.md structure
  - **Rollback:** Revert to task.pending.template.md as task.template.md

### Integration Risks
- **Risk:** User confusion during transition from old to new template structure
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Provide comprehensive inline guidance and examples
  - **Monitoring:** Track task creation patterns and user feedback

### Performance Risks
- **Risk:** Template sync performance impact from additional comments
  - **Mitigation:** Keep inline guidance concise and structured
  - **Monitoring:** handbook sync-templates execution time
  - **Thresholds:** < 2 second increase in sync time

## Scope of Work

### Deliverables

#### Modify

* dev-handbook/templates/release-tasks/task.template.md

#### Create

* dev-handbook/templates/release-tasks/task.template.old.md (backup)

## Acceptance Criteria

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Template enforces behavior-first thinking
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Clear separation between What and How
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Inline guidance helps correct usage
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Sections can be incrementally filled
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Compatible with specification cycle phases
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Examples demonstrate proper usage

## Example

### Scenario 1: Creating a Feature Task

A developer creating a new authentication feature task would use the template:

1.  **What Section First**: Start by defining expected behavior \`\`\`markdown
```markdown
## What: Behavioral Specification

### Expected Behavior

* Users can log in with email/password
* Failed attempts show clear error messages
* Session persists across browser tabs
### Interface Contract

* POST /auth/login accepts \{email, password}
* Returns JWT token on success
* Returns 401 with error message on failure
### Success Criteria

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />User can authenticate successfully
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Invalid credentials are rejected
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Session management works correctly \`\`\`
{: .task-list}

2.  **How Section Later**: Implementation details come after behavior is clear \`\`\`markdown
## How: Implementation Plan

### Planning Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Design authentication flow
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Choose JWT library
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Plan database schema changes
{: .task-list}

### Execution Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Create login endpoint
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Implement password validation
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add JWT token generation
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Create session middleware \`\`\`
{: .task-list}

### Scenario 2: Draft Task Creation

During initial brainstorming, a task can be created with only the What section:

## What: Behavioral Specification
### Expected Behavior
- System should automatically backup user data
- Backups should be encrypted and secure
- Users should be notified of backup status

### Interface Contract
<!-- TODO: Define API contracts -->

### Success Criteria
- [ ] Data is backed up regularly
- [ ] Backups are encrypted
- [ ] Users receive notifications

## How: Implementation Plan
<!-- Implementation details to be planned later -->
```

This allows behavior-first thinking while deferring technical decisions until the specification phase is complete.

## Out of Scope

* ❌ Multiple template variants
* ❌ Automated template selection
* ❌ Migration of existing tasks
* ❌ Template validation tooling

## References

* Current task template
* Specification cycle architecture
* Behavioral specification principles