* * *

id: v.0.4.0+task.5 status: draft priority: high estimate: 4h dependencies: \[v.0.4.0+task.3, v.0.4.0+task.4\] ---

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

## How: Implementation Plan

### Planning Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Review current template pain points
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Study behavioral specification best practices
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Design section hierarchy and flow
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Create inline documentation strategy

### Execution Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Backup current task.template.md
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Restructure template with What/How sections
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add "Expected Behavior" subsection under What
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add "Interface Contract" subsection under What
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Move "Objective" into What section
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Move "Implementation Plan" into How section
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add inline comments explaining each section
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Update section descriptions for clarity
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add examples within template comments
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Test template with sample task creation

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