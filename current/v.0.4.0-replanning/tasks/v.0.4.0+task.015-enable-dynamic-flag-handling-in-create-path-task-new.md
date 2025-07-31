---
id: v.0.4.0+task.015
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Enable Dynamic Flag Handling in create-path task-new

## Behavioral Specification

### User Experience
- **Input**: Users provide the `create-path task-new` command with both defined flags (like `--title`) and arbitrary undefined flags (like `--status draft`, `--priority high`, `--custom-field value`) that should become task metadata
- **Process**: Users experience seamless task creation where any undefined flags are automatically captured and converted into YAML metadata without requiring command definition updates
- **Output**: Users receive a created task file with all undefined flags properly stored as top-level YAML metadata, enabling flexible task attribute assignment

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

The `create-path task-new` command should automatically capture any undefined command-line flags and convert them into YAML metadata in the created task file. This enables users and workflows to dynamically add custom attributes like status, priority, estimation, or any other metadata fields without requiring updates to the command definition.

When users provide undefined flags, the system should:
- Parse the flag name and value pairs
- Convert them into appropriate YAML format 
- Store them as top-level metadata in the task file
- Provide clear feedback about which attributes were added
- Handle type conversion intelligently (strings, numbers, booleans)
- Maintain compatibility with existing defined flags

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# CLI Interface - Enhanced create-path task-new
create-path task-new --title "Task Title" [--defined-flags] [--any-undefined-flag value]

# Examples of dynamic flag usage:
create-path task-new --title "Fix Bug" --status draft --priority high --estimate "2h"
create-path task-new --title "Feature" --status todo --assignee "dev-team" --sprint "sprint-1"
create-path task-new --title "Research" --category research --complexity medium --blocking true

# Expected outputs:
# Task created: /path/to/task.md
# Added metadata: status=draft, priority=high, estimate=2h
# Status: success (exit code 0)

# Alternative --metadata flag approach:
create-path task-new --title "Task" --metadata "status:draft,priority:high,estimate:2h"
```

**Error Handling:**
- Invalid flag values (e.g., malformed syntax): Skip the invalid flag, report warning, continue with remaining flags
- Flag name conflicts with defined flags: Defined flags take precedence, warn about override
- YAML serialization errors: Report specific parsing error, suggest valid format
- Permission errors during file creation: Standard file creation error handling

**Edge Cases:**
- Empty flag values (--flag ""): Store as empty string in YAML
- Numeric flag values (--priority 5): Automatically detect and store as integer/float
- Boolean-like values (--blocking true): Convert "true"/"false" strings to boolean YAML
- Special characters in flag names: Sanitize flag names to valid YAML keys
- Duplicate flag definitions: Last occurrence takes precedence with warning

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Dynamic Metadata Creation**: Users can add arbitrary metadata to tasks via undefined command-line flags without modifying the create-path command definition
- [ ] **Workflow Integration**: AI workflows and automation scripts can pass context-specific task attributes dynamically during task creation
- [ ] **YAML Compatibility**: All undefined flags are properly serialized as valid YAML metadata that integrates with existing task management workflows
- [ ] **Type Intelligence**: Flag values are automatically converted to appropriate YAML types (string, integer, float, boolean) based on content analysis
- [ ] **Error Resilience**: Invalid or problematic flags are handled gracefully without breaking task creation

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [ ] **Requirement Clarity**: Should the --metadata flag be implemented as an alternative/fallback option, or is dynamic flag parsing the primary approach?
- [ ] **Edge Case Handling**: How should the system handle flag names that might conflict with future defined flags added to create-path?
- [ ] **User Experience**: What level of type detection is expected for flag values (basic string/number/boolean vs. more complex types)?
- [ ] **Success Definition**: Should there be limits on the number or complexity of dynamic flags to prevent command-line bloat?
- [ ] **Integration**: How should this feature integrate with existing task template systems and YAML frontmatter validation?

## Objective

Enable flexible and dynamic task creation by allowing users to add arbitrary metadata attributes without requiring command definition updates. This empowers AI workflows, automation scripts, and users to create richly attributed tasks that integrate seamlessly with the existing task management system. The behavioral outcome is reduced friction in task creation workflows and enhanced automation capabilities.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Command-line task creation with dynamic metadata assignment, workflow automation with custom attributes, error handling and feedback for invalid flags
- **System Behavior Scope**: Automatic flag parsing and YAML metadata generation, intelligent type conversion, graceful error handling, compatibility with existing task templates
- **Interface Scope**: Enhanced create-path task-new command interface, optional --metadata flag as alternative, integration with existing YAML frontmatter system

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

- Enhanced idea: dev-taskflow/backlog/ideas/20250731-0800-flag-attribute-yaml.md
- Existing create-path command documentation in docs/tools.md
- YAML frontmatter examples in dev-taskflow/current/v.0.4.0-replanning/tasks/
- Task template structure at dev-handbook/templates/task-management/task.draft.template.md