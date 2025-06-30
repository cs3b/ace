# Create Reflection Note Workflow Instruction

## Goal

Capture individual or team observations, learnings, and ideas for improvement during development work. These notes document insights that can help improve future work processes and outcomes.

## Prerequisites

- Understanding of what reflections to capture (learnings, challenges, improvements)
- Access to create files in the project structure
- Current working session or specific context to reflect upon

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

## High-Level Execution Plan

### Planning Steps

- [ ] Determine the scope and context of the reflection (current session, specific task, or provided topic)
- [ ] Identify the appropriate location for saving the reflection note
- [ ] Analyze recent work patterns and extract key insights

### Execution Steps

- [ ] Create reflection structure using the embedded template
- [ ] Gather and analyze reflection content from recent work or provided context
- [ ] Populate reflection sections with meaningful insights and learnings
- [ ] Save reflection note with appropriate filename and location
- [ ] Commit reflection note to version control

## Process Steps

1. **Determine Reflection Context:**
   - If user provides specific context:
     - Use the provided topic, task, or time period
     - Focus reflection on that specific area
   - If no context provided:
     - Self-review the current working session
     - Analyze recent changes and activities
     - Extract learnings from current work

2. **Identify Target Location:**
   - Determine where to save the reflection:

     ```bash
     # Check for current release
     ls -d dev-taskflow/current/*/
     
     # If current release exists
     dev-taskflow/current/{release}/reflections/
     
     # If no current release
     dev-taskflow/reflections/
     ```

   - Create reflections directory if needed
   - Generate filename: `YYYYMMDD-brief-description.md`
     - Example: `20240126-authentication-refactor-learnings.md`
     - Example: `20240126-session-review.md`

3. **Create Reflection Structure:**

   Use the reflection template: path (dev-handbook/templates/release-reflections/retrospective.template.md)

4. **Gather Reflection Content:**

   **For Self-Review Session:**
   - Review recent git commits
   - Analyze completed tasks
   - Identify challenges faced
   - Note successful solutions
   - Extract patterns and learnings

   **Reflection Prompts:**
   - What was the main goal of this work?
   - What obstacles were encountered?
   - How were problems solved?
   - What would you do differently?
   - What patterns emerged?
   - What knowledge was gained?

5. **Populate Reflection:**

   **Example Content Generation:**

   ```markdown
   # Reflection: Authentication System Refactor
   
   **Date**: 2024-01-26
   **Context**: Refactoring the authentication system to support OAuth
   **Author**: Development Team
   
   ## What Went Well
   
   - Clear separation of authentication strategies made the code more maintainable
   - Test-driven approach caught several edge cases early
   - Pair programming sessions improved code quality
   
   ## What Could Be Improved
   
   - Initial time estimates were too optimistic
   - Documentation was updated after implementation rather than alongside
   - Integration tests took longer than expected to stabilize
   
   ## Key Learnings
   
   - OAuth implementation complexity varies significantly between providers
   - Mocking external authentication services requires careful consideration
   - Early spike solutions save time in the long run
   
   ## Action Items
   
   ### Stop Doing
   - Estimating OAuth integration as "simple"
   - Leaving documentation until the end
   
   ### Continue Doing
   - TDD approach for security-critical features
   - Regular pair programming sessions
   - Creating spike solutions for unknowns
   
   ### Start Doing
   - Document authentication flows before implementation
   - Create integration test fixtures early
   - Schedule regular security reviews
   ```

6. **Review and Save:**
   - Ensure all sections have meaningful content
   - Remove empty sections if not applicable
   - Save file with descriptive filename
   - Commit with appropriate message:

     ```bash
     git add dev-taskflow/current/*/reflections/*.md
     git commit -m "docs(reflection): add learnings from [topic]"
     ```

## Self-Review Process

When no specific context is provided, follow this process:

1. **Analyze Recent Work:**

   ```bash
   # Review recent commits
   git log --oneline -10
   
   # Check modified files
   git diff --name-only HEAD~5
   
   # Review completed tasks
   ls -t dev-taskflow/current/*/tasks/*.md | head -5
   ```

2. **Extract Insights:**
   - Identify patterns in the work
   - Note any repeated challenges
   - Recognize successful approaches
   - Consider process improvements

3. **Generate Reflection:**
   - Summarize the session's accomplishments
   - Document any blockers encountered
   - Capture new learnings
   - Propose process improvements

## Common Reflection Patterns

### Technical Reflection

Focus on code quality, architecture decisions, and technical learnings.

### Process Reflection

Focus on workflow efficiency, team collaboration, and methodology.

### Problem-Solving Reflection

Focus on how specific challenges were overcome and lessons learned.

### Learning Reflection

Focus on new skills, tools, or concepts mastered during the work.

## Success Criteria

- Reflection note created with meaningful content
- Insights captured for future reference
- Action items clearly defined
- File saved in appropriate location
- Learning documented for team benefit

## Best Practices

**DO:**

- Be honest about challenges and failures
- Focus on actionable improvements
- Include specific examples
- Keep entries concise but complete
- Date and contextualize reflections

**DON'T:**

- Make it a blame session
- Be vague or generic
- Skip the action items
- Forget to save/commit
- Write novels - keep it focused

## Common Patterns

### Session-End Reflection

Capture insights at the end of a development session to preserve context and learnings for future work.

### Feature Completion Reflection

Document lessons learned after completing a significant feature or refactoring effort.

### Problem-Solving Reflection

Record insights gained while solving complex technical challenges or debugging issues.

### Process Improvement Reflection

Capture observations about development workflow effectiveness and areas for optimization.

## Usage Examples

**With context:**
> "Create a reflection note about the authentication system refactor we just completed"

**Without context:**
> "Create a reflection note" (triggers self-review of current session)

**Specific learning:**
> "Create a reflection note about the OAuth integration challenges we faced"

---

This workflow helps capture valuable insights and learnings, creating a knowledge base that improves future development work.

<templates>
    <template path="{current-release-path}/reflections/YYYYMMDD-HHMMSS-reflection-topic.md" template-path="dev-handbook/templates/release-reflections/retrospective.template.md">
# Reflection: [Topic/Date]

**Date**: YYYY-MM-DD
**Context**: [Brief description of what this reflection covers]
**Author**: [Name or identifier]

## What Went Well

- [Positive outcome or successful approach]
- [Effective pattern discovered]
- [Good decision that paid off]

## What Could Be Improved

- [Challenge encountered]
- [Inefficiency identified]
- [Area needing attention]

## Key Learnings

- [Important insight gained]
- [New understanding developed]
- [Valuable lesson learned]

## Action Items

### Stop Doing

- [Practice or approach to discontinue]
- [Ineffective pattern to avoid]

### Continue Doing

- [Successful practice to maintain]
- [Effective approach to keep using]

### Start Doing

- [New practice to adopt]
- [Improvement to implement]

## Technical Details

(Optional: Specific technical insights, code patterns, or implementation notes)

## Additional Context

(Optional: Links to relevant PRs, tasks, or documentation)
    </template>
</templates>
