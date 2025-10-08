# Review Task Workflow Instruction

## Goal

Review and update task content without changing its status. This workflow enables incremental improvements to task specifications, implementation plans, or progress notes while maintaining the task's current state in the workflow. Most importantly, this workflow generates clarifying questions that need to be answered to make the task implementation-ready without further user feedback.

## Prerequisites

- Task file exists with any valid status (draft, pending, in_progress, completed)
- Understanding of task's current state and content structure
- Clear intent for what needs to be updated or refined
- Write access to task files in `.ace-taskflow/`
- Access to project documentation and codebase for research

## Project Context Loading

- Read and follow: `ace-nav wfi://load-project-context`

## Process Steps

1. **Load and Analyze Task:**
   - **Task Selection:**
     - If specific task provided: Use the provided task path
     - If no task specified: Run `ace-taskflow tasks` to view all tasks
     - Filter by status if needed: `ace-taskflow tasks --status draft`
   - **Load Task Content:**
     - Read the task file from the identified path
     - Note the current status (draft, pending, in_progress, completed)
     - Analyze existing content structure and sections
     - Identify gaps, ambiguities, or assumptions that need clarification

2. **Autonomous Research Phase:**
   - **Attempt Self-Resolution First:**
     - Search project documentation for answers
     - Analyze similar implementations in codebase
     - Review related tasks and their solutions
     - Check architectural decisions and patterns
     - Consult technical documentation and best practices
   - **Web Search When Appropriate:**
     - If WebSearch tool is available and needed:
       - Search for industry standards or best practices
       - Research security implications or vulnerabilities
       - Find performance benchmarks or comparisons
       - Look up API documentation or integration guides
     - Only search when internal resources insufficient
     - Focus searches on specific technical questions
   - **Document Research Findings:**
     - Note what was discovered through research
     - Record reasonable assumptions based on evidence
     - Include sources from web searches if used
     - Identify truly unresolvable questions

3. **Critical Question Generation:**
   - **Analyze for Completeness:**
     - Identify missing information that would block implementation
     - Find ambiguous requirements that could lead to wrong implementations
     - Spot assumptions that need validation
     - Detect edge cases not covered in current specification
     - Check for comprehensive renaming scope:
       - If task involves renaming, are all related files identified?
       - Are library directories, test files, and imports considered?
       - Have module/class names been addressed?
   - **Filter Questions by Resolution Status:**
     - Questions answered through research (document the answer)
     - Questions with reasonable defaults (document assumption)
     - Questions requiring human input (escalate only these)
   - **Generate Clarifying Questions:**
     - Only include questions that truly need human decision
     - Frame questions to be answerable asynchronously
     - Make questions specific and actionable
     - Include research context and suggested defaults

4. **Status-Specific Review Guidelines:**
   
   ### For `draft` Status Tasks:
   - **Focus Areas:**
     - Behavioral specifications refinement
     - Interface contract clarification
     - Success criteria enhancement
     - Validation questions addition
   - **Key Questions to Generate:**
     - What specific user interactions are expected in edge cases?
     - How should the system behave when errors occur?
     - What are the performance expectations from user perspective?
     - Are there unstated assumptions about user workflows?
   - **Appropriate Updates:**
     - Clarify user experience descriptions
     - Add missing edge cases to interface contracts
     - Refine success criteria for measurability
     - Add new validation questions discovered
     - Update scope boundaries if needed
   - **Avoid:**
     - Adding implementation details
     - Technical architecture decisions
     - Specific tool or library choices

   ### For `pending` Status Tasks:
   - **Focus Areas:**
     - Implementation plan refinement
     - Technical approach updates
     - Test scenario additions
     - Risk assessment improvements
   - **Key Questions to Generate:**
     - Are there hidden dependencies not considered in the plan?
     - What happens if external services are unavailable?
     - How will we validate each implementation step?
     - What are the rollback procedures if something fails?
     - Are performance requirements achievable with chosen approach?
   - **Appropriate Updates:**
     - Refine implementation steps based on new insights
     - Update tool selection based on research
     - Add newly discovered test scenarios
     - Enhance risk mitigation strategies
     - Clarify file modification plans:
       - Verify comprehensive renaming scope is captured
       - Check for missed library/test/doc renames
       - Ensure import/require updates are included
   - **Avoid:**
     - Changing behavioral specifications
     - Modifying core interface contracts

   ### For `in_progress` Status Tasks:
   - **Focus Areas:**
     - Progress documentation
     - Discovery notes
     - Blocker identification
     - Implementation adjustments
   - **Appropriate Updates:**
     - Add progress notes section if missing
     - Document unexpected findings
     - Update remaining steps based on progress
     - Note any blockers or dependencies
     - Adjust estimates if significantly off
   - **Avoid:**
     - Removing completed steps
     - Changing original specifications

   ### For `completed` Status Tasks:
   - **Focus Areas:**
     - Retrospective insights
     - Lessons learned
     - Follow-up identification
     - Documentation completeness
   - **Appropriate Updates:**
     - Add retrospective notes section
     - Document what went well/poorly
     - Identify follow-up tasks or improvements
     - Note any technical debt incurred
     - Update references with final artifacts
   - **Avoid:**
     - Changing implementation details
     - Modifying completion status

5. **Content Update Process:**
   - **Update Metadata for Tracking:**
     - Add `needs_review: true` to metadata if human input required
     - Remove `needs_review` flag when questions are resolved
     - Find tasks needing review: `ace-taskflow tasks needs-review` (preset)
   - **Preserve Structure:**
     - Maintain existing section organization
     - Keep all metadata fields intact (except needs_review)
     - Preserve status field unchanged
   - **Enhancement Approach:**
     - Add new content as subsections or bullets
     - Use comments for clarifications
     - Append rather than replace when possible
     - Mark updates with date/context if significant
   - **Validation During Updates:**
     - Ensure consistency with task purpose
     - Verify updates align with current status
     - Check that dependencies remain valid
     - Confirm estimate remains reasonable

6. **Question Documentation and Persistence:**
   - **Persist Questions in Task File:**
     - Add questions directly to the task file (not just review output)
     - Place in dedicated section for easy access and tracking
     - Questions remain until explicitly answered and removed
     - Enable independent review/answering sessions
   - **Question Section Placement:**
     - For draft/pending: After metadata, before main content
     - For in_progress: In progress notes section
     - For completed: In retrospective section
   - **Question Format with Research Context:**
     ```markdown
     ---
     id: task-001
     status: draft
     priority: high
     needs_review: true
     ---
     
     ## Review Questions (Pending Human Input)
     
     ### [HIGH] Critical Implementation Questions
     - [ ] How should we handle user sessions that exceed 24 hours?
       - **Research conducted**: Checked auth patterns in codebase
       - **Similar implementations**: Found session extension in API module
       - **Suggested default**: Auto-extend if active, expire if idle >2h
       - **Why needs human input**: Business policy decision required
     
     ### [MEDIUM] Enhancement Questions  
     - [ ] Should we log all session extensions for audit purposes?
       - **Research conducted**: Current logging practices reviewed
       - **Suggested default**: Log only anomalous extensions (>5 per day)
       - **Why needs human input**: Compliance requirements unclear
     ```

7. **Common Update Patterns:**

   ### Adding Discovered Requirements (draft/pending):
   ```markdown
   ### Validation Questions
   - [ ] Original question about X
   - [ ] **[Added on review]** New question about Y discovered during research
   ```

   ### Documenting Progress (in_progress):
   ```markdown
   ## Progress Notes
   
   ### 2025-01-30 Update
   - Completed steps 1-3 successfully
   - Discovered unexpected dependency on service X
   - Adjusted approach for step 4 based on findings
   - Remaining work: steps 4-6 (est. 2h)
   ```

   ### Adding Test Scenarios (pending):
   ```markdown
   ### Test Case Planning
   
   #### Original Scenarios
   - Happy path test
   - Basic error handling
   
   #### Additional Scenarios (discovered during review)
   - Edge case: concurrent access scenario
   - Performance: high-volume data processing
   ```

8. **Review Completion and Summary:**
   - **Generate Review Summary:**
     - List all questions generated with priorities
     - Highlight critical blockers that need answers
     - Suggest next steps based on question answers
     - Provide implementation readiness assessment
   - **Summary Format:**
     ```markdown
     ## Review Summary
     
     **Questions Generated:** X total (Y high, Z medium)
     **Critical Blockers:** [List HIGH priority questions]
     **Implementation Readiness:** Ready with assumptions / Blocked on answers
     **Recommended Next Steps:** Based on current state...
     ```

9. **Final Review Steps:**
   - **Final Validation:**
     - Confirm status field unchanged
     - Verify all updates are contextually appropriate
     - Check markdown formatting and structure
     - Ensure no broken references or links
   - **Documentation:**
     - Note what was updated in commit message
     - Reference any sources for new information
     - Link to related discussions or findings

## Decision Guidance

### When to Use This Workflow

**Use review-task when:**
- Refining specifications without changing task state
- Adding details discovered during research
- Documenting progress on active tasks
- Capturing lessons learned on completed tasks
- Updating estimates or dependencies
- Adding test scenarios or edge cases

**Don't use review-task when:**
- Changing task status (use work-on-task or complete-task)
- Creating new tasks (use draft-task)
- Converting ideas to tasks (use draft-task with idea input)
- Major scope changes requiring re-planning

### Review vs. Other Workflows

- **review-task vs. plan-task**: Review updates existing content; plan-task transforms draft to pending with implementation details
- **review-task vs. work-on-task**: Review updates documentation; work-on-task changes status and executes implementation
- **review-task vs. draft-task**: Review refines existing tasks; draft-task creates new behavioral specifications

## Success Criteria

- Task content enhanced with relevant updates
- Critical questions generated and documented
- Questions prioritized by implementation impact
- Default assumptions provided for all questions
- Status field remains unchanged
- Updates align with task's current state
- Structure and formatting preserved
- No loss of existing information
- Clear improvement in task clarity or completeness
- User receives actionable list of questions to answer

## Task Management Integration

### Finding Tasks Needing Review

```bash
# List all tasks requiring human input (using preset)
ace-taskflow tasks needs-review

# Or find by status, then check for needs_review flag manually
ace-taskflow tasks --status draft
ace-taskflow tasks --status pending

# Alternative: use ace-search to find tasks with needs_review flag
cd .ace-taskflow && ace-search "needs_review: true" --content
```

### Review Workflow Patterns

1. **Daily Review Session:**
   - Run filter to find tasks needing input
   - Review and answer questions in batch
   - Remove needs_review flag as questions are resolved

2. **Continuous Improvement:**
   - AI agents autonomously research first
   - Only escalate true blockers
   - Questions persist for asynchronous handling

3. **Pre-Implementation Check:**
   - Review pending tasks before work-on-task
   - Ensure all critical questions answered
   - Confirm implementation readiness

## Common Patterns

### Pattern 1: Behavioral Refinement (draft)
```bash
# Review draft task to clarify interface contracts
review-task .ace-taskflow/$(ace-taskflow release --path)/v.0.5.0/tasks/task.001.md
# Add missing error scenarios and edge cases to interface contract
# Clarify ambiguous success criteria
# Add validation questions discovered during review
```

### Pattern 2: Technical Enhancement (pending)
```bash
# Review pending task to update implementation approach
review-task .ace-taskflow/$(ace-taskflow release --path)/v.0.5.0/tasks/task.002.md
# Refine tool selection based on new research
# Add discovered test scenarios
# Update risk assessment with new considerations
```

### Pattern 3: Progress Documentation (in_progress)
```bash
# Review active task to document progress
review-task .ace-taskflow/$(ace-taskflow release --path)/v.0.5.0/tasks/task.003.md
# Add progress notes section
# Document blockers or discoveries
# Update remaining steps and estimates
```

### Pattern 4: Retrospective Addition (completed)
```bash
# Review completed task to add lessons learned
review-task .ace-taskflow/done/v.0.4.0/tasks/task.010.md
# Add retrospective notes
# Document what could be improved
# Identify follow-up tasks
```

### Pattern 5: Comprehensive Renaming Review (pending)
```bash
# Review task involving renaming to ensure comprehensive scope
review-task .ace-taskflow/$(ace-taskflow release --path)/v.0.5.0/tasks/rename-component.md

# Check for missing rename scope:
# 1. Find all directories with old name
ace-search "*old_name*" --file | grep -v ".git"

# 2. Find all files with old name
ace-search "*old_name*" --file | grep -v ".git"

# 3. Find all code references
ace-search "old_name" --content --glob "**/*.{rb,py,js,md}"

# Update task to include:
# - Library directory renames (lib/old_name/ → lib/new_name/)
# - Test file renames (*old_name_spec.rb → *new_name_spec.rb)
# - Test fixture/cassette renames
# - Module/class name changes
# - Import/require statement updates
# - Documentation reference updates
```

## Error Handling

### Common Issues and Solutions

**"Task not found" Error:**
- **Cause**: Invalid task path or ID
- **Solution**: Use `ace-taskflow tasks` to find correct path

**"Invalid status update attempt" Error:**
- **Cause**: Trying to change status field
- **Solution**: Keep status unchanged; use appropriate workflow for status changes

**"Structure validation failed" Error:**
- **Cause**: Breaking required task structure
- **Solution**: Preserve original section organization

**"Content conflict" Error:**
- **Cause**: Updates conflict with task state
- **Solution**: Ensure updates match status-specific guidelines

## Integration with Other Workflows

### Upstream Workflows
- **capture-idea**: Ideas that become tasks may need review for clarity
- **draft-task**: New drafts often benefit from immediate review
- **plan-task**: Pending tasks may need review after planning

### Downstream Workflows
- **work-on-task**: Reviewed tasks are clearer to implement
- **complete-task**: Final review ensures completeness
- **synthesize-reflection-notes**: Reviews provide input for retrospectives

### Parallel Workflows
- **create-test-cases**: Review may identify need for test cases
- **create-adr**: Significant changes may require decision documentation

## Usage Examples

### Example 1: Refining Draft Behavioral Specification
```
User: "Review the OAuth task draft to clarify the session timeout behavior"
Process:
1. Load task file (status: draft)
2. Research existing auth patterns:
   - Found: API uses 24h sessions with 2h idle timeout
   - Found: Mobile app uses refresh tokens (30 day expiry)
   - Missing: Web app session behavior not documented
   - Web search: "OAuth2 web application session timeout best practices 2025"
     - Found: OWASP recommends 2-12h for sensitive apps
     - Found: Industry standard is 8-24h with activity extension
3. Generate critical questions (only unresolved):
   - [HIGH] Should web app match mobile (30d refresh) or API (24h)?
     - Research: Security best practices suggest shorter for web
     - Web search findings: OWASP recommends max 12h
     - Default: 12h with activity extension (security-focused)
     - Needs input: Business requirement vs security trade-off
4. Update task file:
   - Add needs_review: true to metadata
   - Insert Review Questions section with research context
   - Include web search sources in research notes
5. Summary: 1 HIGH question needs business decision
```

### Example 2: Updating Pending Implementation Plan
```
User: "Review the database migration task - we discovered we need to handle legacy data"
Process:
1. Load task file (status: pending)
2. Analyze impact of legacy data on current plan
3. Generate implementation questions:
   - [HIGH] What's the volume and format of legacy data?
   - [HIGH] Should migration fail if legacy data is corrupted?
   - [MEDIUM] Do we need backward compatibility after migration?
4. Add legacy data handling steps with assumptions
5. Update test scenarios and risk assessment
6. Document questions in Review Questions section
7. Summary: 3 questions need answers before safe implementation
```

### Example 3: Documenting In-Progress Discoveries
```
User: "Review the API integration task - we found rate limiting issues"
Process:
1. Load task file (status: in_progress)
2. Add progress note about rate limiting discovery
3. Update remaining steps to include rate limit handling
4. Note potential estimate impact
```

## Key Value: Autonomous Clarification with Selective Escalation

The review-task workflow maximizes AI agent autonomy while ensuring critical decisions get human input:

1. **Research-First Approach**: AI agents attempt to find answers through documentation, codebase analysis, and pattern recognition before escalating
2. **Smart Question Filtering**: Only truly unresolvable questions requiring business/design decisions are escalated
3. **Persistent Question Tracking**: Questions are saved in task files with `needs_review: true` metadata for easy filtering
4. **Asynchronous Resolution**: Questions can be answered independently without blocking implementation
5. **Context-Rich Escalation**: Every question includes research findings, suggested defaults, and clear rationale for needing human input

This approach enables:
- **Continuous Progress**: AI can work autonomously on most tasks
- **Efficient Human Time**: Humans only address true decision points
- **Better Quality**: Research context leads to more informed decisions
- **Task Management Integration**: Easy tracking of tasks needing attention

---

This workflow ensures tasks remain accurate and comprehensive throughout their lifecycle while preserving the integrity of the task management system's status-based workflow. Most importantly, it transforms vague requirements into clear, actionable specifications through systematic question generation.