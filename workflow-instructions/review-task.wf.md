# Review Task Workflow Instruction

## Goal

Review and refine a task definition, potentially proposing an implementation approach or solution, ensuring it aligns with project goals, architecture, and recent changes. Identify areas requiring user feedback or further clarification.

## Prerequisites

- Task file exists in markdown format
- Understanding of project context and architecture
- Access to recent git history and project status

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

## Process Steps

1. **Load Task Content:**
   - Read the task file from the provided path
   - Parse the structure:

     ```yaml
     ---
     id: v.X.Y.Z+task.N
     status: [pending | in-progress | done | blocked]
     priority: [high | medium | low]
     estimate: Nh
     dependencies: []
     ---
     ```

   - Extract key sections:
     - Objective and description
     - Scope of work and deliverables
     - Implementation plan structure
     - Acceptance criteria
     - Out of scope items

2. **Review Task Against Context:**

   **Project Alignment Check:**
   - Does the objective align with project goals?
   - Is the approach consistent with architecture?
   - Are deliverables appropriate for the project?

   **Recent Changes Review:**

   ```bash
   # Review recent commits
   git log --oneline -20
   
   # Check recently modified files in task area
   git diff --name-only HEAD~10
   
   # Look for related completed tasks
   ls -t dev-taskflow/current/*/tasks/*.md | grep -E "(done|completed)" | head -10
   ```

   **Dependency Validation:**
   - Are listed dependencies actually complete?
   - Are there hidden dependencies not listed?
   - Will recent changes impact this task?

3. **Analyze Implementation Plan:**

   **Structure Assessment:**
   - Check for proper Planning Steps (`* [ ]`) and Execution Steps (`- [ ]`)
   - Verify embedded tests are included where needed
   - Ensure logical flow from research to implementation

   **Quality Criteria:**
   - [ ] Planning steps cover necessary research/design
   - [ ] Execution steps are concrete and actionable
   - [ ] Test blocks validate critical operations
   - [ ] Steps are properly sequenced
   - [ ] Effort estimates seem reasonable

   **Common Issues to Check:**
   - Missing directory audits for context
   - Vague or ambiguous action items
   - Lack of verification steps
   - Unrealistic scope or timeline
   - Missing error handling considerations

4. **Identify Improvement Areas:**

   **Task Definition Issues:**
   - Ambiguous requirements
   - Incomplete acceptance criteria
   - Missing technical details
   - Unclear scope boundaries

   **Implementation Plan Issues:**
   - Missing research/analysis steps
   - No test verification blocks
   - Skipping important validations
   - Ignoring edge cases

   **Context Issues:**
   - Outdated assumptions
   - Conflicts with recent changes
   - Missing architectural considerations
   - Ignoring coding standards

5. **Propose Refinements:**

   Use the enhanced implementation plan template: path (dev-handbook/templates/release-tasks/task.template.md)

6. **Formulate Feedback Points:**

   **Question Templates:**
   - "The objective mentions [X], but the scope includes [Y]. Should we...?"
   - "Recent changes to [component] may impact this. How should we adjust?"
   - "The acceptance criteria don't specify [important aspect]. What's expected?"
   - "Two approaches are viable: [A] vs [B]. Which aligns better with our goals?"

   **Decision Points:**
   - Technical approach confirmation
   - Scope clarification
   - Priority validation
   - Resource allocation
   - Risk assessment

7. **Present Review Summary:**
   
   Use the review report template: path (dev-handbook/templates/release-docs/documentation.template.md)

## Review Checklist

**Task Completeness:**

- [ ] Clear, measurable objective
- [ ] Well-defined scope and deliverables
- [ ] Comprehensive implementation plan
- [ ] Verifiable acceptance criteria
- [ ] Explicit out-of-scope items

**Technical Validity:**

- [ ] Aligns with architecture
- [ ] Follows coding standards
- [ ] Considers recent changes
- [ ] Addresses dependencies
- [ ] Includes error handling

**Process Compliance:**

- [ ] Uses correct task format
- [ ] Has proper metadata
- [ ] Includes embedded tests
- [ ] Follows naming conventions
- [ ] Documents decisions

## Output / Success Criteria

- Comprehensive review identifying all issues
- Clear improvement recommendations
- Specific questions for clarification
- Actionable next steps defined
- Risk areas highlighted
- Implementation approach validated

## Common Patterns

### High-Risk Task Pattern

Tasks touching core functionality need extra scrutiny:

- More thorough testing requirements
- Rollback plan considerations
- Performance impact analysis
- Security review requirements

### Refactoring Task Pattern

Refactoring tasks should include:

- Current state documentation
- Refactoring strategy
- Incremental milestones
- Regression test plans

### New Feature Pattern

New features require:

- User story validation
- API design review
- Integration considerations
- Documentation requirements

## Usage Example
>
> "Review task dev-taskflow/current/v.0.3.0/tasks/v.0.3.0+task.5-implement-oauth.md and identify any issues or improvements needed before implementation."

---

This workflow ensures tasks are thoroughly vetted before implementation, reducing rework and improving quality through systematic review.

## Embedded Templates

### Enhanced Implementation Plan Template: path (dev-handbook/templates/release-tasks/task.template.md)

````markdown
## Implementation Plan

### Planning Steps
* [ ] Research existing implementation patterns
  > TEST: Pattern Analysis
  > Type: Pre-condition Check
  > Assert: Similar patterns identified and documented
  > Command: grep -r "pattern" lib/

* [ ] Design solution approach
  - Consider alternatives
  - Document decision rationale
  - Create high-level design

* [ ] Identify impacted components
  > TEST: Impact Analysis
  > Type: Pre-condition Check
  > Assert: All dependencies mapped
  > Command: bin/deps --check component

### Execution Steps
- [ ] Implement core functionality
  > TEST: Core Implementation
  > Type: Action Validation
  > Assert: Basic functionality works
  > Command: bin/test spec/feature_spec.rb

- [ ] Add error handling
  - Handle edge cases
  - Add appropriate logging
  - Create helpful error messages

- [ ] Write comprehensive tests
  > TEST: Test Coverage
  > Type: Action Validation
  > Assert: Coverage > 90%
  > Command: bin/test --coverage

- [ ] Update documentation
  - API documentation
  - User guides
  - Code comments
````

### Review Report Template: path (dev-handbook/templates/release-docs/documentation.template.md)

````markdown
## Task Review Summary

### Task: [ID] - [Title]
**Status**: Ready for implementation | Needs clarification | Requires updates

### Key Findings
1. [Finding 1 - e.g., aligns with architecture]
2. [Finding 2 - e.g., missing test criteria]
3. [Finding 3 - e.g., conflicts with recent changes]

### Proposed Improvements
- [Specific improvement 1]
- [Specific improvement 2]

### Questions for Clarification
1. [Question requiring user input]
2. [Design decision needed]

### Recommended Next Steps
- [ ] Address clarification points
- [ ] Update task definition
- [ ] Proceed with implementation
````
