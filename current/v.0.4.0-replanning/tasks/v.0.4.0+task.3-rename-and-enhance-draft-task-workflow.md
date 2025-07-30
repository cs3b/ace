---
id: v.0.4.0+task.3
status: draft
priority: high
estimate: 6h
dependencies: [v.0.4.0+task.2]
---

# Rename create-task to draft-task with Behavior-First Focus

## Objective

Transform the existing `create-task.wf.md` workflow into `draft-task.wf.md` with a fundamental shift to behavior-first specification. This workflow becomes the Blueprint Generator phase, focusing on WHAT the system should do (UX/DX/AX) rather than HOW to implement it.

## What: Behavioral Specification

### User Experience
- **Input**: Enhanced ideas or direct requirements
- **Process**: Create high-level natural language task specifications
- **Output**: Draft tasks with clear behavioral contracts and interface definitions

### Expected Behavior
1. Focus on end-user experience and interfaces first
2. Define success criteria before implementation details
3. Specify public APIs, CLI interfaces, or UI behaviors
4. Leave implementation details for the replan phase
5. Create tasks in "draft" status for further planning

### Key Transformation
- **FROM**: Mixing what and how in a single pass
- **TO**: Pure behavioral specification with interface contracts
- **Result**: Clear handoff to implementation planning phase

## How: Implementation Plan

### Planning Steps
* [ ] Analyze current create-task.wf.md structure and pain points
* [ ] Research best practices for behavioral specification
* [ ] Design new workflow structure with clear sections
* [ ] Plan migration strategy for existing workflow users

### Execution Steps
- [ ] Copy create-task.wf.md to draft-task.wf.md
- [ ] Rewrite workflow goals to emphasize behavior-first approach
- [ ] Add "Behavioral Specification" section to process steps
- [ ] Include "Interface Contract" definition requirements
- [ ] Add "Success Criteria" as mandatory first step
- [ ] Remove implementation-focused sections
- [ ] Update task template references to use draft status
- [ ] Add examples of good behavioral specifications
- [ ] Create deprecation notice in create-task.wf.md

## Scope of Work

### Deliverables

#### Create
- dev-handbook/workflow-instructions/draft-task.wf.md

#### Modify
- dev-handbook/workflow-instructions/create-task.wf.md (add deprecation notice)
- dev-handbook/workflow-instructions/README.md (update workflow list)

## Acceptance Criteria

- [ ] Workflow focuses exclusively on WHAT not HOW
- [ ] Clear examples of behavioral specification
- [ ] Interface contract section is mandatory
- [ ] Success criteria defined before any other details
- [ ] Integration with draft status documented
- [ ] Migration path from create-task clear

## Example

### Scenario: Converting Existing Task Creation to Behavior-First Approach

**Current workflow usage:**
```bash
# Old create-task approach (mixed what/how)
workflow create-task "Add user authentication system"
```

**New draft-task workflow usage:**
```bash
# New behavior-first approach
workflow draft-task "Add user authentication system"
```

### Step-by-Step Process

1. **Behavioral Specification Phase**
   - Define what users experience: "Users can securely log in and access protected features"
   - Specify interface contracts: API endpoints, CLI commands, UI components
   - Set success criteria: "Users can authenticate within 3 seconds, sessions persist for 24 hours"

2. **Draft Task Creation**
   ```markdown
   ---
   id: v.0.5.0+task.15
   status: draft
   priority: high
   estimate: TBD
   ---
   
   # Add User Authentication System
   
   ## Behavioral Specification
   
   ### User Experience
   - Users see a login form with email/password fields
   - Invalid credentials show clear error messages
   - Successful login redirects to dashboard
   - Sessions automatically expire after 24 hours
   
   ### Interface Contract
   ```bash
   # CLI Interface
   auth-manager login --email user@example.com
   auth-manager logout
   auth-manager status
   
   # API Interface
   POST /api/auth/login
   DELETE /api/auth/logout
   GET /api/auth/status
   ```
   
   ### Success Criteria
   - [ ] Users can log in with valid credentials
   - [ ] Invalid attempts are blocked with helpful messages
   - [ ] Sessions persist across browser refreshes
   - [ ] Logout completely clears session data
   ```

3. **Handoff to Implementation Planning**
   - Task remains in "draft" status
   - Implementation details handled in separate replan phase
   - Clear interface contract enables parallel development

### Before/After Comparison

**Before (create-task):**
- Mixed behavioral requirements with implementation details
- Unclear separation between what and how
- Tasks ready for immediate implementation (often incomplete)

**After (draft-task):**
- Pure behavioral specification
- Clear interface contracts
- Draft status indicates need for implementation planning
- Behavior-first approach ensures user value is defined upfront

## Out of Scope

- ❌ Implementation planning details
- ❌ Tool selection or file lists
- ❌ Technical architecture decisions
- ❌ Dependency analysis

## References

- Blueprint Generator concept from research
- Current create-task.wf.md workflow
- Task template structure