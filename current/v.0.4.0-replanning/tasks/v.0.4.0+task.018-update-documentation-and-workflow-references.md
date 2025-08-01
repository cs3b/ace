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

- [ ] **Update Scope**: Should we update historical ADRs and decision records that reference the old command?
- [ ] **Example Migration**: How should we handle embedded code examples in templates that use the old command?
- [ ] **Validation Method**: What is the best approach to systematically verify all references have been updated?
- [ ] **Rollback Plan**: If issues are discovered post-migration, what is the rollback strategy for documentation?

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

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: File structures, code organization, technical architecture
- ❌ **Technology Decisions**: Tool selections, library choices, framework decisions  
- ❌ **Performance Optimization**: Specific performance improvement strategies
- ❌ **Future Enhancements**: Related features or capabilities not in current scope

## References

- Original idea file: dev-taskflow/backlog/ideas/20250731-0828-task-create-migrate.md
- docs/tools.md - Main CLI reference documentation requiring updates
- dev-handbook/workflow-instructions/ - All workflow files using task creation commands
- All spec and test files with command examples
- Project-wide documentation consistency standards