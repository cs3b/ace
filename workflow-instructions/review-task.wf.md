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

1. **Identify and Load Task:**
   - **Task Selection:**
     - If specific task provided: Use the provided task path
     - If no task specified: Run `bin/tn` to get the next task to review
     - Document the selected task path for reference
   - **Load Task Content:**
     - Read the task file from the identified path
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

3. **Conduct Task-Specific Research:**
   - **Identify Research Topics:**
     - What domain knowledge is required for this task?
     - Which technologies or patterns are involved?
     - What are the key decision points in the implementation?
   - **Research Current Best Practices:**
     - Industry standards for the task's domain
     - Recent developments in relevant technologies
     - Proven patterns and approaches
   - **Identify Potential Gotchas:**
     - Common pitfalls in similar implementations
     - Integration challenges with existing systems
     - Performance or security considerations
   - **Project-Specific Considerations:**
     - How does this task fit within our architecture?
     - Are there project-specific constraints or requirements?
     - What should we be especially careful about given our context?
   - **Document Research Findings:**
     - Summarize key insights
     - Note any recommendations or concerns
     - Identify areas requiring further investigation

4. **Analyze Implementation Plan:**

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

5. **Identify Improvement Areas:**

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

6. **Validate Task Currency and Update:**
   - **Project Status Validation:**
     - Is the task still relevant to current project goals?
     - Are the assumptions still valid given recent changes?
     - Do the deliverables align with current architecture?
   - **Task Update Process:**
     - Identify specific content that needs updating
     - Propose necessary changes to task definition
     - Update implementation plan based on research findings
     - Revise acceptance criteria if needed
   - **User Confirmation:**
     - Present proposed changes to user
     - Explain rationale for each modification
     - Request approval before applying changes
     - Document any user feedback or decisions

7. **Propose Refinements:**

   Use the enhanced implementation plan template:

8. **Formulate Feedback Points:**

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

9. **Implementation Readiness Assessment:**
   - **Readiness Checklist:**
     - [ ] All research findings incorporated
     - [ ] Task definition is current and accurate
     - [ ] Implementation plan is detailed and actionable
     - [ ] Dependencies are resolved or clearly tracked
     - [ ] User feedback has been addressed
     - [ ] Acceptance criteria are complete and testable
   - **Final Validation:**
     - Confirm task aligns with current project state
     - Verify all improvement areas have been addressed
     - Ensure implementation approach is sound
   - **Go/No-Go Decision:**
     - **✅ Ready for Implementation**: All criteria met, proceed with confidence
     - **⚠️ Ready with Conditions**: Minor issues noted, proceed with caution
     - **❌ Not Ready**: Critical issues must be resolved before implementation

10. **Present Review Summary:**
   Use the task review summary template:

11. **Update the task:**
   Use all the gatherd information

12. **Present questions to user again, so they will not be missed**
   Repeat what do you have in point 8.

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

<documents>
    <template path="dev-handbook/templates/release-tasks/task.template.md">---
id: <run bin/tnid to generate ID>
status: pending
priority: <high/medium/low>
estimate: <n>h
dependencies: [<ticket-ids>]
---

# <Verb + Object>

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

Why are we doing this?

## Scope of Work

- Bullet 1 …
- Bullet 2 …

### Deliverables

#### Create

- path/to/file.ext

#### Modify

- path/to/other.ext

#### Delete

- path/to/obsolete.ext

## Phases

1. Audit
2. Extract …
3. Refactor …

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: bin/test --check-analysis-complete
- [ ] Research best practices and design approach
- [ ] Plan detailed implementation strategy

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Step 1: Describe the first implementation action.
- [ ] Step 2: Describe the second action, which produces a verifiable outcome.
  > TEST: Verify Action 2 Outcome
  > Type: Action Validation
  > Assert: The outcome of Step 2 (e.g., file created, content updated) is as expected.
  > Command: bin/test --check-something path/to/relevant_artifact_from_step_2
- [ ] ... Add more implementation steps as needed.

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: All specified deliverables created/modified.
- [ ] AC 2: Key functionalities (if applicable) are working as described.
- [ ] AC 3: All automated checks in the Implementation Plan pass.

## Out of Scope

- ❌ …

## References

```
</template>

    <template path="dev-handbook/templates/review-tasks/task-review-summary.template.md"># Task Review Summary

## 1. Executive Summary

✅/⚠️/❌ Overall task assessment and key findings

## 2. Project Alignment Review

### Goal Alignment

- [ ] ✅ Objective aligns with project goals
- [ ] ✅ Approach consistent with architecture
- [ ] ✅ Deliverables appropriate for project

### Recent Changes Impact

- [ ] ✅ Compatible with recent commits
- [ ] ✅ No conflicts with ongoing work
- [ ] ✅ Considers architectural updates

## 3. Task Structure Assessment

### Metadata Quality

- [ ] ✅ Proper task format and structure
- [ ] ✅ Accurate priority and estimate
- [ ] ✅ Dependencies correctly identified
- [ ] ✅ Status appropriately set

### Implementation Plan Quality

- [ ] ✅ Planning steps cover necessary research
- [ ] ✅ Execution steps are concrete and actionable
- [ ] ✅ Test blocks validate critical operations
- [ ] ✅ Steps are properly sequenced
- [ ] ✅ Effort estimates seem reasonable

## 4. Dependency Analysis

### Stated Dependencies

- Dependency 1: Status and impact
- Dependency 2: Status and impact

### Hidden Dependencies

- Identified unstated dependencies
- Potential blockers

## 5. Implementation Approach Review

### Technical Approach

✅/⚠️/❌ Assessment of proposed solution

### Quality Considerations

- [ ] ✅ Follows coding standards
- [ ] ✅ Includes error handling
- [ ] ✅ Addresses security concerns
- [ ] ✅ Considers performance impact

## 6. Identified Issues

### 🔴 Critical Issues (Blocking)

- Issue 1: Description and recommendation
- Issue 2: Description and recommendation

### 🟡 High Priority Issues

- Issue 1: Description and recommendation
- Issue 2: Description and recommendation

### 🟢 Medium Priority Issues  

- Issue 1: Description and recommendation
- Issue 2: Description and recommendation

### 🔵 Nice-to-Have Improvements

- Improvement 1: Description
- Improvement 2: Description

## 7. Scope and Boundary Review

### Scope Clarity

✅/⚠️/❌ Assessment of scope definition

### Boundary Issues

- Missing items that should be in scope
- Items that should be out of scope
- Unclear boundaries

## 8. Risk Assessment

### Technical Risks

- Risk 1: Description and mitigation
- Risk 2: Description and mitigation

### Project Risks

- Risk 1: Description and mitigation
- Risk 2: Description and mitigation

## 9. Recommendations

### Immediate Actions Required

1. Action 1: Description and rationale
2. Action 2: Description and rationale

### Suggested Improvements

1. Improvement 1: Description and benefit
2. Improvement 2: Description and benefit

## 10. Questions for Clarification

1. Question 1: Context and options
2. Question 2: Context and options

## 11. Approval Status

    [ ] ✅ Approve as-is - ready for implementation
    [ ] ✅ Approve with minor changes - proceed with noted adjustments
    [ ] ⚠️ Request changes (non-blocking) - improvements recommended
    [ ] ❌ Request changes (blocking) - critical issues must be resolved

**Justification:** Brief explanation of approval decision

## 12. Next Steps

- [ ] Step 1: Who and when
- [ ] Step 2: Who and when
- [ ] Step 3: Who and when
</template>

</documents>
