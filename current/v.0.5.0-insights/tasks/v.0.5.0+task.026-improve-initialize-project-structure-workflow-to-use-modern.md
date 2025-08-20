---
id: v.0.5.0+task.026
status: done
priority: high
estimate: 1h
dependencies: []
---

# Improve initialize-project-structure workflow to use modern dev-tools

## Behavioral Context

**Issue**: The initialize-project-structure workflow was outdated and contained deprecated patterns:
- Still created bin/ scripts (test, lint, build, run) that are now handled by dev-tools
- Manual dotfiles installation instead of using `handbook claude integrate`
- Incorrect decisions directory location (dev-taskflow/decisions instead of docs/decisions)
- Redundant tool documentation in architecture template

**Key Behavioral Requirements**:
- Workflow should leverage modern dev-tools commands
- Use handbook CLI for Claude integration
- Follow current project structure standards
- Remove deprecated binstub patterns

## Objective

Updated the initialize-project-structure workflow to align with current dev-tools architecture and remove deprecated patterns.

## Scope of Work

- Removed outdated binstub creation and templates
- Added Claude integration via `handbook claude integrate`
- Fixed decisions directory location
- Updated architecture template to reference dev-tools
- Enhanced prerequisites and workflow context

### Deliverables

#### Create
- None (modification only)

#### Modify
- dev-handbook/workflow-instructions/initialize-project-structure.wf.md
  - Replaced binstub setup with dev-tools integration
  - Added Claude integration step
  - Updated documentation generation
  - Fixed directory structure creation
  - Enhanced success criteria

#### Delete
- Removed binstub templates from workflow (test, lint, build, run)

## Implementation Summary

### What Was Done

- **Problem Identification**: Reviewed feedback in dev-taskflow/backlog/ideas/wf-initiliaze-project-structure-feedback.md
- **Investigation**: Analyzed current dev-tools capabilities and handbook CLI features
- **Solution**: Systematically updated workflow to use modern patterns
- **Validation**: Verified all changes align with current project structure

### Technical Details

Key changes made:
1. Replaced Step 4 "Setup Project bin/ Scripts from Binstubs" with "Setup Dev-Tools Integration"
2. Added Step 3 "Install Claude Integration and Configuration Files" using `handbook claude integrate`
3. Fixed directory creation to include `docs/decisions/` for ADRs
4. Updated architecture template section from "Command-line Tools (bin/)" to "Development Tools"
5. Removed all binstub template embeddings (400+ lines)
6. Updated prerequisites to require Ruby >= 3.2 and submodules
7. Enhanced workflow context and success criteria

### Testing/Validation

```bash
# Verified handbook command exists and has Claude integration
dev-tools/exe/handbook claude --help

# Checked available dev-tools commands
ls -la dev-tools/exe/
```

**Results**: Confirmed all referenced tools and commands are available and functional

## References

- Commits: Made changes to initialize-project-structure.wf.md
- Related issues: dev-taskflow/backlog/ideas/wf-initiliaze-project-structure-feedback.md
- Documentation: Updated embedded templates within workflow
- Follow-up needed: None - work is complete