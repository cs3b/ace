---
id: v.0.4.0+task.5
status: draft
priority: high
estimate: 4h
dependencies: [v.0.4.0+task.3, v.0.4.0+task.4]
---

# Update Task Template with Clear What/How Sections

## Objective

Redesign the task template (`task.template.md`) to clearly separate behavioral specification (WHAT) from implementation details (HOW), supporting the new specification cycle architecture. The template should guide users to think behavior-first and defer implementation planning.

## What: Behavioral Specification

### User Experience
- **Template Users**: Developers and AI agents creating tasks
- **Structure**: Clear sections that enforce behavior-first thinking
- **Guidance**: Inline comments explaining what belongs in each section

### Expected Behavior
1. Template starts with behavioral specification sections
2. Success criteria and interface contracts come before implementation
3. Clear separation between WHAT and HOW sections
4. Implementation sections can be left empty in draft state
5. Inline guidance helps users fill sections correctly

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
* [ ] Review current template pain points
* [ ] Study behavioral specification best practices
* [ ] Design section hierarchy and flow
* [ ] Create inline documentation strategy

### Execution Steps
- [ ] Backup current task.template.md
- [ ] Restructure template with What/How sections
- [ ] Add "Expected Behavior" subsection under What
- [ ] Add "Interface Contract" subsection under What
- [ ] Move "Objective" into What section
- [ ] Move "Implementation Plan" into How section
- [ ] Add inline comments explaining each section
- [ ] Update section descriptions for clarity
- [ ] Add examples within template comments
- [ ] Test template with sample task creation

## Scope of Work

### Deliverables

#### Modify
- dev-handbook/templates/release-tasks/task.template.md

#### Create
- dev-handbook/templates/release-tasks/task.template.old.md (backup)

## Acceptance Criteria

- [ ] Template enforces behavior-first thinking
- [ ] Clear separation between What and How
- [ ] Inline guidance helps correct usage
- [ ] Sections can be incrementally filled
- [ ] Compatible with specification cycle phases
- [ ] Examples demonstrate proper usage

## Example

### Scenario 1: Creating a Feature Task

A developer creating a new authentication feature task would use the template:

1. **What Section First**: Start by defining expected behavior
   ```markdown
   ## What: Behavioral Specification
   ### Expected Behavior
   - Users can log in with email/password
   - Failed attempts show clear error messages
   - Session persists across browser tabs
   
   ### Interface Contract
   - POST /auth/login accepts {email, password}
   - Returns JWT token on success
   - Returns 401 with error message on failure
   
   ### Success Criteria
   - [ ] User can authenticate successfully
   - [ ] Invalid credentials are rejected
   - [ ] Session management works correctly
   ```

2. **How Section Later**: Implementation details come after behavior is clear
   ```markdown
   ## How: Implementation Plan
   ### Planning Steps
   - [ ] Design authentication flow
   - [ ] Choose JWT library
   - [ ] Plan database schema changes
   
   ### Execution Steps
   - [ ] Create login endpoint
   - [ ] Implement password validation
   - [ ] Add JWT token generation
   - [ ] Create session middleware
   ```

### Scenario 2: Draft Task Creation

During initial brainstorming, a task can be created with only the What section:

```markdown
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

- ❌ Multiple template variants
- ❌ Automated template selection
- ❌ Migration of existing tasks
- ❌ Template validation tooling

## References

- Current task template
- Specification cycle architecture
- Behavioral specification principles