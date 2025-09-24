---
id: v.0.5.0+task.068
status: done
priority: high
estimate: 20m
dependencies: []
---

# Improve next steps task creation clarity in initialize-project-structure workflow

## Behavioral Context

**Issue**: Step 8 of the initialize-project-structure workflow wasn't clear about where the next steps task should be created, potentially causing it to be missed or created in the wrong location.

**Key Behavioral Requirements**:
- Next steps task MUST be created for proper project handoff
- Task should be ID 000 to appear first in task listings
- Must handle both v.0.0.0-bootstrap and v.0.1.0 scenarios
- Task must be verifiable with `task-manager next` command

## Objective

Clarify and improve the next steps task creation logic in the initialize-project-structure workflow to ensure it's always created in the appropriate location.

## Scope of Work

- Made Step 8 more explicit about task location logic
- Added fallback handling for different scenarios
- Enhanced verification steps
- Updated success criteria

### Deliverables

#### Modify

- `.ace/handbook/.integrations/wfi/initialize-project-structure.wf.md`:
  - Enhanced Step 8 with clear location determination logic
  - Added explicit fallback to v.0.1.0 if no bootstrap exists
  - Added verification steps to confirm task creation
  - Updated success criteria to include task verification
  - Updated documentation sections to emphasize critical nature

## Implementation Summary

### What Was Done

- **Problem Identification**: User feedback indicated next steps task was getting lost
- **Investigation**: Found that Step 8 existed but wasn't explicit enough about location
- **Solution**: Enhanced the workflow with clear logic and verification steps
- **Validation**: Reviewed workflow to ensure clarity and completeness

### Technical Details

Updated Step 8 to include:
1. **Determine Task Location** section with explicit logic:
   - If v.0.0.0-bootstrap exists → create as v.0.0.0+task.000
   - Else → create as v.0.1.0+task.000 in backlog
2. **Verification** section with specific checks:
   - Run `task-manager next` to confirm task appears
   - Verify project-specific information (not placeholders)
   - Ensure status is 'pending' and priority is P0
3. Updated documentation sections to emphasize this is **CRITICAL**
4. Added success criteria for task verification

### Changes Made

- Added "(Critical for project continuity)" to Step 8 title
- Made location determination explicit with if/else logic
- Added **IMPORTANT** note about task creation requirement
- Added verification subsection with specific commands
- Updated success criteria to include task verification
- Enhanced documentation sections with fallback notes

## References

- Commits:
  - .ace/handbook: `25068e0` - feat(wfi): add next steps task creation guidance
- Related feedback: User reported lost next steps task in recent testing
- Template: `.ace/handbook/templates/task-management/task.next-steps.template.md`