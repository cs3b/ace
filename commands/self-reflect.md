# Self-Reflect Command

This command guides the process of **analyzing** a completed unit of work (e.g., a task, a feedback cycle, a development day) to capture learnings, assess quality, and identify actionable improvements for the codebase and the development process itself.

**Run this command at logical breakpoints:** after completing a significant task, after implementing PR feedback, or at the end of a development session.

It is distinct from `log-session`, which primarily captures technical state for session resumption.

## Process Steps

1. Analysis Context:
   - Review recent commit history related to the completed work (`git log --since='...'`).
   - Review the completed task file(s) in `docs-dev/project/current/{release_dir}/tasks/`.
   - Consider the associated code changes and test results.

2. Review Areas (Focus on the recently completed work):

   A. Coding Session Review:
      - AI interaction effectiveness
      - Solution quality assessment
      - Knowledge preservation
      - Pattern recognition

   B. Commit Analysis:
      - Commit message clarity
      - Change atomicity
      - Documentation updates
      - Test coverage

   C. Architecture Impact:
      - Design principles alignment
      - Component relationships
      - Interface contracts
      - Technical debt assessment

   D. Collaboration Workflow Analysis:
      - Task breakdown effectiveness
      - Communication clarity
      - Decision-making process
      - Knowledge sharing practices
      - Testing and validation approach
      - Implementation planning quality
      - Progress tracking methods

   E. Release Progress:
      - Feature completeness
      - Documentation status
      - Test coverage
      - Release readiness

3. Actionable Outcomes & Knowledge Capture:

Based on the review, take the following actions:

*   **Document Decisions:** If significant architectural or design decisions were made, create or update an ADR in `docs-dev/decisions/`.
*   **Update Documentation:**
    *   Refine code comments for clarity.
    *   Update relevant guides in `docs-dev/guides/` if standards or best practices need modification based on learnings.
    *   Update the specific task `.md` file in `docs-dev/project/current/{release_dir}/tasks/` with final notes or implementation details if necessary.
    *   Update `docs-dev/project/architecture.md` if the changes impacted the overall architecture.
*   **Record Findings:** Add specific technical findings or research notes to `docs-dev/project/current/{release_dir}/researches/` if applicable.
*   **Identify Process Improvements:** Note down specific ways the development process, commands, or collaboration could be improved.
*   **Create Backlog Tasks:** **Crucially**, for any identified improvements (process changes, refactoring needs, non-trivial follow-up work) that aren't immediate fixes, **create new task `.md` files** in `docs-dev/project/backlog/` (e.g., for a future `v.X.Y.Z-ProcessImprovements` release). This ensures reflections lead to action.
*   **Log Reflection:** Create a reflection summary document for this session/task using the template below and save it within the current release's reflection directory (e.g., `docs-dev/project/current/{release_dir}/reflections/YYYYMMDD-taskID.md`).



## Success Criteria

1.  **Analysis Performed:** The completed work (code, tests, task execution) has been reviewed against the review areas (Coding Session, Commit, Architecture, Workflow).
2.  **Learnings Captured:** Key insights, successful patterns, and challenges encountered are documented in a reflection file within the release directory (`project/current/{release}/reflections/`).
3.  **Documentation Updated:** Relevant code comments, guides, ADRs, or architecture documents have been updated based on the reflection.
4.  **Actionable Improvements Identified:** Specific improvements for the codebase or development process are noted.
5.  **Backlog Updated:** Necessary follow-up actions or process improvements have been converted into new tasks in `docs-dev/project/backlog/`.

## Reflection Log Template & Location

1.  **Location:** Reflection summaries should be saved within the corresponding release directory:
    ```
    docs-dev/project/{current|done}/{release_dir}/reflections/YYYYMMDD-{taskID_or_topic}.md
    ```
    *Example:* `docs-dev/project/current/v.0.2.0-StreamlineWorkflow/reflections/20250415-Task02.md`

2.  **Template Format:** Use the following Markdown structure for each reflection file:

    ```markdown
    # Reflection: [Brief Title - e.g., Task 02 Implementation] - YYYY-MM-DD

    ## 1. Summary of Work Completed
    - Briefly describe the task(s) or work unit being reflected upon.
    - Link to relevant task files or commits.

    ## 2. Key Learnings & Observations
    - **What went well?** (e.g., Effective AI interactions, good test coverage, clear task breakdown)
    - **What was challenging?** (e.g., Ambiguous requirements, unexpected technical hurdles, inefficient workflow step)
    - **Surprises or Discoveries:** (e.g., Found a useful library, uncovered hidden complexity)

    ## 3. Quality Assessment
    - **Code Quality:** (e.g., Adherence to standards, readability, potential refactoring needs)
    - **Test Quality:** (e.g., Coverage, clarity of tests, edge cases handled)
    - **Documentation Quality:** (e.g., Clarity of comments, accuracy of updated guides/ADRs)

    ## 4. Actionable Improvements & Next Steps
    - **Immediate Fixes/Updates Made:** (e.g., Updated guide X, added comment Y, created ADR Z)
    - **Process Improvements Identified:** (e.g., Suggest changing command X, need better template for Y)
    - **Code Refactoring / Tech Debt Noted:** (e.g., Module A needs refactoring, investigate performance issue B)
    - **New Backlog Tasks Created:** (List any tasks created in `docs-dev/project/backlog/` based on this reflection. Include links.)
      - `docs-dev/project/backlog/v.X.Y.Z-ProcessImprovements/tasks/NN-ImproveCommandX.md`
      - `docs-dev/project/backlog/v.A.B.C-FeatureRefactor/tasks/MM-RefactorModuleA.md`

    ## 5. AI Collaboration Notes (Optional)
    - Effective prompts or interaction patterns used.
    - Areas where AI assistance was less helpful or required significant guidance.
    ```

3.  **Usage:**
    *   Create a new reflection file after completing a logical unit of work.
    *   Focus on concise, actionable insights.
    *   Use these reflections during release retrospectives or when planning future work.
    *   Periodically review reflections across releases to identify broader patterns (a global `docs-dev/reflections/cross_release_insights.md` could summarize these).



## Reference Documentation

- [Project Management Guide](../guides/project-management.md) (Task structure, workflow)
- [Documentation Guide](../guides/documentation.md)
- [Generate ADR Command](./docs/generate-adr.md) (Referenced in Actions)
- `log-session` command (for context capture - documentation to be created in Task 04)

## Collaboration Workflow Reflection Guide

When analyzing collaboration workflows, focus on these key dimensions:

1. **Task Management**
   - How effectively were tasks broken down?
   - Was progress tracked transparently?
   - Were dependencies and blockers identified early?

2. **Communication Patterns**
   - Was knowledge shared clearly and proactively?
   - Were questions answered comprehensively?
   - Was contextual information provided with changes?

3. **Decision-Making Process**
   - Were options explored before committing to solutions?
   - Was rationale documented for key decisions?
   - Were tradeoffs clearly articulated?

4. **Implementation Approach**
   - Was planning conducted before implementation?
   - Were checkpoint reviews performed?
   - Was the approach adjusted based on emerging information?

5. **Testing and Validation**
   - Were tests written/updated appropriately?
   - Was validation conducted at key milestones?
   - Were edge cases considered?

6. **Knowledge Capture**
   - Were insights documented during the process?
   - Were reusable patterns identified?
   - Was documentation updated to reflect new knowledge?

For each dimension, identify:
- What worked well (continue)
- What could be improved (change)
- What new practices to try (start)
- What practices to eliminate (stop)

This analysis should produce specific, actionable insights that can be applied to future collaboration sessions.
