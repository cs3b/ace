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
    * Validate roadmap format against [Roadmap Definition Guide](../guides/roadmap-definition.g.md).
    * If validation fails, refer to definition guide for correction requirements.
3. **Update Release Status**
    * Check current release folder locations:
        * `docs-project/backlog/` - Future releases (should appear in roadmap)
        * `docs-project/current/` - Active releases (should be linked in roadmap)
        * `docs-project/done/` - Completed releases (should be removed from roadmap)
    * Update roadmap links to reflect current release status
    * Remove completed releases from "Planned Major Releases" section (delegate to changelog)
    * Update cross-release dependencies if they reference completed releases

4. **Draft Changes**
    * Source proposed changes from the **input document or prompt** (very often a PRD) to ensure alignment with
      new strategic information.
    * Use a markdown checklist to outline proposed changes, e.g.:

    ```markdown
    - [ ] Add Objective: "Simplify contributor onboarding" (metric: onboarding ≤30 min)
    - [ ] Add Release v.0.4.0 "Autopilot" Q1 2026
    - [ ] Remove completed release v.0.2.0 from roadmap (moved to done/)
    ```

5. **Internal Review**
    * Share draft (PR or discussion).
    * Gather feedback and reach consensus.
6. **Apply Updates**
    * Edit `roadmap.md`, increment `last_reviewed`, update relevant tables.
    * Append an entry to **Update History**.
    * Ensure release status changes are accurately reflected
7. **Validate Synchronization**
    * Verify roadmap "Planned Major Releases" table matches current project folder structure:
        * All releases in `docs-project/backlog/` appear in roadmap
        * No releases in `docs-project/done/` appear in roadmap  
        * Active releases in `docs-project/current/` are properly represented
    * Check cross-release dependencies for accuracy and remove references to completed releases
    * Validate roadmap format compliance against [Roadmap Definition Guide](../guides/roadmap-definition.g.md)
    * Confirm no broken references or outdated information remains
8. **Commit Changes**
    * Follow `commit.md` guideline. Example message:
      > docs(roadmap): add onboarding objective & "Autopilot" release
      > docs(roadmap): update release status - remove completed v.0.2.0
9. **Notify Stakeholders**
    * Post link to PR/revision in communication channel.

## Error Handling

**Format Validation Failures:**

* If roadmap format validation fails in step 2, halt process and report specific violations
* Require format corrections before proceeding with any updates
* Reference [Roadmap Definition Guide](../guides/roadmap-definition.g.md) for correction requirements

**Release Status Inconsistencies:**

* If release folder locations don't match roadmap entries in step 3, report discrepancies
* Require manual reconciliation of project structure or roadmap content
* Document any changes needed to achieve consistency

**Cross-Reference Validation Errors:**

* If broken references are found in step 7, halt process and report specific issues
* Require dependency resolution or reference updates before committing
* Validate all references are reachable after corrections

**Commit/Push Failures:**

* If Git operations fail in step 8, preserve roadmap changes for manual resolution
* Report specific Git error details and suggested recovery actions
* Allow manual commit completion outside workflow if needed

## Output / Success Criteria

* Updated `docs-project/roadmap.md` with changes applied.
* Release status accurately reflects current project folder structure.
* Completed releases removed from roadmap and delegated to changelog.
* `Update History` includes a new entry with release status changes.
* Commit merged following review.

## Cross-Workflow Dependencies

This workflow integrates with release lifecycle management workflows:

* **Called by Draft-Release Workflow**: After step 6 (Ensure Completeness) to add new releases to roadmap
* **Called by Publish-Release Workflow**: During step 15 to remove completed releases from roadmap
* **Calls Commit Workflow**: For all roadmap changes following standard commit practices

**Integration Requirements:**

* Roadmap updates MUST be committed separately from release scaffolding/archival
* Failed roadmap updates in release workflows SHOULD trigger process halt or rollback consideration
* Release status validation MUST check actual project folder structure (`backlog/`, `current/`, `done/`)

## Reference Documentation

* [Roadmap Definition Guide](../guides/roadmap-definition.g.md)
* [Strategic Planning Guide](../guides/strategic-planning.g.md)
* [`breakdown-notes-into-tasks.wf.md` Workflow](breakdown-notes-into-tasks.wf.md)
* [Draft Release Workflow](draft-release.wf.md)
* [Publish Release Workflow](publish-release.wf.md)
* [Commit Workflow](commit.wf.md)
