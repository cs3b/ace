# Log Compact Session Workflow Instruction

## Goal

Capture a compact summary of the current session (what was done, next steps, key file links) primarily for context saving/reloading, especially when dealing with token limits or needing to transfer session state.

## Prerequisites

- Active development session with recent work
- Clear understanding of what was accomplished
- Knowledge of next steps or current blockers

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

## High-Level Execution Plan

### Planning Steps

- [ ] Analyze current session work and recent changes
- [ ] Identify critical context and files for session restoration
- [ ] Determine appropriate save location for session log

### Execution Steps

- [ ] Generate comprehensive session summary using embedded template
- [ ] Create detailed context loading instructions
- [ ] Include restoration commands and file paths
- [ ] Save compact session log with timestamp
- [ ] Provide confirmation and usage instructions

## Process Steps

1. **Analyze Current Session:**
   - Review recent work in the session:
     - Main objectives addressed
     - Key files modified or created
     - Decisions made
     - Problems encountered
     - Current state of work

   - Identify critical context:
     - Active task or feature
     - Important file paths
     - Unfinished work
     - Next immediate steps

2. **Generate Session Summary:**

   Use the session log template:

3. **Determine Save Location:**

   ```bash
   # Check for current release
   RELEASE_DIR=$(ls -d dev-taskflow/current/*/ 2>/dev/null | head -1)
   
   if [ -n "$RELEASE_DIR" ]; then
     SESSION_DIR="${RELEASE_DIR}sessions/"
   else
     SESSION_DIR="dev-taskflow/sessions/"
   fi
   
   # Create directory if needed
   mkdir -p "$SESSION_DIR"
   
   # Generate filename with timestamp
   FILENAME="$(date +%Y%m%d-%H%M%S)-compact-log.md"
   FILEPATH="${SESSION_DIR}${FILENAME}"
   ```

4. **Include Restoration Instructions:**

   **Essential Elements:**
   - Exact file paths to reopen
   - Current git branch/status
   - Environment state if relevant
   - Test commands to verify state
   - Clear next action

   **Example Context Loading:**

   ```markdown
   ### Quick Restore Commands
   ```bash
   # 1. Load the task
   cat dev-taskflow/current/v.0.3.0/tasks/v.0.3.0+task.5.md
   
   # 2. Open key files
   $EDITOR src/auth/oauth_handler.rb spec/auth/oauth_handler_spec.rb
   
   # 3. Check current state
   git status
   bin/test --only-failures
   
   # 4. Resume where left off
   # - Complete the error handling in oauth_handler.rb:45
   # - Add remaining test cases for error scenarios
   # - Update API documentation
   ```

   ```

5. **Save and Confirm:**
   - Save the log to determined location
   - Provide confirmation with path:

     ```
     Session log saved to: dev-taskflow/current/v.0.3.0/sessions/20240126-143022-compact-log.md
     
     To resume this session later, load the context prompt from the saved file.
     ```

## Usage Patterns

### End of Work Session

```markdown
## Request Summary
Implemented user authentication feature with JWT tokens

## Work Completed
- Created AuthenticationController with login/logout endpoints
- Added JWT token generation and validation
- Wrote comprehensive test suite (15 tests, all passing)
- Updated API documentation

## Current State
- Active task: v.0.3.0+task.12 (90% complete)
- Work status: Ready for code review
- Key files in focus:
  - `app/controllers/authentication_controller.rb` - Complete
  - `spec/controllers/authentication_controller_spec.rb` - Complete
  - `docs/api/authentication.md` - Needs final review
```

### Context Switch

```markdown
## Request Summary
Debugging production issue with payment processing

## Work Completed
- Identified race condition in payment state machine
- Added logging to trace issue
- Created failing test case

## Current State
- Active task: HOTFIX-payment-race-condition
- Work status: In-progress (root cause identified)
- Key files in focus:
  - `app/services/payment_processor.rb:145` - Race condition here
  - `spec/services/payment_processor_spec.rb:298` - Failing test
```

### Token Limit Reached

```markdown
## Request Summary
Refactoring legacy notification system (session truncated due to token limit)

## Work Completed
- Analyzed 15 files in legacy notification system
- Created refactoring plan with 8 phases
- Completed Phase 1: Extract notification types
- Started Phase 2: Create adapter interfaces

## Context Loading Prompt
[Detailed state for resuming exactly where left off]
```

## Best Practices

**DO:**

- Keep summaries concise but complete
- Include exact file paths and line numbers
- Note any uncommitted changes
- Specify exact commands to resume
- Mention critical decisions or blockers

**DON'T:**

- Include lengthy code snippets
- Duplicate information available in files
- Forget to mention the current git state
- Omit important context or decisions
- Make summaries too verbose

## Success Criteria

- Compact session log created with all essential information
- Clear instructions for resuming work
- File saved in appropriate location
- Context sufficient to continue without confusion
- Next steps explicitly defined

## Common Patterns

### Context Switch Logging

Capture session state when switching between different features or bug fixes within the same project.

### Token Limit Recovery

Preserve detailed context when approaching conversation token limits to enable seamless continuation.

### Work Session Boundaries

Log session state at natural stopping points to enable clean resumption later.

### Multi-Session Feature Development

Maintain context across multiple development sessions for complex features requiring extended work.

## Usage Example
>
> "Create a session log - we've been working on the OAuth implementation and I need to switch contexts"

---

This workflow enables efficient context preservation and restoration, critical for managing complex development work across sessions or token limits.

## Embedded Templates

### Session Log Template

Reference the session context template for creating compact session logs.

<documents>
    <template path="dev-handbook/templates/session-management/session-context.template.md">
# Compact Session Log: YYYY-MM-DD HH:MM:SS

## Request Summary

[Concise summary of the user's main goal during this session]
Example: "User requested implementation of OAuth authentication feature"

## Work Completed

- [Key accomplishment 1]
- [Key accomplishment 2]
- [Files created/modified with paths]

## Current State

- Active task: [task ID and brief description]
- Work status: [in-progress/blocked/ready for review]
- Key files in focus:
  - `path/to/file1.ext` - [what was done]
  - `path/to/file2.ext` - [current state]

## Context Loading Prompt

---

### Resume Session: [Brief Description]

**Goal:** [Next immediate objective]

**Session Context:**

- Working on: [current feature/task]
- Progress: [percentage or milestones completed]
- Release: [current release if applicable]

**Key Files to Load:**

```

dev-taskflow/current/v.X.Y.Z/tasks/current-task.md
src/main/feature/implementation.rb
spec/feature/implementation_spec.rb
docs/feature-guide.md

```

**Recent Changes:**

- [File]: [Brief description of changes]
- [File]: [Current state/what's pending]

**Next Steps:**

1. [Immediate next action]
2. [Following action]
3. [Subsequent tasks]

**Blockers/Decisions Needed:**

- [Any blockers or pending decisions]

**Commands to Run:**

```bash
# Useful commands to resume work
bin/test spec/feature_spec.rb
bin/lint
git status
```

---
    </template>
</documents>
