---
id: v.0.5.0+task.020
status: done
priority: medium
estimate: 1h
dependencies: []
---

# Centralize project context loading across all workflow files

## Behavioral Context

**Issue**: Workflow files contained duplicated project context loading instructions, violating DRY principle and making maintenance difficult.

**Key Behavioral Requirements**:
- All workflows should load project context consistently
- Single source of truth for project context loading
- Maintainable and updateable from one location

## Objective

Refactored 27 workflow files to replace manual Project Context Loading sections with a centralized reference to the `load-project-context.wf.md` workflow, improving maintainability and eliminating duplication.

## Scope of Work

- Analyzed all workflow files for Project Context Loading sections
- Replaced duplicated instructions with centralized reference
- Added missing Project Context Loading sections to workflows that lacked them
- Achieved 69-line net reduction across all files

### Deliverables

#### Create

None - used existing load-project-context.wf.md workflow

#### Modify

- dev-handbook/workflow-instructions/*.wf.md (25 files)
- dev-handbook/.meta/wfi/*.wf.md (4 files)
- dev-taskflow/backlog/ideas/commit.wf.md (checked but not a standard workflow)

#### Delete

None - only content within files was removed

## Implementation Summary

### What Was Done

- **Problem Identification**: Discovered duplication of project context loading instructions across 26+ workflow files
- **Investigation**: Analyzed all workflow files to identify patterns and variations in context loading
- **Solution**: Leveraged existing `load-project-context.wf.md` workflow as centralized reference
- **Validation**: Verified all workflows still function correctly with centralized approach

### Technical Details

Replaced sections like:
```markdown
## Project Context Loading

* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`
- Load tools documentation: `docs/tools.md`
```

With:
```markdown
## Project Context Loading

- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`
```

### Files Modified

**Standard workflows updated (20 files):**
- work-on-task.wf.md
- improve-code-coverage.wf.md (kept specialized context)
- synthesize-reflection-notes.wf.md
- draft-task.wf.md
- create-reflection-note.wf.md
- initialize-project-structure.wf.md
- review-code.wf.md
- plan-task.wf.md
- draft-release.wf.md
- publish-release.wf.md
- create-test-cases.wf.md
- create-api-docs.wf.md
- create-adr.wf.md
- save-session-context.wf.md
- rebase-against.wf.md
- fix-tests.wf.md
- create-user-docs.wf.md
- prioritize-align-ideas.wf.md
- update-blueprint.wf.md

**Specialized workflows updated (4 files):**
- document-unplanned-work.wf.md
- synthesize-reviews.wf.md
- .meta/wfi/review-workflows.wf.md (kept workflow-specific context)
- .meta/wfi/manage-workflow-instructions.wf.md (kept workflow-specific context)
- .meta/wfi/review-guides.wf.md (kept guide-specific context)
- .meta/wfi/manage-guides.wf.md (kept guide-specific context)

**Added missing context loading (2 files):**
- update-context-docs.wf.md
- review-task.wf.md

### Testing/Validation

```bash
# Verified changes maintain workflow functionality
grep -r "## Project Context Loading" dev-handbook/workflow-instructions/
grep -r "load-project-context.wf.md" dev-handbook/workflow-instructions/
```

**Results**: All 27 workflow files now consistently reference the centralized load-project-context.wf.md workflow.

## Completion Summary

✅ **Completed**: All workflow files successfully updated to use centralized project context loading
✅ **Statistics**: 104 lines removed, 35 lines added (69 lines net reduction)
✅ **Consistency**: Achieved complete consistency across all workflow files
✅ **Maintainability**: Single source of truth established for project context loading

## References

- Commits: 
  - `704cffd` - refactor: Centralize project context loading (main)
  - `3b87e66` - refactor: Centralize project context loading (dev-handbook)
  - `994297a` - chore: update submodule commit hash
- Related workflow: `dev-handbook/workflow-instructions/load-project-context.wf.md`
- Discussion: User identified duplication and requested centralization