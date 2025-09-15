---
id: v.0.5.0+task.066
status: done
priority: high
estimate: 30m
dependencies: [v.0.5.0+task.064, v.0.5.0+task.065]
---

# Update draft-release workflow to use release-manager draft command

## Behavioral Context

**Issue**: The draft-release workflow was manually creating directory structures and release overview files, duplicating functionality that the `release-manager draft` command already provides. Additionally, it was creating `v.X.Y.Z-codename.md` instead of the standard `README.md`.

**Key Behavioral Requirements**:
- Use existing tooling (`release-manager draft`) instead of manual steps
- Follow standard naming convention (README.md) for release overviews
- Maintain consistency with other workflows (initialize-project-structure)
- Simplify the workflow by removing redundant manual operations

## Objective

Update the draft-release workflow to leverage the `release-manager draft` command for creating release structures and standardize the release overview filename to README.md.

## Scope of Work

- Replaced manual directory creation with `release-manager draft` command
- Added step to rename `release-overview.md` to `README.md`
- Updated all references to use README.md
- Simplified validation steps
- Updated error handling for new approach

### Deliverables

#### Modified
- `dev-handbook/workflow-instructions/draft-release.wf.md`
  - Step 2: Now uses `release-manager draft v.X.Y.Z codename`
  - Step 3: Renames `release-overview.md` to `README.md`
  - Step 4: References `README.md` instead of `v.X.Y.Z-codename.md`
  - Step 8: Simplified validation
  - Error handling: Added release-manager failures, updated for README.md

## Implementation Summary

### What Was Done

- **Problem Identification**: User feedback during review of initialize-project-structure improvements revealed that draft-release workflow should also use `release-manager draft` and README.md naming
- **Investigation**: 
  - Analyzed current draft-release workflow manual steps
  - Examined what `release-manager draft` command creates
  - Confirmed it creates `release-overview.md` and full directory structure
- **Solution**: 
  1. Replaced Step 2 manual directory creation with `release-manager draft` command
  2. Added rename step to convert `release-overview.md` to `README.md`
  3. Updated all file references throughout workflow
  4. Simplified validation (trust tool-created structure)
  5. Added error handling for release-manager failures
- **Validation**: Verified all references updated and workflow logic intact

### Technical Details

**Changes to Step 2:**
- Removed ~15 lines of manual mkdir commands
- Single command now creates entire structure: `release-manager draft v.X.Y.Z codename`

**New Step 3:**
```bash
mv dev-taskflow/backlog/v.X.Y.Z-codename/release-overview.md \
   dev-taskflow/backlog/v.X.Y.Z-codename/README.md
```

**Updated validations:**
- Removed subdirectory checks (guaranteed by tool)
- Changed from checking `v.X.Y.Z-codename.md` to `README.md`

**Error handling additions:**
- New section for "Release-manager Draft Failures"
- Updated "README.md Rename Failures" (replaced Directory Creation)
- Simplified recovery steps

### Testing/Validation

```bash
# Verified release-manager draft references
grep -n "release-manager draft" dev-handbook/workflow-instructions/draft-release.wf.md
# Result: 5 references found in appropriate locations

# Confirmed README.md references
grep -n "README.md" dev-handbook/workflow-instructions/draft-release.wf.md  
# Result: All overview references updated to README.md

# Checked success criteria updates
grep "README.md created and populated" dev-handbook/workflow-instructions/draft-release.wf.md
# Result: Success criteria properly updated
```

**Results**: Workflow successfully updated to use tooling and standard conventions

## References

- Related task: v.0.5.0+task.064 (release-manager draft command implementation)
- Related task: v.0.5.0+task.065 (NEXT_STEPS.md taskflow integration)
- Commits: To be created after this documentation
- Follow-up needed: None - implementation complete