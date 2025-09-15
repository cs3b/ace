---
id: v.0.6.0+task.030
status: done
priority: high
estimate: 2h
dependencies: [v.0.6.0+task.029]
---

# Fix Claude integrate command to preserve YAML frontmatter

## Behavioral Context

**Issue**: When running `handbook claude integrate --force`, command files in `.claude/commands/` were missing their YAML frontmatter (description, allowed-tools, model). Investigation revealed duplicate command generation was overwriting properly formatted files.

**Key Behavioral Requirements**:
- `handbook claude integrate` should copy commands from `.ace/handbook/.integrations/claude/` to `.claude/`
- YAML frontmatter must be preserved during installation
- Template references must use correct paths for installed location
- No duplicate template files should exist

## Objective

Fix the Claude integrate command to properly copy command files without regenerating them, ensuring YAML frontmatter is preserved and template paths are correct for the installed location.

## Scope of Work

- Remove redundant `generate_workflow_commands` call from orchestrator
- Fix template path to reference installed location
- Remove duplicate template file
- Verify commands retain metadata after integration

### Deliverables

#### Create

- None

#### Modify

- .ace/tools/lib/coding_agent_tools/organisms/claude_commands_orchestrator.rb
- .ace/handbook/.integrations/claude/templates/command.md.tmpl

#### Delete

- .ace/handbook/.integrations/claude/command.template.md

## Phases

1. Identify root cause of missing YAML frontmatter
2. Remove duplicate command generation
3. Fix template references
4. Clean up duplicate files
5. Test and verify fix

## Technical Approach

### Architecture Pattern
- [ ] Pattern selection and rationale
- [ ] Integration with existing architecture
- [ ] Impact on system design

### Technology Stack
- [ ] Libraries/frameworks needed
- [ ] Version compatibility checks
- [ ] Performance implications
- [ ] Security considerations

### Implementation Strategy
- [ ] Step-by-step approach
- [ ] Rollback considerations
- [ ] Testing strategy
- [ ] Performance monitoring

## Tool Selection

| Criteria | Option A | Option B | Option C | Selected |
|----------|----------|----------|----------|----------|
| Performance | | | | |
| Integration | | | | |
| Maintenance | | | | |
| Security | | | | |
| Learning Curve | | | | |

**Selection Rationale:** [Explain selection reasoning]

### Dependencies
- [ ] New dependency 1: version and reason
- [ ] New dependency 2: version and reason
- [ ] Compatibility verification completed

## File Modifications

### Create
- path/to/new/file.ext
  - Purpose: [why this file]
  - Key components: [what it contains]
  - Dependencies: [what it depends on]

### Modify
- path/to/existing/file.ext
  - Changes: [what to modify]
  - Impact: [effects on system]
  - Integration points: [how it connects]

### Delete
- path/to/obsolete/file.ext
  - Reason: [why removing]
  - Dependencies: [what depends on this]
  - Migration strategy: [how to handle removal]

## Implementation Plan

<!-- This section details the specific steps required to implement the behavioral requirements -->
<!-- Clear distinction between planning/analysis activities and concrete implementation work -->

### Planning Steps

- [x] **Root Cause Analysis**: Discovered integrate command does two conflicting things:
  1. Copies commands from `_generated/` WITH YAML frontmatter
  2. Then calls `generate_workflow_commands` which regenerates WITHOUT frontmatter
- [x] **Template Investigation**: Found two template files with different paths:
  - `command.template.md` with correct path `@.claude/commands/commit.md`
  - `templates/command.md.tmpl` with incorrect path `@dev-handbook/.integrations/claude/commands/_custom/commit.md`
- [x] **Code Analysis**: Confirmed `generate_workflow_commands` is redundant since commands already exist in `_generated/`

### Execution Steps

- [x] **Remove Redundant Generation**: Removed from orchestrator:
  - Line 151: `generate_workflow_commands(target_base / 'commands')`
  - Method definition lines 196-206
  > Result: Commands are now only copied, not regenerated

- [x] **Fix Template Path**: Updated command.md.tmpl line 10:
  - From: `read and run @dev-handbook/.integrations/claude/commands/_custom/commit.md`
  - To: `read and run @.claude/commands/commit.md`
  > Result: Commit reference works in installed location

- [x] **Remove Duplicate Template**: Deleted `command.template.md`
  > Command: rm .ace/handbook/.integrations/claude/command.template.md
  > Result: Only one template file remains

- [x] **Regenerate Commands**: Updated all commands with fixed template
  > Command: handbook claude generate-commands --force
  > Result: 24 commands regenerated with correct paths

- [x] **Test Integration**: Verified YAML preservation
  > Command: handbook claude integrate --force
  > Verification: .claude/commands/fix-tests.md contains full YAML frontmatter
  > Result: All metadata preserved correctly

## Risk Assessment

### Technical Risks
- **Risk:** [Description]
  - **Probability:** High/Medium/Low
  - **Impact:** High/Medium/Low
  - **Mitigation:** [Strategy]
  - **Rollback:** [Procedure]

### Integration Risks
- **Risk:** [Description]
  - **Probability:** High/Medium/Low
  - **Impact:** High/Medium/Low
  - **Mitigation:** [Strategy]
  - **Monitoring:** [How to detect]

### Performance Risks
- **Risk:** [Description]
  - **Mitigation:** [Strategy]
  - **Monitoring:** [Metrics to track]
  - **Thresholds:** [Acceptable limits]

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [x] **YAML Preservation**: Commands retain all frontmatter when integrated
- [x] **Single Generation**: Commands are generated once, not overwritten
- [x] **Correct Paths**: Template references work in installed location
- [x] **No Duplicates**: Only one template file exists

### Implementation Quality Assurance  
- [x] **Clean Removal**: Redundant code completely removed
- [x] **Template Update**: Path references updated correctly
- [x] **File Cleanup**: Duplicate template deleted

### Documentation and Validation
- [x] **Verification**: Commands show proper metadata after integration
- [x] **Testing**: Both generate and integrate commands work correctly
- [x] **Commit Path**: References to commit.md resolve properly

## Out of Scope

- ❌ Redesigning the command generation system
- ❌ Changing the YAML frontmatter format
- ❌ Modifying command file structure

## References

- Issue: `.claude/commands/fix-tests.md` missing YAML frontmatter
- Root cause: `generate_workflow_commands` overwrites properly formatted files
- Related task: v.0.6.0+task.014 (template organization)
- Commits: 
  - dev-handbook: b31f44b "fix(claude): preserve frontmatter and fix commit path"
  - dev-tools: 94b8169 "fix(claude): preserve YAML frontmatter and use correct commit path"