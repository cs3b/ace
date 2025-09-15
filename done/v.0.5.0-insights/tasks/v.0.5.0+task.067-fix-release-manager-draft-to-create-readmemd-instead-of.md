---
id: v.0.5.0+task.067
status: done
priority: high
estimate: 30m
dependencies: []
---

# Fix release-manager draft to create README.md instead of release-overview.md

## Behavioral Context

**Issue**: The `release-manager draft` command was creating `release-overview.md` instead of the standard `README.md`, making release documentation harder to discover and inconsistent with conventions.

**Key Behavioral Requirements**:
- Release directories should have README.md as the primary documentation file
- README should focus on release goals and scope, not duplicate task details
- The file should use the comprehensive release-overview template

## Objective

Update the release-manager draft command to create README.md with proper release overview template instead of release-overview.md.

## Scope of Work

- Updated file creation to use README.md naming
- Implemented comprehensive release overview template
- Fixed success message to reference correct filename

### Deliverables

#### Modify

- `.ace/tools/lib/coding_agent_tools/cli/commands/release/draft.rb`:
  - Changed `release-overview.md` to `README.md` in line 124
  - Updated template content with full release overview structure
  - Fixed success message to reference README.md

## Implementation Summary

### What Was Done

- **Problem Identification**: User feedback indicated missing README.md in release directories
- **Investigation**: Found that draft command was creating release-overview.md instead
- **Solution**: Updated the Draft command class to use proper naming and template
- **Validation**: Tested with `release-manager draft v.0.1.0 test-foundation` successfully

### Technical Details

Changed the `create_release_overview` method to:
1. Create `README.md` instead of `release-overview.md`
2. Use comprehensive template based on `.ace/handbook/templates/release-management/release-overview.template.md`
3. Include all standard sections: Goals, Dependencies, Implementation Plan, Quality Assurance, Release Checklist

### Testing/Validation

```bash
# Created test release
cd /tmp && mkdir -p test-project/.ace/taskflow/backlog
cd test-project && release-manager draft v.0.1.0 test-foundation

# Verified README.md was created
ls -la /tmp/test-project/.ace/taskflow/backlog/v.0.1.0-test-foundation/
# Confirmed README.md exists with proper content
```

**Results**: Successfully created README.md with comprehensive release overview template

## References

- Commits: 
  - dev-tools: `a516787` - feat(release): update release overview to README and improve content
- Related feedback: User reported missing README.md in v.0.1.0-foundation release directories
- Template source: `.ace/handbook/templates/release-management/release-overview.template.md`