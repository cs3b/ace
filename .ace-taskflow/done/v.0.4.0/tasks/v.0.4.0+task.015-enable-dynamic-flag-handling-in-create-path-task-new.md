---
id: v.0.4.0+task.015
status: done
priority: high
estimate: 6h
dependencies: []
---

# Enable Dynamic Flag Handling in create-path task-new

## Technical Approach

### Architecture Pattern
The solution integrates with the existing ATOM architecture by extending the CreatePathCommand at the Molecule level. The approach maintains compatibility with dry-cli while adding pre-processing capabilities for undefined flags.

**Integration with existing architecture:**
- Preserves existing security validation patterns
- Maintains template substitution system
- Extends metadata building without breaking changes
- Uses existing FileIoHandler and PathResolver components

**Pattern Selection Rationale:**
- **Hybrid Pre-processing**: Extract undefined flags before dry-cli validation
- **Metadata Integration**: Merge undefined flags into existing metadata hash
- **Security Preservation**: Apply same validation patterns to dynamic flags

### Technology Stack
- **ARGV Pre-processing**: Ruby's ARGV manipulation before dry-cli
- **YAML Integration**: Extend existing YAML metadata serialization
- **Type Detection**: Intelligent type conversion (string/int/float/boolean)
- **Security Framework**: Apply existing path validation and sanitization

**Performance implications:**
- Minimal startup overhead (< 5ms for flag parsing)
- Memory efficient with lazy processing
- No impact on existing command performance

**Security considerations:**
- Validate dynamic flag names against safe patterns
- Apply same sanitization as existing metadata
- Prevent flag name conflicts with future defined options

### Implementation Strategy
1. **ARGV Pre-processing**: Extract undefined flags before dry-cli processes them
2. **Metadata Merging**: Integrate undefined flags into build_metadata_hash
3. **Type Intelligence**: Auto-detect and convert flag values to appropriate types
4. **Backwards Compatibility**: Ensure existing workflows continue unchanged

## Tool Selection

| Criteria | ARGV Pre-parse | Custom Parser | dry-cli Extension | Selected |
|----------|---------------|---------------|-------------------|----------|
| Compatibility | Excellent | Poor | Good | ARGV Pre-parse |
| Security | Excellent | Fair | Good | ARGV Pre-parse |
| Maintenance | Excellent | Poor | Fair | ARGV Pre-parse |
| Performance | Excellent | Good | Good | ARGV Pre-parse |

**Selection Rationale:** ARGV pre-processing maintains full compatibility with existing dry-cli architecture while providing the needed flexibility. It preserves all existing security validations and requires minimal code changes.

### Dependencies
- No new external dependencies required
- Uses existing Ruby standard library (YAML, etc.)
- Leverages existing ATOM components

## File Modifications

### Modify
- `/Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/tools/lib/coding_agent_tools/cli/create_path_command.rb`
  - **Changes**: Add parse_undefined_flags method, extend build_metadata_hash to merge dynamic flags, add type conversion logic
  - **Impact**: Enhanced task creation flexibility, backward compatible
  - **Integration points**: Existing metadata system, template substitution engine

## Risk Assessment

### Technical Risks
- **Risk:** Flag name conflicts with future defined options
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Implement reserved flag name checking, clear error messages for conflicts
  - **Rollback:** Disable dynamic flag parsing via configuration flag

- **Risk:** YAML serialization errors from invalid flag values
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Validate flag values before YAML generation, graceful error handling
  - **Rollback:** Skip invalid flags with warning messages

### Integration Risks
- **Risk:** Backward compatibility issues with existing templates
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Extensive testing with existing task templates, metadata key collision detection
  - **Monitoring:** Monitor task creation success rates after deployment

### Performance Risks
- **Risk:** Command startup time degradation
  - **Mitigation:** Lazy processing, efficient ARGV parsing
  - **Monitoring:** Track command execution times
  - **Thresholds:** < 5ms additional startup time

## Implementation Plan

### Planning Steps

* [x] Research existing metadata key patterns in task templates
  > TEST: Template Analysis Complete
  > Type: Pre-condition Check
  > Assert: All task template metadata keys are catalogued for conflict detection
  > Command: grep -r "^[a-z_-]*:" .ace/handbook/templates/task-management/

* [x] Analyze dry-cli option processing flow to identify integration points
  > TEST: Integration Point Identification
  > Type: Architecture Analysis
  > Assert: ARGV pre-processing integration point identified without breaking dry-cli
  > Command: ruby -c modified_create_path_command.rb

* [x] Design type detection algorithm for intelligent flag value conversion
  > TEST: Type Detection Algorithm
  > Type: Design Validation
  > Assert: Algorithm correctly identifies strings, integers, floats, booleans from flag values
  > Command: ruby type_conversion_test.rb

### Execution Steps

- [x] Implement parse_undefined_flags method to extract dynamic flags from ARGV
  > TEST: Flag Parsing Validation
  > Type: Unit Test
  > Assert: Method correctly extracts undefined flags while preserving defined flags
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/create_path_spec.rb -e "parse_undefined_flags"

- [x] Add intelligent type conversion for flag values (string, int, float, boolean)
  > TEST: Type Conversion Validation
  > Type: Unit Test
  > Assert: Flag values converted to appropriate YAML types based on content analysis
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/create_path_spec.rb -e "type_conversion"

- [x] Extend build_metadata_hash to merge undefined flags with existing metadata
  > TEST: Metadata Integration
  > Type: Integration Test
  > Assert: Dynamic flags properly merged into task YAML metadata without conflicts
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/create_path_spec.rb -e "metadata_merging"

- [x] Implement conflict detection for reserved/defined flag names
  > TEST: Conflict Detection
  > Type: Unit Test
  > Assert: System detects and handles conflicts between dynamic and defined flags
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/create_path_spec.rb -e "conflict_detection"

- [x] Add comprehensive error handling for invalid flag values and YAML issues
  > TEST: Error Handling Validation
  > Type: Integration Test
  > Assert: Invalid flags handled gracefully without breaking task creation
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/create_path_spec.rb -e "error_handling"

- [x] Create comprehensive test cases covering happy path, edge cases, and error conditions
  > TEST: Test Coverage Validation
  > Type: Test Suite
  > Assert: All scenarios covered including type conversion, conflicts, and error conditions
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/create_path_spec.rb && coverage_check

- [x] Validate backward compatibility with existing task-new workflows
  > TEST: Backward Compatibility
  > Type: Regression Test
  > Assert: Existing create-path task-new commands work unchanged
  > Command: test_existing_workflows.rb

- [x] Test dynamic flag handling with real task creation scenarios
  > TEST: End-to-end Validation
  > Type: System Test
  > Assert: Dynamic flags appear correctly in created task YAML frontmatter
  > Command: create-path task-new --title "Test Task" --status draft --priority high --custom-field value && validate_task_metadata.rb

## Acceptance Criteria

- [x] **Dynamic Metadata Creation**: Users can add arbitrary metadata to tasks via undefined command-line flags without modifying the create-path command definition
- [x] **Workflow Integration**: AI workflows and automation scripts can pass context-specific task attributes dynamically during task creation
- [x] **YAML Compatibility**: All undefined flags are properly serialized as valid YAML metadata that integrates with existing task management workflows
- [x] **Type Intelligence**: Flag values are automatically converted to appropriate YAML types (string, integer, float, boolean) based on content analysis
- [x] **Error Resilience**: Invalid or problematic flags are handled gracefully without breaking task creation
- [x] **Backward Compatibility**: Existing create-path task-new commands continue to work without modification

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

- Enhanced idea: .ace/taskflow/backlog/ideas/20250731-0800-flag-attribute-yaml.md
- Existing create-path command documentation in docs/tools.md
- YAML frontmatter examples in .ace/taskflow/current/v.0.4.0-replanning/tasks/
- Task template structure at .ace/handbook/templates/task-management/task.draft.template.md