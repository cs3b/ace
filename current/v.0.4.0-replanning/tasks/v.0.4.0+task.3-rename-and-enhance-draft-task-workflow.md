---
id: v.0.4.0+task.3
status: pending
priority: high
estimate: 8h
dependencies: [v.0.4.0+task.2]
---

# Rename create-task to draft-task with Behavior-First Focus

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/workflow-instructions | grep -E "(create-task|draft-task|review-task)" | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── create-task.wf.md
    ├── review-task.wf.md
```

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
  > TEST: Structure Analysis Check
  > Type: Pre-condition Check
  > Assert: Current workflow mixes WHAT and HOW concerns
  > Command: grep -E "(implementation|file|code|function)" dev-handbook/workflow-instructions/create-task.wf.md | wc -l
* [ ] Research best practices for behavioral specification from reflections
  > TEST: Learning Integration Check
  > Type: Research Validation
  > Assert: Key patterns from task 1 and reflections are documented
  > Command: grep -E "(validation|question|unknown|assumption)" current-analysis.md
* [ ] Design new workflow structure with clear behavioral sections
* [ ] Identify all project references to create-task for immediate update

### Execution Steps
- [ ] Search for all create-task references across the project and maintain tracking list
  > TEST: Reference Discovery
  > Type: Pre-execution Check
  > Assert: All create-task references found and documented in a list
  > Command: grep -r "create-task" dev-handbook/ dev-taskflow/ docs/ --include="*.md" | grep -v "done/" > create-task-references.txt && wc -l create-task-references.txt
- [ ] Copy create-task.wf.md to draft-task.wf.md
  > TEST: File Creation Check
  > Type: Action Validation
  > Assert: New draft-task.wf.md file exists with correct content
  > Command: test -f dev-handbook/workflow-instructions/draft-task.wf.md && echo "File exists"
- [ ] Rewrite workflow goals to emphasize behavior-first approach
  - Focus on WHAT the system should do (UX/DX/AX)
  - Remove all implementation (HOW) concerns
  - Emphasize validation questions and unknowns
- [ ] Add "Behavioral Specification" mandatory section with embedded template
  - Use XML documents container per documents-embedding.g.md
  - Update task template in dev-handbook/templates/release-tasks/task.template.md
  - Embed updated template in draft-task.wf.md
  > TEST: Template Section Check
  > Type: Content Validation
  > Assert: Behavioral specification template is embedded in XML format
  > Command: grep -A5 "<documents>" dev-handbook/workflow-instructions/draft-task.wf.md
- [ ] Add "Interface Contract" definition requirements with examples
  - CLI interface examples (from ideas-manager pattern)
  - API endpoint contracts
  - UI component behaviors
- [ ] Add "Success Criteria" as mandatory first step
- [ ] Add "Integration with ideas-manager" section showing optional input
  > TEST: Integration Documentation
  > Type: Content Validation
  > Assert: ideas-manager integration example exists
  > Command: grep -A10 "ideas-manager" dev-handbook/workflow-instructions/draft-task.wf.md
- [ ] Remove all implementation-focused sections (file lists, code details)
- [ ] Update task template to always use draft status
- [ ] Add comprehensive examples from task 1 patterns
- [ ] Update all create-task references to draft-task project-wide using tracking list
  - Work through create-task-references.txt systematically
  - Update each file in the list
  - Mark off completed updates
  > TEST: Reference Update Validation
  > Type: Post-update Check
  > Assert: No create-task references remain (except historical)
  > Command: grep -r "create-task" dev-handbook/ dev-taskflow/ docs/ --include="*.md" | grep -v "done/" | grep -v "deprecat" | wc -l
- [ ] Delete create-task.wf.md after all references updated
- [ ] Update workflow README with new draft-task entry

## Scope of Work

### Deliverables

#### Create
- dev-handbook/workflow-instructions/draft-task.wf.md

#### Modify
- dev-handbook/workflow-instructions/README.md (update workflow list)
- All files with create-task references (update to draft-task)

#### Delete
- dev-handbook/workflow-instructions/create-task.wf.md (after reference updates)

## Acceptance Criteria

- [ ] Workflow focuses exclusively on WHAT not HOW
- [ ] Clear examples of behavioral specification from task 1 patterns
- [ ] Interface contract section is mandatory with CLI/API examples
- [ ] Success criteria defined before any other details
- [ ] Integration with draft status documented
- [ ] ideas-manager integration documented as optional input
- [ ] All create-task references updated project-wide
- [ ] Embedded test blocks validate all critical operations
- [ ] Validation questions and unknowns emphasized

## Example

### Scenario 1: Using ideas-manager Output as Input

**New workflow with ideas-manager:**
```bash
# Step 1: Capture idea with ideas-manager
ideas-manager capture "Add user authentication with OAuth support"
# Output: dev-taskflow/backlog/ideas/20250130-1445-oauth-authentication.md

# Step 2: Use enhanced idea as input for draft-task workflow
# For Claude Code: /draft-task dev-taskflow/backlog/ideas/20250130-1445-oauth-authentication.md
# For other agents: Read dev-handbook/workflow-instructions/draft-task.wf.md and follow steps
```

The draft-task workflow reads the enhanced idea which already contains:
- Validated questions and unknowns
- Initial problem statement
- Preliminary solution directions

This provides structured input for creating a behavior-first task specification.

### Scenario 2: Converting Existing Task Creation to Behavior-First Approach

**Current workflow usage:**
```bash
# Old create-task approach (mixed what/how)
# For Claude Code: /create-task "Add user authentication system"
# For other agents: Read and follow create-task.wf.md
```

**New draft-task workflow usage:**
```bash
# New behavior-first approach
# For Claude Code: /draft-task "Add user authentication system"
# For other agents: Read and follow draft-task.wf.md
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
- No structured validation questions

**After (draft-task):**
- Pure behavioral specification
- Clear interface contracts with examples
- Draft status indicates need for implementation planning
- Behavior-first approach ensures user value is defined upfront
- Validation questions and unknowns prominently featured
- Optional integration with ideas-manager for structured input
- Embedded test blocks for workflow validation

## Out of Scope

- ❌ Implementation planning details (belongs to plan-task workflow - task 4)
- ❌ Tool selection or file lists
- ❌ Technical architecture decisions
- ❌ Dependency analysis
- ❌ Changes to review-task workflow (handled in task 4)

## Behavioral Specification Template Update

The task template in `dev-handbook/templates/release-tasks/task.template.md` should be enhanced with:

```markdown
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
```

## References

- Blueprint Generator concept from research
- Current create-task.wf.md workflow
- Task template structure
- v.0.4.0+task.1 patterns for behavioral specification
- Reflection: 20250730-113043-task-review-enhancement-session.md
- Reflection: 20250730-180723-task-reopening-and-test-integrity-session.md
- Guide: dev-handbook/guides/documents-embedding.g.md