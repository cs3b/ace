---
id: v.0.5.0+task.064
status: done
priority: high
estimate: 2h
dependencies: []
---

# Add release-manager draft command for creating release directories

## Behavioral Context

**Issue**: The initialize-project-structure workflow referenced a non-existent `release-manager draft` command, and there was no CLI tool for creating release directory structures.

**Key Behavioral Requirements**:
- Command must create release directories at project root regardless of current directory
- Must use template structure for consistency
- Should generate initial release-overview.md file
- Must validate semantic versioning format

## Objective

Implemented a new `release-manager draft` command that creates release directory structures with proper templates and documentation.

## Scope of Work

- Created new draft command implementation
- Created template directory structure for releases
- Registered command in CLI and release-manager executable
- Ensured project-root relative execution

### Deliverables

#### Create
- `.ace/tools/lib/coding_agent_tools/cli/commands/release/draft.rb` - New command implementation
- `.ace/handbook/.meta/tpl/project-structure/release-dir-structure/` - Template directory structure with:
  - tasks/
  - ideas/
  - docs/ideas/
  - reflections/
  - researches/
  - user-experience/
  - codemods/
  - test-cases/
  - code-review/
  - All with .keep files

#### Modify
- `.ace/tools/lib/coding_agent_tools/cli.rb` - Added draft command registration
- `.ace/tools/exe/release-manager` - Added draft command to release-manager
- `.ace/handbook/.integrations/wfi/initialize-project-structure.wf.md` - Updated to use Claude command instead

#### Delete
- `.ace/handbook/templates/release-v.0.0.0/` - Removed duplicate templates

## Implementation Summary

### What Was Done

- **Problem Identification**: Workflow referenced non-existent bash command
- **Investigation**: Found release-manager lacked draft functionality
- **Solution**: 
  - Implemented full draft command with template support
  - Created reusable template structure
  - Ensured project-root relative execution
  - Added semantic version validation
- **Validation**: Tested command from various directories

### Technical Details

Command features:
- Validates semantic version format (v.X.Y.Z)
- Always operates from project root using ProjectRootDetector
- Copies template structure from .ace/handbook/.meta/tpl/
- Generates release-overview.md with metadata
- Provides helpful next steps

Key implementation decisions:
- Used Pathname for path operations
- Added explicit project root checks
- Included fallback for missing templates
- Clear error messages for common issues

### Testing/Validation

```bash
# Test from different directories
release-manager draft v.0.2.0 testing
cd .ace/handbook && ../.ace/tools/exe/release-manager draft v.0.3.0 another-test

# Verify structure
tree .ace/taskflow/backlog/v.0.2.0-testing/
```

**Results**: 
- Command works from any directory
- Always creates releases at project root
- Proper directory structure with all folders
- release-overview.md generated correctly

## References

- User feedback: "release-manager draft v.0.1.0 foundation => should work"
- Related workflow: initialize-project-structure.wf.md
- Template location: .ace/handbook/.meta/tpl/project-structure/release-dir-structure/