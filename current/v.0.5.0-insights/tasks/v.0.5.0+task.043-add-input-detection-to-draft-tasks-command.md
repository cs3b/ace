---
id: v.0.5.0+task.043
status: done
priority: medium
estimate: 3h
dependencies: []
---

# Add Input Detection to Draft-Tasks Command

## Behavioral Specification

### User Experience
- **Input**: Users execute `/draft-tasks` with various file types (idea files or completed task files)
- **Process**: System intelligently detects input file type and adapts workflow accordingly - creating new tasks from ideas or registering existing completed tasks
- **Output**: Appropriate processing based on input type with clear feedback about detected file type and actions taken

### Expected Behavior
When users run `/draft-tasks` with different input file types, the system should:
1. Analyze provided files to determine if they are idea files or completed task specifications
2. For idea files: Execute existing workflow (transform ideas → create draft tasks via `task-manager create`)
3. For completed task files: Execute registration workflow (register tasks with `task-manager create` and preserve content)
4. Provide clear user feedback about detected file types and processing approach
5. Handle mixed input (both types) appropriately with clear status reporting

### Interface Contract
```bash
# CLI Interface - Idea file processing (existing behavior)
/draft-tasks dev-taskflow/backlog/ideas/feature-concept.md
# Expected output:
# "Detected: 1 idea file"
# "Creating draft tasks from ideas..."
# "Created: v.0.5.0+task.XXX - Feature Concept"

# CLI Interface - Completed task file processing (new behavior)
/draft-tasks dev-taskflow/backlog/tasks/completed-task-spec.md
# Expected output:
# "Detected: 1 completed task file"
# "Registering existing tasks..."
# "Registered: v.0.5.0+task.XXX - Completed Task Spec"

# Mixed input handling
/draft-tasks idea1.md completed-task1.md idea2.md
# Expected output:
# "Detected: 2 idea files, 1 completed task file"
# "Processing ideas: idea1.md, idea2.md"
# "Registering tasks: completed-task1.md"
# "Results: 3 tasks processed (2 created, 1 registered)"
```

**Error Handling:**
- Unrecognizable file types: Clear error message with file classification failure details
- Processing failures: Specific error for each file with recovery suggestions
- Mixed failures: Partial success reporting with clear status for each file

**Edge Cases:**
- Empty files: Should be detected and handled with appropriate error message
- Malformed files: Clear distinction between format errors and content issues
- Files that don't fit either category: Guidance on expected input format

### Success Criteria
- [x] **Intelligent Detection**: System correctly identifies idea files vs completed task files
- [x] **Workflow Adaptation**: Appropriate processing workflow selected based on detected file type
- [x] **User Clarity**: Clear feedback about file types detected and processing approach taken
- [x] **Content Preservation**: Completed task files maintain their full content when registered

### Validation Questions
- [x] **Detection Criteria**: What specific characteristics reliably distinguish idea files from completed tasks?
- [x] **Error Recovery**: How should the system handle files that don't clearly fit either category?
- [x] **User Feedback**: What level of detail should be provided about detection and processing decisions?
- [x] **Backwards Compatibility**: Will changes affect existing workflows that depend on current behavior?

## Objective

Enhance the `/draft-tasks` command to be more versatile and user-friendly by intelligently handling different input file types, reducing user confusion and eliminating the need for manual workarounds when processing completed task files.

## Scope of Work

### User Experience Scope
- File type detection and classification workflow
- Adaptive processing based on detected input types
- User feedback and status reporting for processing decisions
- Error handling for unrecognizable or problematic files

### System Behavior Scope
- Input analysis logic for distinguishing file types
- Dual workflow execution (idea processing vs task registration)
- Content preservation for completed task files
- Integration with existing `task-manager create` functionality

### Interface Scope
- `/draft-tasks` command enhanced functionality
- File path processing and validation
- Status reporting and user feedback mechanisms
- Error messaging for various failure scenarios

### Deliverables

#### Behavioral Specifications
- User experience flow definitions for file type detection
- System behavior specifications for adaptive workflow selection
- Interface contract definitions for enhanced command functionality

#### Validation Artifacts
- Success criteria validation methods for file type detection
- User acceptance criteria for workflow adaptation
- Behavioral test scenarios for various input file combinations

## Phases

1. Audit
2. Extract …
3. Refactor …

## Technical Approach

### Architecture Pattern
- [x] **Command Enhancement Pattern**: Enhance existing `/draft-tasks` Claude command with input detection layer
- [x] **Workflow Preservation**: Maintain existing `draft-task.wf.md` workflow for idea processing
- [x] **Additive Design**: Add new capabilities without breaking existing functionality
- [x] **Minimal Impact**: Changes limited to command interface layer, no core system modifications

### Technology Stack
- [x] **No New Dependencies**: Implementation uses existing Claude command system and workflow patterns
- [x] **File Analysis**: Uses file content inspection (YAML frontmatter vs LLM metadata headers)
- [x] **Workflow Integration**: Leverages existing `task-manager create` and workflow infrastructure
- [x] **Backwards Compatible**: All existing command usage patterns continue to work

### Implementation Strategy
- [x] **File Type Detection**: Parse file headers to distinguish idea files from completed task files
- [x] **Dual Workflow Routing**: Route to appropriate processing based on detected type
- [x] **User Feedback**: Provide clear reporting about file types and actions taken
- [x] **Error Handling**: Graceful handling of unrecognizable files with user guidance

## Tool Selection

| Criteria | File Header Analysis | External Detection Tool | Filename Patterns | Selected |
|----------|---------------------|------------------------|-------------------|----------|
| Performance | Excellent | Fair | Good | File Header Analysis |
| Integration | Excellent | Poor | Good | File Header Analysis |
| Maintenance | Good | Fair | Excellent | File Header Analysis |
| Security | Excellent | Unknown | Good | File Header Analysis |
| Learning Curve | Low | High | Low | File Header Analysis |

**Selection Rationale:** File header analysis is the most reliable method for distinguishing between idea files (LLM metadata headers) and completed task files (YAML frontmatter). It integrates seamlessly with existing Claude command patterns and requires no external dependencies.

### Dependencies
- [x] **No New Dependencies Required**: Implementation uses existing Claude command system
- [x] **File System Access**: Standard file reading capabilities already available
- [x] **Compatibility Verified**: Changes are additive to existing workflow system

## File Modifications

### Create
- No new files required for this implementation

### Modify
- `.claude/commands/draft-tasks.md`
  - Changes: Add file type detection logic and dual workflow routing
  - Impact: Enhanced command functionality without breaking existing behavior
  - Integration points: Continues to use existing `draft-task.wf.md` workflow and `task-manager create`

### Delete
- No file deletions required

## Implementation Plan

<!-- This section details the specific steps required to implement the behavioral requirements -->
<!-- Clear distinction between planning/analysis activities and concrete implementation work -->

### Planning Steps
<!-- Research, analysis, and design activities that clarify the technical approach -->
<!-- Use asterisk markers (* [ ]) for activities that don't change system state -->
<!-- Focus on understanding, designing, and preparing for implementation -->

- [x] **System Analysis**: Current `/draft-tasks` command and `draft-task.wf.md` workflow analyzed
  > TEST: Understanding Check
  > Type: Pre-condition Check  
  > Assert: Command processes idea files via `task-manager create`, needs dual workflow capability
  > Command: # Manual verification - Current system understanding complete
- [x] **File Type Detection Design**: File header analysis approach selected (YAML vs LLM metadata)
  > TEST: Design Validation
  > Type: Design Review
  > Assert: Detection method reliable for distinguishing file types
  > Command: # Manual validation - Detection criteria clearly defined
- [x] **Implementation Strategy**: Additive enhancement to existing command without breaking changes
- [x] **Dependency Analysis**: No new dependencies required, uses existing Claude command system
- [x] **Risk Assessment**: Low-risk additive changes with straightforward rollback strategy

### Execution Steps  
<!-- Concrete implementation actions that modify code, create files, or change system state -->
<!-- Use hyphen markers (- [ ]) for actions that result in tangible system changes -->
<!-- Each step should be verifiable and move toward behavioral requirement fulfillment -->

- [x] **Add File Type Detection Logic**: Enhance `.claude/commands/draft-tasks.md` with file analysis capability
  > TEST: Detection Logic Verification
  > Type: Functional Validation
  > Assert: Command correctly identifies idea files vs completed task files
  > Command: # Manual test with sample files of each type
- [x] **Implement Dual Workflow Routing**: Add conditional logic to route to appropriate processing workflow
  > TEST: Workflow Routing Check
  > Type: Integration Test
  > Assert: Idea files → draft-task workflow, completed tasks → registration workflow
  > Command: # Test with mixed input files
- [x] **Add User Feedback Reporting**: Implement clear status reporting for file types and actions
  > TEST: User Feedback Validation
  > Type: Interface Contract Test
  > Assert: Users receive clear feedback about detected types and processing actions
  > Command: # Verify output messages match behavioral specification
- [x] **Implement Error Handling**: Add handling for unrecognizable files and processing failures
  > TEST: Error Scenario Testing
  > Type: Edge Case Validation
  > Assert: Graceful handling of edge cases with appropriate user guidance
  > Command: # Test with malformed, empty, and ambiguous files
- [x] **Validate Integration**: Test enhanced command with existing workflow infrastructure
  > TEST: System Integration Check
  > Type: End-to-End Validation
  > Assert: Enhanced command integrates properly with `task-manager create` and workflows
  > Command: # Full end-to-end test with real task creation and file processing

## Risk Assessment

### Technical Risks
- **Risk:** File Type Detection Inaccuracy
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Conservative detection logic with clear error reporting for ambiguous files
  - **Rollback:** Revert to original command behavior by removing detection logic

- **Risk:** Breaking Existing Workflows
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Preserve existing workflow paths completely, only add new detection layer
  - **Rollback:** Simple file reversion as changes are additive

### Integration Risks
- **Risk:** User Confusion About New Adaptive Behavior
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Comprehensive user feedback and clear documentation of new behavior
  - **Monitoring:** Monitor for user questions about command behavior changes

### Performance Risks
- **Risk:** Slight performance impact from file header analysis
  - **Mitigation:** Efficient file header parsing, minimal overhead
  - **Monitoring:** User-reported performance issues
  - **Thresholds:** No noticeable delay in command execution

## Acceptance Criteria

<!-- Define conditions that signify successful implementation of behavioral requirements -->
<!-- These should directly map to success criteria from the behavioral specification -->
<!-- Focus on verifying that behavioral requirements are met, not just implementation completed -->

### Behavioral Requirement Fulfillment
- [x] **User Experience Delivery**: All user experience requirements from behavioral spec are implemented and working
- [x] **Interface Contract Compliance**: All interface contracts function exactly as specified in behavioral requirements  
- [x] **System Behavior Validation**: System demonstrates all expected behaviors defined in behavioral specification

### Implementation Quality Assurance  
- [x] **Code Quality**: All code meets project standards and passes quality checks
- [x] **Test Coverage**: All embedded tests in Implementation Plan pass successfully
- [x] **Integration Verification**: Implementation integrates properly with existing system components
- [x] **Performance Requirements**: System meets any performance criteria specified in behavioral requirements

### Documentation and Validation
- [x] **Behavioral Validation**: Success criteria from behavioral specification are demonstrably met
- [x] **Error Handling**: All error conditions and edge cases handle as specified
- [x] **Documentation Updates**: Any necessary documentation reflects the implemented behavior

## Out of Scope

- ❌ **Implementation Details**: File parsing algorithms, detection heuristic specifics
- ❌ **Technology Decisions**: File processing library choices, workflow engine decisions
- ❌ **Advanced Features**: Machine learning-based classification or complex file analysis
- ❌ **UI Enhancements**: Graphical interfaces or advanced progress reporting

## References

- Original idea file: dev-taskflow/current/v.0.5.0-insights/docs/ideas/043-20250812-0033-draft-tasks-input-error.md
- Task management workflow patterns
- Existing `/draft-tasks` command implementation