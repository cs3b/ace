# Create Reflection Note Workflow Instruction

## Goal

Capture individual or team observations, learnings, and ideas for improvement during development work. These notes document insights that can help improve future work processes and outcomes.

**Enhanced Capabilities:**

- **Conversation Analysis**: Analyze current conversation context to identify challenges, user input requirements, tool limitations, and improvement opportunities
- **Self-Reflection**: Review development sessions to extract learnings from work patterns, blockers, and successful approaches
- **Pattern Recognition**: Group challenges by type and prioritize by impact to focus on high-value improvements

## Prerequisites

- Understanding of what reflections to capture (learnings, challenges, improvements)
- Access to create files in the project structure
- Current working session or specific context to reflect upon

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`
- Load tools documentation: `docs/tools.md`

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

## Process Steps

1. **Determine Reflection Context:**
   - If user provides specific context:
     - Use the provided topic, task, or time period
     - Focus reflection on that specific area
   - If no context provided:
     - Self-review the current working session
     - Analyze recent changes and activities
     - Extract learnings from current work
   - **For Conversation Analysis:**
     - Analyze current conversation thread
     - Identify challenges and repeated attempts
     - Review user input requirements and corrections
     - Note tool result issues (large output, truncation, token limits)

2. **Identify Target Location:**
   - Determine where to save the reflection using current release context:

     ```bash
     # Get current release information and path automatically
     create-path file:reflection-new --title '<reflection-title>'

     # This tool will:
     # 1. Determine current release context automatically
     # 2. Create target directory if needed
     # 3. Generate appropriate filename with timestamp
     # 4. Create the reflection file and return full path
     ```


3. **Create Reflection Structure:**

   Use the reflection template:

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

## Conversation Analysis Process

For conversation-based self-reflection, follow these specialized steps:

1. **Analyze Conversation Thread:**
   - Review the entire conversation from start to current point
   - Identify patterns of interaction and workflow execution
   - Note decision points and direction changes

2. **Identify Challenge Patterns:**
   - **Multiple Attempts**: Tasks requiring several tries to achieve desired outcome
   - **User Input Required**: Points where user clarification or correction was needed
   - **User Corrections**: Instances where user input corrected or redirected the work
   - **Tool Limitations**: Large outputs, truncated results, or token limit issues
   - **Context Switching**: Tasks requiring multiple context loads or searches
   - **Workflow Deviations**: Points where standard processes were modified

3. **Pattern Grouping and Impact Analysis:**
   - Group identified challenges by common causes or types:
     - **Communication Issues**: Unclear requirements, missing context
     - **Technical Constraints**: Tool limitations, environment issues
     - **Process Gaps**: Missing workflow steps, inadequate guidance
     - **Knowledge Gaps**: Unfamiliar tools, incomplete understanding
   - Sort groups by impact level:
     - **High Impact**: Issues causing significant delays or rework
     - **Medium Impact**: Issues causing minor inefficiencies
     - **Low Impact**: Minor inconveniences or edge cases

4. **Generate Improvement Proposals:**
   For each challenge group, propose specific solutions:
   - **Process Improvements**: New workflow steps, better documentation
   - **Tool Enhancements**: Better commands, additional capabilities
   - **Communication Protocols**: Clearer requirement gathering, confirmation steps
   - **Preventive Measures**: Early validation, assumption checking

5. **Handle Token Limits and Truncation Issues:**
   - **Identify Token Limit Problems:**
     - Large tool outputs that exceed display limits
     - Truncated responses affecting context understanding
     - Conversation length causing memory constraints
   - **Document Impact:**
     - Lost information from truncated outputs
     - Incomplete context affecting decision making
     - Workflow interruptions requiring context rebuilding
   - **Mitigation Strategies:**
     - Break large operations into smaller chunks
     - Use targeted queries instead of broad searches
     - Implement progressive disclosure techniques
     - Save intermediate results to files

6. **Create Conversation Analysis Report:**
   Use the enhanced template to document findings and recommendations

## Self-Review Process

When no specific context is provided, follow this process:

1. **Analyze Recent Work:**

   ```bash
   # Review recent commits with enhanced context
   git-log --oneline -10

   # Check modified files with intelligent diff
   git-diff --name-only HEAD~5

   # Review completed tasks using task manager
   task-manager recent --limit 5 --filter status:done
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
- Forget to save file
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

<documents>
    <template path="dev-handbook/templates/release-reflections/retrospective.template.md">
# Reflection: [Topic/Date]

**Date**: YYYY-MM-DD
**Context**: [Brief description of what this reflection covers]
**Author**: [Name or identifier]
**Type**: [Standard | Conversation Analysis | Self-Review]

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

## Conversation Analysis (For conversation-based reflections)

### Challenge Patterns Identified

#### High Impact Issues

- **[Challenge Type]**: [Description]
  - Occurrences: [Number of times this pattern appeared]
  - Impact: [Description of delays/rework caused]
  - Root Cause: [Analysis of underlying issue]

#### Medium Impact Issues

- **[Challenge Type]**: [Description]
  - Occurrences: [Number of times this pattern appeared]
  - Impact: [Description of inefficiencies caused]

#### Low Impact Issues

- **[Challenge Type]**: [Description]
  - Occurrences: [Number of times this pattern appeared]
  - Impact: [Minor inconveniences]

### Improvement Proposals

#### Process Improvements

- [Specific workflow enhancement]
- [Documentation improvement]
- [Better validation step]

#### Tool Enhancements

- [Command improvement suggestion]
- [Tool capability request]
- [Automation opportunity]

#### Communication Protocols

- [Clearer requirement gathering]
- [Better confirmation process]
- [Enhanced feedback loop]

### Token Limit & Truncation Issues

- **Large Output Instances**: [Count and description]
- **Truncation Impact**: [Information lost, workflow disruption]
- **Mitigation Applied**: [How issues were resolved]
- **Prevention Strategy**: [Future avoidance approach]

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
</documents>
