---
name: task-review
allowed-tools: Bash, Read
description: Review draft tasks for readiness, vertical slice quality, verification plans, and promotion to pending
doc-type: workflow
purpose: Review draft tasks for readiness and quality before promotion
ace-docs:
  last-updated: '2026-03-03'
---

# Review Task Workflow Instruction

## Goal

Validate draft behavioral specifications and promote to pending when ready. This workflow acts as the readiness gate between drafting and implementation. It reviews draft tasks for completeness, conducts autonomous research to resolve open questions, generates critical questions for unresolved items, and either promotes validated drafts to `status: pending` or blocks with `needs_review: true` when questions remain.

## Prerequisites

- Task file exists, primarily with `status: draft`
- Understanding of task's current state and content structure
- Write access to task files in `.ace-tasks/`
- Access to project documentation and codebase for research

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## Process Steps

1. **Load and Analyze Draft Task:**
   - **Task Selection:**
     - If specific task provided: Use the provided task path
     - If no task specified: Run `ace-task list --status draft` to view draft tasks
   - **Load Task Content:**
     - Read the task file from the identified path
     - Verify the task has `status: draft`
     - Detect whether the task is an orchestrator with subtasks
     - If the task is an orchestrator:
       - Enumerate child subtasks and their current statuses before any promotion
       - Treat every child subtask still in `draft` as an additional review target
       - Review draft subtasks first and defer any parent promotion decision until child review outcomes are known
     - Parse the behavioral specification sections:
       - User Experience (input, process, output)
       - Expected Behavior
       - Interface Contract
       - Success Criteria
       - Validation Questions
       - Vertical Slice Decomposition (Task/Subtask Model)
       - Verification Plan
       - Frontmatter `bundle` block (`presets`, `files`, `commands`)
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

4. **Readiness Checklist:**
   Evaluate the draft against these readiness criteria:

   - [ ] **Behavioral Spec Complete**: User Experience section defines input, process, and output
   - [ ] **Expected Behavior Defined**: Clear description of what the system should do
   - [ ] **Interface Contracts Specified**: CLI/API/UI contracts with examples
   - [ ] **Success Criteria Measurable**: Observable, testable outcomes defined
   - [ ] **Scope Boundaries Clear**: In-scope and out-of-scope explicitly stated
   - [ ] **Validation Questions Addressed**: All validation questions either answered or documented as blocking
   - [ ] **Vertical Slice Quality (Task/Subtask)**: Scope is decomposed into end-to-end capability slices (standalone task or orchestrator+subtasks), not horizontal layer-only work
   - [ ] **Subtask Slice Clarity**: Each subtask has a distinct observable outcome and does not duplicate sibling scope
   - [ ] **Child Readiness Complete** (orchestrators only): Every draft child subtask has been reviewed and either promoted to `pending` or blocked with documented questions
   - [ ] **Tracer-First for Uncertain Architecture**: For uncertain/novel execution paths, first subtask is a tracer slice validating viability
   - [ ] **Slice Size Signal Present**: Each slice includes advisory size (`small|medium|large`) for planning visibility
   - [ ] **Decision-Complete Spec**: Implementer can execute without inventing missing behavioral decisions
   - [ ] **Defaults Declared**: Ambiguous/unspecified behavior has explicit defaults
   - [ ] **Verification Plan Present**: Spec includes explicit verification plan with concrete scenarios and commands/checks
   - [ ] **Verification Coverage**: Verification includes unit/equivalent checks, integration/E2E checks when needed, and at least one failure/invalid-path check
   - [ ] **Success Criteria ↔ Verification Mapping**: Each success criterion has corresponding verification evidence path
   - [ ] **Bundle Frontmatter Present**: Task frontmatter includes `bundle` with keys `presets`, `files`, `commands` in canonical order
   - [ ] **Bundle Context Completeness**: `bundle.files` includes all critical context artifacts required for fresh-session execution
   - [ ] **No Contradictory Directives**: Scan spec for conflicting instructions (e.g., "replace X" and "preserve X" for same entity; "add" and "remove" same dependency). Flag any contradictions as HIGH priority questions
   - [ ] **Consumer Packages Listed**: When interfaces change (CLI flags, config keys, protocol URIs), spec identifies which packages consume the interface and will need updates
   - [ ] **Deliverables Match Scope**: Number of deliverables is proportional to scope -- flag if spec lists 3 deliverables but scope implies 15+ file changes
   - [ ] **Operating Modes Covered**: Spec addresses relevant operating modes (dry-run, force, verbose, quiet) or explicitly marks them out-of-scope
   - [ ] **Degenerate Inputs Covered**: Spec considers identity operations (X=Y), empty inputs, and self-referential calls where the same entity appears in both argument positions
   - [ ] **Per-Path Variations Covered**: If spec says "same behavior for X and Y", it enumerates edge cases unique to each path (guard logic, error handling, parameter differences)
   - [ ] **End-State Coherence** (orchestrator subtasks only): Concepts introduced by this subtask
         (new fields, modes, formats) are expected to exist in the final deliverable --
         not be removed by a later subtask. If this subtask adds a concept that a later
         subtask will consolidate away, flag as SCOPE RISK and consider merging subtasks.
   - [ ] **Title Length**: Title is max 80 characters
   - [ ] **Folder Slug**: 3-5 word context slug for folder
   - [ ] **File Slug**: 4-7 word action slug for spec file
   - [ ] **No Slug Repetition**: Subtask slugs do not repeat words from parent folder slug
   - [ ] **Usage Documentation Present**: If task changes CLI/API/workflow/config interfaces, `ux/usage.md` exists with concrete usage scenarios
   - [ ] **No Blocking Questions Remain**: All HIGH priority questions resolved or have acceptable defaults

   **Assessment:**
   - If ALL checklist items pass: Task is ready for promotion
   - If ANY checklist item fails: Task needs work, document what's missing
   - `large` slice signal alone is advisory and does not block promotion

5. **Promote or Block:**

   **If Ready (all readiness criteria met):**
   - **Orchestrator rule:** If the task is an orchestrator, only promote the parent after all draft child subtasks have been reviewed and promoted successfully.
   - **Recursive promotion for orchestrators:**
     - Review each draft child subtask using the same checklist
     - Promote each child subtask that passes:
       ```bash
       ace-task update <child-ref> --set status=pending
       ace-task update <child-ref> --set needs_review=false
       ```
     - For any child subtask that fails, keep it in `draft`, set `needs_review=true`, and do not promote the parent
   - Promote the task status and clear any existing `needs_review` flag:
     ```bash
     ace-task update <ref> --set status=pending
     ace-task update <ref> --set needs_review=false
     ```
   - Report promotion:
     ```
     Task <ref> promoted from draft to pending.
     Readiness: All behavioral specs validated, no blocking questions.
     Ready for implementation via ace-assign.
     ```
   - **Orchestrator summary requirement:**
     - Report how many child subtasks were reviewed
     - Report how many child subtasks were promoted
     - Report whether parent promotion was deferred due to any blocked child

   **If Not Ready (blocking questions or gaps remain):**
   - Add `needs_review: true` to task metadata (`ace-task update <ref> --set needs_review=true`)
   - Keep status as `draft`
   - Report blocking status:
     ```
     Task <ref> remains draft.
     needs_review: true -- N HIGH priority questions require human input.
     See Review Questions section in task file.
     ```

6. **Question Documentation and Persistence:**
   - **Persist Questions in Task File:**
     - Add questions directly to the task file (not just review output)
     - Place in dedicated section for easy access and tracking
     - Questions remain until explicitly answered and removed
     - Enable independent review/answering sessions
   - **Question Section Placement:**
     - For draft tasks: After metadata, before main content
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

7. **Review Completion and Summary:**
   - **Generate Review Summary:**
     - List all questions generated with priorities
     - Highlight critical blockers that need answers
     - Report readiness checklist results
     - State whether task was promoted or blocked
   - **Summary Format:**
     ```markdown
     ## Review Summary

     **Readiness Checklist:** X/N criteria met
     **Questions Generated:** X total (Y high, Z medium)
     **Critical Blockers:** [List HIGH priority questions]
     **Advisories:** [List non-blocking advisories such as large slice size]
     **Decision:** Promoted to pending / Remains draft (needs_review: true)
     **Recommended Next Steps:** Based on current state...
     ```
   - **Orchestrator runs should also include:**
     - `Subtasks Reviewed: X`
     - `Subtasks Promoted: Y`
     - `Subtasks Blocked: Z`
     - `Parent Decision: promoted / deferred`

## Secondary Support: Non-Draft Statuses

While review-task primarily serves as the draft-to-pending gate, it can provide lightweight review for other statuses:

- **Pending tasks**: Validate implementation plan completeness, check for stale assumptions
- **In-progress tasks**: Document progress, identify blockers, update remaining steps
- **Completed tasks**: Add retrospective notes, identify follow-up tasks

For non-draft tasks, skip the Readiness Checklist and Promote/Block steps. Focus on content enhancement and question generation only.

## Decision Guidance

### When to Use This Workflow

**Use review-task when:**
- Validating a draft task for promotion to pending
- Refining draft specifications before implementation
- Researching answers to open questions on draft tasks
- Checking if a draft is implementation-ready

**Don't use review-task when:**
- Creating new tasks (use draft-task)
- Planning implementation details (use plan-task via ace-assign)
- Executing implementation (use work-on-task)
- Converting ideas to tasks (use draft-task with idea input)

## Success Criteria

- Draft task validated against readiness checklist
- Critical questions generated and documented with research context
- Questions prioritized by implementation impact
- Default assumptions provided for all questions
- Vertical slice quality validated using task/subtask model
- Verification Plan quality validated against success criteria
- Bundle frontmatter (`presets`, `files`, `commands`) validated for completeness
- Task promoted to pending if ready, or blocked with `needs_review: true`
- Orchestrator parents are promoted only after draft child subtasks have also passed review
- Structure and formatting preserved
- No loss of existing information
- Clear improvement in task clarity or completeness
- User receives actionable list of questions to answer (if any)

## Task Management Integration

### Finding Tasks Needing Review

```bash
# List all draft tasks ready for review
ace-task list --status draft

# List all tasks requiring human input (using preset)
ace-task list needs-review

# Alternative: use ace-search to find tasks with needs_review flag
cd .ace-tasks && ace-search "needs_review: true" --content
```

### Review Workflow Patterns

1. **Draft Validation Session:**
   - Run filter to find draft tasks
   - Review behavioral spec completeness
   - Promote ready tasks, block incomplete ones

2. **Question Resolution Session:**
   - Run filter to find tasks needing review
   - Answer questions in batch
   - Remove `needs_review` flag as questions are resolved
   - Re-run review-task to promote

3. **Continuous Improvement:**
   - AI agents autonomously research first
   - Only escalate true blockers
   - Questions persist for asynchronous handling

## Error Handling

### Common Issues and Solutions

**"Task not found" Error:**
- **Cause**: Invalid task path or ID
- **Solution**: Use `ace-task list` to find correct path

**"Task is not draft" Warning:**
- **Cause**: Task has a non-draft status
- **Solution**: Review-task primarily targets draft tasks. For other statuses, use lightweight review mode (skip readiness checklist and promotion)

**"Structure validation failed" Error:**
- **Cause**: Breaking required task structure
- **Solution**: Preserve original section organization

## Integration with Other Workflows

### Upstream Workflows
- **capture-idea**: Ideas that become tasks may need review for clarity
- **draft-task**: New drafts are the primary input for review-task

### Downstream Workflows
- **plan-task (via ace-assign)**: JIT implementation planning for promoted pending tasks
- **work-on-task**: Reviewed and promoted tasks are clearer to implement

## Key Value: Draft-to-Pending Readiness Gate

The review-task workflow serves as the quality gate between specification and implementation:

1. **Research-First Approach**: AI agents attempt to find answers through documentation, codebase analysis, and pattern recognition before escalating
2. **Readiness Checklist**: Systematic validation ensures behavioral specs are complete before promotion
3. **Smart Question Filtering**: Only truly unresolvable questions requiring business/design decisions are escalated
4. **Persistent Question Tracking**: Questions are saved in task files with `needs_review: true` metadata for easy filtering
5. **Clear Lifecycle Decision**: Every review results in either promotion to pending or documented blocking questions

This approach enables:
- **Clear Lifecycle Gate**: Draft tasks must pass validation before entering the implementation pipeline
- **Efficient Human Time**: Humans only address true decision points
- **Better Quality**: Research context leads to more informed decisions
- **Task Management Integration**: Easy tracking of tasks needing attention

---

This workflow ensures draft tasks are validated and promoted to pending when ready, or blocked with clear questions when not, serving as the quality gate between behavioral specification and implementation planning.
