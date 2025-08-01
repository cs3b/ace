---
id: v.0.4.0+task.018
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Update documentation and workflow references

## Behavioral Specification

### User Experience
- **Input**: Users access documentation, workflow instructions, and help text expecting consistent command references
- **Process**: Users experience seamless discovery of task creation commands through unified documentation and examples
- **Output**: Users find consistent, accurate references to task-manager create throughout all project documentation

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

All project documentation, workflow instructions, examples, and help text consistently reference the new task-manager create command instead of the deprecated create-path task-new command. Users can confidently follow any documentation or workflow instruction knowing they will encounter the correct, current command syntax throughout the entire project ecosystem.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# Documentation Interface - All references updated from:
# OLD: create-path task-new --title "Task Name"
# NEW: task-manager create --title "Task Name"

# Files requiring updates:
# - docs/tools.md: Update CLI reference table and examples
# - dev-handbook/workflow-instructions/*.wf.md: Update all workflow steps
# - All spec files: Update test expectations and command examples
# - Help text and usage documentation: Consistent command references

# Validation commands:
# grep -r "create-path task-new" . # Should return no results after update
# grep -r "task-manager create" . # Should show consistent usage patterns
```

**Error Handling:**
- Missed documentation references: Comprehensive grep/search to identify all occurrences
- Inconsistent examples: Systematic review of all code examples and usage patterns
- Workflow instruction failures: Test all updated workflows to ensure they work with new command

**Edge Cases:**
- Comments in code: Update any code comments that reference the old command
- Historical documentation: Consider whether to update or archive older documentation versions
- External references: Identify any external documentation that might reference the old command

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Documentation Consistency**: Zero references to create-path task-new remain in any project documentation
- [ ] **Workflow Functionality**: All workflow instructions execute successfully with updated command references
- [ ] **User Discoverability**: New users can follow any documentation path and encounter consistent command syntax

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [x] **Update Scope**: Should we update historical ADRs and decision records that reference the old command?
  - **Answer**: Yes, update all references for consistency across the entire project ecosystem
- [x] **Example Migration**: How should we handle embedded code examples in templates that use the old command?
  - **Answer**: Update all embedded examples to use task-manager create syntax
- [x] **Validation Method**: What is the best approach to systematically verify all references have been updated?
  - **Answer**: Use systematic grep searches to ensure zero remaining references to create-path task-new
- [x] **Rollback Plan**: If issues are discovered post-migration, what is the rollback strategy for documentation?
  - **Answer**: Revert documentation changes via git commit rollback

## Objective

Ensure users have a consistent, seamless experience when following any project documentation or workflow instructions. By updating all references to use the new task-manager create command, we eliminate confusion and provide a unified command experience that aligns with the improved command structure. This prevents user frustration from encountering deprecated commands in documentation.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: All documentation reading, workflow following, and example usage experiences across the entire project
- **System Behavior Scope**: Documentation consistency, workflow instruction accuracy, and help text correctness
- **Interface Scope**: All written documentation, embedded examples, help text, and workflow instruction files

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- User experience flow definitions
- System behavior specifications  
- Interface contract definitions

#### Validation Artifacts
- Success criteria validation methods
- User acceptance criteria
- Behavioral test scenarios

## Technical Approach

### Architecture Pattern
- [x] Pattern selection and rationale: Systematic documentation update approach
- [x] Integration with existing architecture: Updates documentation to reflect new task-manager create command structure
- [x] Impact on system design: No system design impact - pure documentation changes

### Implementation Strategy
- [x] Step-by-step approach: Systematic search and replace across all project files
- [x] Rollback considerations: Git-based rollback for any problematic changes
- [x] Testing strategy: Verification through grep searches and manual validation
- [x] Performance monitoring: No performance impact expected

## Tool Selection

| Criteria | grep/sed | Manual Edit | Automated Scripts | Selected |
|----------|----------|-------------|-------------------|----------|
| Accuracy | Good | Excellent | Good | Manual Edit |
| Speed | Excellent | Poor | Excellent | Manual Edit |
| Safety | Poor | Excellent | Good | Manual Edit |
| Precision | Good | Excellent | Fair | Manual Edit |

**Selection Rationale:** Manual editing ensures precision and safety for documentation changes while allowing careful review of each context. Though slower, it prevents unintended changes to similar but unrelated text patterns.

## File Modifications

### Modify
- docs/tools.md
  - Changes: Update all create-path task-new references to task-manager create
  - Impact: Main CLI reference documentation reflects new command structure
  - Integration points: Central documentation hub for all tool references

- dev-tools/docs/tools.md
  - Changes: Update CLI tool examples and reference table
  - Impact: Tools-specific documentation consistency
  - Integration points: Technical documentation for dev-tools submodule

- dev-handbook/workflow-instructions/*.wf.md (4 files)
  - Changes: Update all workflow steps to use task-manager create
  - Impact: AI agents and users follow updated command syntax
  - Integration points: Self-contained workflow instruction system

- dev-tools/docs/migrations/migration-guide.md
  - Changes: Update migration examples and command references
  - Impact: Historical migration documentation remains current
  - Integration points: Developer reference documentation

### Comprehensive Update Scope
Based on systematic analysis, 33+ files contain references to create-path task-new:
- Documentation files: Main project docs, tools documentation
- Workflow instructions: AI workflow files in dev-handbook
- Historical files: Task completion records, reflection notes
- Migration guides: Developer reference materials
- Template examples: Embedded command examples

## Risk Assessment

### Technical Risks
- **Risk:** Missing references during manual update process
  - **Probability:** Medium
  - **Impact:** Low  
  - **Mitigation:** Systematic grep validation after updates
  - **Rollback:** Git revert of documentation changes

### Integration Risks
- **Risk:** Updated documentation references non-existent command
  - **Probability:** High
  - **Impact:** High
  - **Mitigation:** Ensure task 017 (implement task-manager create) completes first
  - **Monitoring:** Test command availability before documentation updates

### Performance Risks
- **Risk:** No performance risks identified
  - **Mitigation:** Pure documentation changes have no runtime impact
  - **Monitoring:** No monitoring required
  - **Thresholds:** No performance thresholds applicable

## Out of Scope

- ❌ **Command Implementation**: Task 017 handles actual task-manager create command
- ❌ **Behavioral Changes**: No changes to task creation behavior or interface
- ❌ **Code Modifications**: No Ruby code changes in dev-tools gem
- ❌ **Test Updates**: Test modifications handled by task 017
- ❌ **Breaking Changes**: Documentation updates only, no functional changes

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work.*

### Planning Steps

*Research and design activities to clarify the approach before implementation begins.*

- [x] Analyze current system/codebase to understand existing command references
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All references to create-path task-new are identified and catalogued
  > Command: grep -r "create-path.*task-new" . --include="*.md" | wc -l
- [x] Research documentation architecture and update patterns
- [x] Plan detailed systematic update strategy
- [x] Validate that task-manager create command exists and is functional
  > TEST: Command Availability Check
  > Type: Dependency Validation
  > Assert: task-manager create command is available and functional
  > Command: task-manager create --help

### Execution Steps

*Concrete implementation actions that modify documentation and files.*

- [ ] Update main tools documentation (docs/tools.md)
  > TEST: Verify Main Documentation Update
  > Type: Content Validation
  > Assert: All create-path task-new references replaced with task-manager create
  > Command: ! grep -r "create-path.*task-new" docs/tools.md

- [ ] Update dev-tools specific documentation (dev-tools/docs/tools.md)
  > TEST: Verify Tools Documentation Update
  > Type: Content Validation
  > Assert: All command examples use new syntax
  > Command: ! grep -r "create-path.*task-new" dev-tools/docs/tools.md

- [ ] Update workflow instruction files in dev-handbook
  > TEST: Verify Workflow Instructions Update
  > Type: Content Validation
  > Assert: All workflow files use task-manager create syntax
  > Command: ! grep -r "create-path.*task-new" dev-handbook/workflow-instructions/

- [ ] Update migration guide documentation
  > TEST: Verify Migration Guide Update
  > Type: Content Validation
  > Assert: Migration examples reflect new command structure
  > Command: ! grep -r "create-path.*task-new" dev-tools/docs/migrations/

- [ ] Update historical task and reflection files for consistency
  > TEST: Verify Historical Files Update
  > Type: Content Validation
  > Assert: Historical references updated for consistency
  > Command: ! grep -r "create-path.*task-new" dev-taskflow/ --include="*.md"

- [ ] Perform comprehensive verification scan
  > TEST: Verify Complete Migration
  > Type: Final Validation
  > Assert: Zero references to create-path task-new remain in project
  > Command: ! grep -r "create-path.*task-new" . --include="*.md" --exclude-dir=tmp

## Acceptance Criteria

*Define the conditions that signify the task is complete.*

- [ ] **AC 1**: All documentation files consistently reference task-manager create instead of create-path task-new
- [ ] **AC 2**: All workflow instructions execute successfully with updated command references
- [ ] **AC 3**: Comprehensive grep search returns zero matches for "create-path.*task-new" pattern in active documentation
- [ ] **AC 4**: All embedded examples and code blocks use correct new command syntax
- [ ] **AC 5**: Historical documentation maintains consistency with new command structure

## References

- Original idea file: dev-taskflow/current/v.0.4.0-replanning/docs/ideas/017-20250731-0828-task-create-migrate.md
- Task 017: Add task-manager create subcommand (dependency)
- docs/tools.md - Main CLI reference documentation requiring updates
- dev-handbook/workflow-instructions/ - All workflow files using task creation commands
- Systematic search results: 33+ files containing create-path task-new references
- Project-wide documentation consistency standards