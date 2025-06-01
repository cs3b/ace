# Workflow Instruction: Manage Roadmap

**Goal:** Propose, review, and apply updates to `docs-project/roadmap.md` ensuring the roadmap remains an accurate
strategic guide.

## Prerequisites

* Current project context loaded via `load-env`.
* Write access to `docs-project/roadmap.md`.

## Process Steps

1. **Select Roadmap**
    * Confirm the file exists at `docs-project/roadmap.md`.
    * Load its content.
2. **Validate Structure**
    * Verify required sections/tables (Vision, Objectives, Themes, Releases, Dependencies, Update History).
    * If missing, stop and raise an issue.
3. **Draft Changes**
    * Source proposed changes from the **input document or prompt** (very often a PRD) to ensure alignment with
      new strategic information.
    * Use a markdown checklist to outline proposed changes, e.g.:

    ```markdown
    - [ ] Add Objective: "Simplify contributor onboarding" (metric: onboarding ≤30 min)
    - [ ] Add Release v.0.4.0 "Autopilot" Q1 2026
    ```

4. **Internal Review**
    * Share draft (PR or discussion).
    * Gather feedback and reach consensus.
5. **Apply Updates**
    * Edit `roadmap.md`, increment `last_reviewed`, update relevant tables.
    * Append an entry to **Update History**.
6. **Commit Changes**
    * Follow `commit.md` guideline. Example message:
      > docs(roadmap): add onboarding objective & "Autopilot" release
7. **Notify Stakeholders**
    * Post link to PR/revision in communication channel.

## Output / Success Criteria

* Updated `docs-project/roadmap.md` with changes applied.
* `Update History` includes a new entry.
* Commit merged following review.

## Reference Documentation

* [Strategic Planning Guide](../guides/strategic-planning.g.md)
* [`breakdown-notes-into-tasks.wf.md` Workflow](breakdown-notes-into-tasks.wf.md)
* [Commit Workflow](commit.wf.md)
