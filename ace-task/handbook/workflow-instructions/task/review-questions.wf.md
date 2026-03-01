---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2025-10-08'
---

# Review Questions Workflow Instruction

## Goal

Interactively review and resolve questions in tasks marked with `needs_review: true`, capturing answers and updating task definitions to make them implementation-ready without requiring further clarification.

## Prerequisites

- One or more tasks exist with `needs_review: true` flag
- Understanding of task review question format and structure
- Authority to make implementation decisions or access to stakeholders
- Write access to task files in `.ace-tasks/`
- Access to `ace-task list` tool for finding tasks

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`
- Load existing review workflow: `ace-bundle wfi://task/review`

## Process Steps

1. **Find Next Task Needing Review:**

   ```bash
   # List tasks by status (needs_review is a metadata field, not a filter)
   ace-task list --status draft
   ace-task list --status pending

   # You'll need to check task files manually for needs_review: true flag
   # Or use ace-search to find tasks with the flag:
   cd .ace-tasks && ace-search "needs_review: true" --content
   ```

   **Selection Strategy:**
   - Prioritize HIGH priority tasks first
   - Within same priority, select oldest tasks
   - Consider task dependencies (review prerequisites first)
   - Note the task path for loading
   - **Note**: `needs_review` is a task metadata field that must be checked by reading task files

2. **Load and Analyze Task Questions:**
   
   - **Read Task File:**
     ```bash
     # Read the selected task
     cat [task-path]
     ```
   
   - **Identify Question Structure:**
     - Locate `## Review Questions (Pending Human Input)` section
     - Note question priorities: [HIGH], [MEDIUM], [LOW]
     - Review research context for each question
     - Understand suggested defaults and rationale
   
   - **Prepare Question Presentation:**
     - Group questions by priority level
     - Order within groups by dependency/logic flow
     - Prepare to present context with each question

3. **Interactive Question Review Process:**
   
   ### For Each Question (Priority Order):
   
   **a. Present Question with Full Context:**
   ```markdown
   ========================================
   QUESTION [1/N] - [PRIORITY LEVEL]
   ========================================
   
   **Question**: [Question text]
   
   **Research Conducted**: 
   [Research findings from task]
   
   **Current Context**:
   [Relevant project/technical context]
   
   **Suggested Default**:
   [Default recommendation with rationale]
   
   **Why Human Input Needed**:
   [Business/design decision reasoning]
   
   **Potential Options**:
   1. [Option A with implications]
   2. [Option B with implications]
   3. [Option C with implications]
   4. [Custom answer]
   
   Please provide your decision:
   ```
   
   **b. Capture User Answer:**
   - Record the exact answer provided
   - Ask for optional rationale if not clear
   - Confirm understanding before proceeding
   - Note any follow-up implications
   
   **c. Document Answer Format:**
   ```markdown
   ### [RESOLVED] Original Question Title
   - **Decision**: [User's answer]
   - **Rationale**: [Why this choice was made]
   - **Implications**: [What this means for implementation]
   - **Resolved by**: [User/Role]
   - **Date**: [YYYY-MM-DD]
   ```

4. **Save Answers Progressively:**
   
   **After Each Answer:**
   - Update the task file immediately
   - Move question from pending to resolved section
   - Preserve original question for audit trail
   - Add resolution details
   
   **Answer Integration Pattern:**
   ```markdown
   ## Review Questions (Resolved)
   
   ### ✅ [RESOLVED] How should we handle session timeouts?
   - **Original Priority**: HIGH
   - **Decision**: Implement 12-hour sessions with 2-hour idle timeout
   - **Rationale**: Balances security with user convenience per OWASP
   - **Implementation Notes**: 
     - Use refresh tokens for extension
     - Log timeout events for monitoring
   - **Resolved by**: Product Owner
   - **Date**: 2025-01-30
   
   ## Review Questions (Pending Human Input)
   
   ### [MEDIUM] Remaining Question
   - [ ] [Question still needing answer...]
   ```

5. **Update Task Definition with Answers:**
   
   **Integration Points by Task Section:**
   
   ### Technical Specifications:
   - Add concrete configuration values from answers
   - Update implementation approach based on decisions
   - Specify exact thresholds, limits, quotas
   
   ### Implementation Notes:
   - Document specific technical choices made
   - Add configuration examples with resolved values
   - Include edge case handling per decisions
   
   ### Success Criteria:
   - Update measurable targets with specific values
   - Add validation criteria from answers
   - Include performance thresholds decided
   
   ### Configuration Files:
   - Update code examples with actual values
   - Replace placeholders with decisions
   - Add comments explaining choices
   
   **Example Integration:**
   ```javascript
   // Before (with question)
   numberOfRuns: 3, // TODO: How many runs for reliability?
   
   // After (with answer integrated)
   numberOfRuns: 3, // Confirmed: 3 runs for median reliability (decided 2025-01-30)
   ```

6. **Complete Review Session:**
   
   **When All Questions Answered:**
   - Remove `needs_review: true` flag from metadata
   - Move all questions to Resolved section
   - Add review completion note
   
   **Completion Metadata Update:**
   ```yaml
   ---
   id: v.0.2.0+task.123
   status: draft  # Or current status
   priority: high
   estimate: 4-6h  # Update if needed based on decisions
   dependencies: none
   # needs_review: true  # REMOVED
   review_completed: 2025-01-30
   reviewed_by: [User/Role]
   ---
   ```
   
   **Add Implementation Readiness Note:**
   ```markdown
   ## Review Completion Summary
   
   **Date**: 2025-01-30
   **Reviewed by**: [User/Role]
   **Questions Resolved**: 5 (3 HIGH, 2 MEDIUM)
   **Implementation Readiness**: ✅ Ready for implementation
   
   **Key Decisions Made**:
   - Lighthouse CI will run on all builds with sampling
   - Performance thresholds: 5-point warning, 10-point failure
   - Mobile-first testing with 3 runs for reliability
   - 50ms monitoring overhead budget approved
   - BigQuery integration deferred to Phase 2
   ```

7. **Handle Partial Reviews:**
   
   **If Review Must Be Interrupted:**
   - Save all answered questions immediately
   - Keep `needs_review: true` flag
   - Add progress note with timestamp
   - Document which questions remain
   
   **Progress Note Format:**
   ```markdown
   ## Review Progress Notes
   
   ### Session: 2025-01-30 14:30
   - Resolved: 3 of 5 questions
   - Remaining: 2 MEDIUM priority questions
   - Blocked on: Need input from DevOps team
   - Next steps: Schedule follow-up for remaining items
   ```

8. **Batch Review Mode (Optional):**
   
   **For Multiple Tasks:**
   ```bash
   # Generate review queue (find tasks with needs_review flag)
   cd .ace-tasks && ace-search "needs_review: true" --content --files-with-matches > ../review-queue.txt

   # Process each task systematically
   for task in $(cat review-queue.txt); do
     echo "Reviewing: $task"
     # Follow steps 2-6 for each task
   done
   ```
   
   **Batch Summary Report:**
   ```markdown
   ## Batch Review Summary - 2025-01-30
   
   **Tasks Reviewed**: 3
   **Questions Resolved**: 12 total
   - Task.123: 5 questions ✅
   - Task.124: 4 questions ✅  
   - Task.125: 3 questions (2 resolved, 1 pending)
   
   **Common Decisions**:
   - All performance monitoring at 25% sampling
   - Consistent 5/10 point threshold strategy
   - Mobile-first testing approach approved
   ```

## Success Criteria

- All HIGH priority questions answered with clear decisions
- Answers documented with rationale and implications
- Task definition updated with concrete implementation details
- Configuration examples include actual decided values
- `needs_review` flag removed when fully resolved
- Task achieves "implementation-ready" state
- No ambiguity remains that would block implementation
- Review completion summary added to task

## Common Question Types and Answer Templates

### Performance/Threshold Questions
```markdown
**Question**: What performance degradation threshold should trigger build failure?
**Answer Template**:
- Warning threshold: [X points/percent]
- Failure threshold: [Y points/percent]
- Applies to: [specific metrics]
- Exception handling: [if any]
```

### Configuration/Setup Questions
```markdown
**Question**: Should this run in CI/CD or local only?
**Answer Template**:
- Environments: [local, CI, production]
- Trigger conditions: [PR, merge, manual]
- Resource limits: [if applicable]
- Cost considerations: [if applicable]
```

### Feature Scope Questions
```markdown
**Question**: Should we include [feature X] in this implementation?
**Answer Template**:
- Include in current scope: [Yes/No]
- If deferred, target phase: [Phase N]
- Dependencies affected: [list]
- Alternative approach: [if not included]
```

### Technical Approach Questions
```markdown
**Question**: Which library/tool should we use for [purpose]?
**Answer Template**:
- Selected option: [Library/Tool name]
- Version constraint: [if specific]
- Rationale: [why chosen]
- Fallback option: [if first choice fails]
```

## Integration with Task Workflows

### Before review-questions:
- `review-task`: Generates questions needing answers
- `draft-task`: Creates tasks that may need clarification

### After review-questions:
- `plan-task`: Can proceed with clear requirements
- `work-on-task`: Implementation without ambiguity
- Task is ready for execution without blockers

### Parallel workflows:
- `create-adr`: Document significant technical decisions
- `create-test-cases`: Define tests based on decisions

## Error Handling

### Common Issues:

**"No tasks need review"**
- Run `ace-task list needs-review` (preset) or `cd .ace-tasks && ace-search "needs_review: true" --content`
- Check if reviews were already completed
- Look for tasks with questions but missing flag

**"Cannot parse question format"**
- Ensure questions follow standard format
- Check for `## Review Questions` section
- Verify markdown structure is valid

**"Conflicting answers"**
- Review previous decisions for consistency
- Document why this case differs
- Consider creating ADR for significant changes

## Usage Examples

### Example 1: Single Task Review
```
User: "Review questions for the Lighthouse CI task"

Process:
1. Load task.123 with 5 pending questions
2. Present each question with context:
   Q1 [HIGH]: "Should Lighthouse CI run on all builds?"
   - Show research about build times
   - Present cost implications
   - Suggest: "PR checks + production"
3. Capture answer: "Yes, but with different configs"
4. Document decision with rationale
5. Update task config examples with decision
6. Continue through all 5 questions
7. Remove needs_review flag
8. Add completion summary
Result: Task ready for implementation
```

### Example 2: Batch Review Session
```
User: "Review all pending task questions"

Process:
1. Find 3 tasks needing review (123, 124, 125)
2. Start with highest priority (task.123)
3. Work through all questions systematically
4. Save progress after each task
5. Generate batch summary report
6. Flag any that need follow-up
Result: 2 tasks ready, 1 needs additional input
```

### Example 3: Partial Review with Handoff
```
User: "Review what I can answer for task.124"

Process:
1. Load 4 questions from task.124
2. Answer technical questions (2 resolved)
3. Flag business questions for Product Owner
4. Save partial progress with notes
5. Keep needs_review flag active
6. Document what remains and who should answer
Result: Partial resolution with clear next steps
```

## Key Value: Structured Decision Capture

This workflow ensures:
1. **No Lost Context**: All research and reasoning preserved
2. **Audit Trail**: Clear record of who decided what and why
3. **Implementation Clarity**: Developers have exact values and approaches
4. **Efficient Reviews**: Questions presented with full context for quick decisions
5. **Progressive Resolution**: Can handle partial reviews and handoffs
6. **Batch Processing**: Efficiently review multiple tasks in one session

The workflow transforms tasks from "blocked on questions" to "ready to build" through systematic, documented decision-making.
