---
id: v.0.6.0+task.029
status: done
priority: high
estimate: 1h
dependencies: []
---

# Fix invalid Claude tool specifications in command metadata

## Behavioral Context

**Issue**: Claude tool specifications were using invalid syntax `Bash(command)` instead of simple tool names like `Bash`. This caused errors when running `handbook claude integrate --force --debug`.

**Key Behavioral Requirements**:
- Claude commands must use valid tool names without parentheses
- The command metadata inferrer must generate correct tool specifications
- Documentation must reflect correct tool usage patterns

## Objective

Fix invalid tool specifications in the Claude command metadata inferrer to ensure generated commands use valid Claude tool names, preventing errors during command execution.

## Scope of Work

- Fix all invalid `Bash(*)` specifications in command_metadata_inferrer.rb
- Update documentation to reflect correct tool specifications
- Update workflow instruction to include validation steps

### Deliverables

#### Create

- None

#### Modify

- dev-tools/lib/coding_agent_tools/molecules/claude/command_metadata_inferrer.rb
- dev-handbook/.meta/wfi/update-integration-claude.wf.md
- dev-handbook/.integrations/claude/metadata-field-reference.md

#### Delete

- None

## Phases

1. Identify all invalid tool specifications
2. Update command_metadata_inferrer.rb
3. Update documentation
4. Regenerate and test commands

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

- [x] **System Analysis**: Identified that `Bash(command)` format is invalid for Claude tools
- [x] **Root Cause**: Found 5 instances in command_metadata_inferrer.rb using invalid syntax
- [x] **Documentation Review**: Found incorrect examples in metadata-field-reference.md
- [x] **Impact Analysis**: Determined this affects all generated commands

### Execution Steps

- [x] **Fix Tool Specifications**: Updated 5 lines in command_metadata_inferrer.rb
  - Changed `'Bash(git *), Read, Write'` to `'Bash, Read, Write'`
  - Changed `'Read, Write, TodoWrite, Bash(task-manager *)'` to `'Read, Write, TodoWrite, Bash'`
  - Changed `'Read, Write, Bash(bundle exec rspec), Grep'` to `'Read, Write, Bash, Grep'`
  - Changed `'Read, Write, Edit, Bash(bundle exec *), Grep'` to `'Read, Write, Edit, Bash, Grep'`
  - Changed `'Read, Write, Bash(task-manager release *), Grep'` to `'Read, Write, Bash, Grep'`

- [x] **Update Workflow Documentation**: Added validation section to update-integration-claude.wf.md
  - Added tool specification validation guidelines
  - Added diagnostic command: `grep -r "Bash(" dev-handbook/.integrations/claude/`
  - Added quality check item for invalid specifications

- [x] **Update Reference Documentation**: Fixed metadata-field-reference.md
  - Updated format from `Tool(pattern)` to `Tool`
  - Fixed all example tool specifications
  - Updated inference rules table

- [x] **Regenerate Commands**: Ran `handbook claude generate-commands --force`
  - Successfully regenerated 24 commands with correct tool specifications

- [x] **Validate Fix**: Verified no invalid specifications remain
  > Command: grep -r "Bash(" dev-handbook/.integrations/claude/commands/
  > Result: No matches (success)

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
- [x] **Valid Tool Specifications**: All generated commands use simple tool names without parentheses
- [x] **Command Generation**: `handbook claude generate-commands` produces valid tool specifications
- [x] **Documentation Accuracy**: All documentation reflects correct tool usage patterns

### Implementation Quality Assurance  
- [x] **Code Quality**: Changes follow Ruby conventions and project patterns
- [x] **Validation**: No invalid tool specifications remain in generated commands
- [x] **Integration**: Commands work correctly with Claude Code

### Documentation and Validation
- [x] **Workflow Updated**: update-integration-claude.wf.md includes validation steps
- [x] **Reference Updated**: metadata-field-reference.md shows correct examples
- [x] **Verification Command**: Added grep command to check for invalid specifications

## Out of Scope

- ❌ Changing Claude's actual tool system (we only fix our metadata)
- ❌ Modifying how tools are invoked
- ❌ Creating new validation in the Ruby code

## References

- Error encountered: `ERROR: "handbook claude integrate" was called with arguments "--force --debug"`
- Root cause: `Bash(bundle exec rspec)` is not a valid Claude tool specification
- Solution: Use simple tool names like `Bash` without parentheses
- Commit: "fix(claude): correct tool spec and update docs"