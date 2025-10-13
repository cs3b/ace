---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2025-10-08'
---

# Plan Task Workflow Instruction

## Goal

Create a detailed implementation plan for a task that already has a validated behavioral specification. Focus exclusively on the HOW (technical implementation approach) rather than the WHAT (behavioral requirements). Transform a draft task into a pending task with complete technical implementation details.

## Prerequisites

- Task file exists with **draft** status and validated behavioral specification
- Task must have clear behavioral requirements from draft-task workflow
- Understanding of project context and architecture
- Access to recent git history and project status
- load project context

## Project Context Loading

- Read and follow: `ace-nav wfi://load-project-context`

## Task Type Considerations

**Code Implementation Tasks** (Full workflow applies including test planning):
- New features with business logic
- API endpoints and services
- Data processing and transformation
- Authentication and authorization systems
- Integration with external services

**Documentation/Workflow Tasks** (Skip test planning steps):
- Creating or updating documentation
- Workflow instruction development
- Guide and template creation
- Process documentation
- Configuration documentation

**Mixed Tasks** (Apply test planning selectively):
- Configuration with validation logic
- CLI tools with complex functionality
- Templates with embedded logic
- Build and deployment scripts


## Process Steps

1. **Load and Validate Draft Task:**
   - **Task Selection:**
     - If specific task provided: Use the provided task path
     - If no task specified: Run `ace-taskflow tasks --status draft` to get draft tasks
     - Document the selected task path for reference
   - **Load Task Content:**
     - Read the task file from the identified path
     - Verify task has `status: draft`
     - Parse the structure and extract:
       - Behavioral specification (User Experience, Interface Contract, Success Criteria)
       - Existing scope and deliverables
       - Any existing implementation notes

2. **Technical Research Phase:**

   **Architecture Pattern Analysis:**
   - Review existing project patterns and identify best fit
   - Analyze how this feature integrates with current architecture
   - Document architectural decisions and rationale

   **Technology Stack Research:**
   - Research available libraries, frameworks, and tools
   - Evaluate performance implications and compatibility
   - Consider version requirements and dependencies

   **Implementation Approach Investigation:**
   - Research industry best practices for this type of feature
   - Analyze similar implementations in the codebase
   - Identify proven patterns and anti-patterns

   **Naming Consistency Analysis:**
   - For rename/refactoring tasks, analyze comprehensive scope:
     - Search for all files and directories containing the old name
     - Identify library structure patterns that need renaming
     - Check test file naming conventions and related test assets
     - Review module and class naming throughout the codebase
   - Document the full renaming scope to prevent partial migrations

   **Document Research Findings:**
   - Summarize key technical insights
   - Note recommended approaches with pros/cons
   - Identify potential technical risks and mitigation strategies

3. **Tool Selection:**

   **Evaluation Criteria:**
   - Performance requirements alignment
   - Integration with existing stack
   - Maintenance and support considerations
   - Learning curve and team expertise

   **Selection Matrix:**
   - Create comparison matrix for major decisions
   - Document selection rationale
   - Note any trade-offs or compromises

   **Dependency Analysis:**
   - List all new dependencies required
   - Verify compatibility with existing dependencies
   - Document any potential conflicts or risks

4. **File Modification Planning:**

   **Create Files:**
   - List all new files to be created with purpose and key components
   - Define file structure and organization
   - Plan directory structure if needed

   **Modify Files:**
   - Identify existing files requiring changes
   - Document specific modifications and their impact
   - Plan integration points and interfaces

   **Delete Files:**
   - Identify obsolete files to be removed
   - Document reasons for removal
   - Check dependencies before deletion

   **Naming Consistency Analysis:**
   - When renaming commands, tools, or components, identify ALL related items:
     - Executable/command files
     - Library directory structures (e.g., `lib/.../old_name/` → `lib/.../new_name/`)
     - Test file patterns (e.g., `old_name_spec.rb` → `new_name_spec.rb`)
     - Test fixture/cassette directories
     - Module and class names in code
     - Import/require statements throughout codebase
     - Documentation references in markdown files
     - Configuration file references
   - Use systematic search commands:
     ```bash
     # Find all directories and files with the old name
     ace-search "*old_name*" --file | grep -v ".git"

     # Find all code references
     ace-search "old_name" --content --glob "**/*.{rb,py,js,md}"
     ```
   - Document the complete renaming scope to avoid partial migrations

5. **Test Case Planning:** *(For code implementation tasks only)*

   **Note:** This step applies when the task involves code implementation (new features, APIs, business logic, etc.). Skip for documentation, workflow, or configuration-only tasks.

   **Analyze Testing Requirements:**
   - Review behavioral specification for testable components
   - Identify input validation rules, business logic flows, output expectations
   - Determine error scenarios and integration points
   - Consider performance and security requirements

   **Scenario Identification:**

   **Happy Path Scenarios:**
   - Standard expected usage patterns
   - Primary user workflows and interactions
   - Common configuration and data combinations
   - Successful operation outcomes

   **Edge Case Scenarios:**
   - Boundary values (minimum/maximum limits)
   - Empty, null, or missing inputs
   - Special characters and unusual data formats
   - Large datasets or high-volume operations
   - Concurrent or simultaneous operations

   **Error Condition Scenarios:**
   - Invalid input validation failures
   - Missing required data or parameters
   - External service failures or unavailability
   - Network timeouts and connectivity issues
   - Permission denials and authorization failures

   **Integration Point Scenarios:**
   - External API interactions and responses
   - Database operations and transactions
   - File system access and manipulation
   - Message queue and event handling
   - Third-party service integrations

   **Test Type Categorization:**

   **Unit Tests** (High Priority):
   - Individual functions and methods in isolation
   - Pure business logic validation
   - Input/output transformation correctness
   - Mock external dependencies

   **Integration Tests** (Medium Priority):
   - Component interaction and communication
   - API endpoint request/response cycles
   - Database integration and data persistence
   - Service layer coordination

   **End-to-End Tests** (Context Dependent):
   - Complete user journey validation
   - Multi-step process workflows
   - Cross-system integration flows
   - UI interaction testing (if applicable)

   **Performance Tests** (If Applicable):
   - Response time benchmarks and limits
   - Throughput capacity and scalability
   - Resource usage monitoring
   - Concurrent user load handling

   **Security Tests** (If Applicable):
   - Authentication and authorization validation
   - Input sanitization and injection prevention
   - Data exposure and privacy protection
   - Access control verification

   **Test Planning Documentation:**
   - Create high-level test case matrix for edge cases
   - Document test data requirements and prerequisites
   - Plan test environment setup and configuration needs
   - Identify test framework and tooling requirements
   - Define test coverage expectations and success criteria

   **Note:** For complex features requiring comprehensive test coverage, consider creating detailed test cases using the `create-test-cases.wf.md` workflow and `test-case.template.md` template.

   **Test Prioritization:**
   - **High Priority:** Core business logic, security-critical features, user-facing functionality
   - **Medium Priority:** Secondary features, admin functions, performance optimizations
   - **Low Priority:** Nice-to-have features, rare edge cases, internal utilities

6. **Implementation Steps Planning:**

   **Detailed Step Breakdown:**
   - Create specific, actionable implementation steps
   - Order steps logically with dependencies
   - Include validation and testing at each step
   - Integrate test implementation alongside code implementation

   **Test Implementation Integration:**
   - Plan test implementation concurrent with code development
   - Include test creation steps in execution plan
   - Design test validation for each major implementation milestone
   - Plan test data setup and teardown procedures

   **Embedded Test Planning:**
   - Design test blocks for critical operations using planned test scenarios
   - Plan verification commands for each step based on test case analysis
   - Include test execution validation at key implementation points
   - Include rollback verification where needed
   - Reference high-level test scenarios from Test Case Planning step

7. **Risk Analysis and Rollback Planning:**

   **Technical Risks:**
   - Identify potential failure points
   - Plan mitigation strategies
   - Document fallback approaches

   **Rollback Strategy:**
   - Define rollback steps for each implementation phase
   - Plan data preservation and recovery
   - Document emergency procedures

   **Performance Impact:**
   - Analyze potential performance implications
   - Plan performance monitoring and validation
   - Define acceptable performance thresholds

8. **Implementation Plan Assembly:**

   **Planning Steps Section:**
   - Research and analysis activities (use `* [ ]`)
   - Technical investigation tasks
   - Design and architecture decisions

   **Execution Steps Section:**
   - Concrete implementation actions (use `- [ ]`)
   - File creation and modification tasks
   - Testing and validation steps

   **Embedded Tests:**
   - Add test blocks for critical operations:
     ```markdown
     - [ ] Implementation step
       > TEST: Action Validation
       > Type: Action Validation
       > Assert: Expected outcome
       > Command: # Run project-specific test command --verify-result
     ```

9. **UX/Usage Documentation Creation:**

   **Purpose:** Create practical usage documentation to validate the implementation approach and provide clear examples for users. This helps ensure the plan is heading in the right direction before finalizing.

   **When to Create:**
   - **User-facing features**: Commands, CLI tools, APIs, workflows
   - **Developer tools**: Build systems, test frameworks, development utilities
   - **Skip for**: Internal refactoring, technical debt, infrastructure tasks

   **Create ux/usage.md in task directory:**
   - Path: `<task-directory>/ux/usage.md`
   - Example: `.ace-taskflow/v.0.9.0/t/046-batch-operations/ux/usage.md`

   **Document Structure:**

   **Overview Section:**
   - Brief description of what the feature does
   - List of available commands/features
   - Key benefits or use cases

   **Command Types** (if applicable):
   - Distinguish between command execution contexts
   - Example: Claude Code commands vs bash CLI commands
   - Show syntax differences clearly

   **Command Structure:**
   - Basic invocation patterns
   - Argument formats
   - Option/flag usage
   - Default behaviors

   **Usage Scenarios** (3-6 real-world examples):
   - **Scenario 1**: Common/typical use case
     - Goal statement
     - Step-by-step commands
     - Expected output
   - **Scenario 2**: Alternative workflow
   - **Scenario 3**: Edge case handling
   - **Scenario 4**: Complex/advanced usage
   - Include both successful and error cases

   **Command Reference:**
   - Detailed syntax for each command
   - Parameter descriptions
   - Input/output formats
   - Internal implementation notes (what tools/commands it uses)

   **Tips and Best Practices:**
   - Common pitfalls to avoid
   - Recommended workflows
   - Performance considerations
   - Troubleshooting guidance

   **Migration Notes** (if replacing existing feature):
   - Legacy vs new command comparison
   - Key differences
   - Transition guidance

   **Review Criteria:**
   - [ ] Examples use actual command syntax (verified against implementation)
   - [ ] Scenarios cover common and edge cases
   - [ ] Command types clearly distinguished
   - [ ] Output examples realistic and helpful
   - [ ] Troubleshooting addresses likely issues
   - [ ] Migration path clear if applicable

10. **Task Status Promotion:**
   - Update task metadata:
     - Change `status: draft` to `status: pending`
     - Verify priority and estimate are appropriate
     - Update dependencies if needed
   - Add implementation plan sections
   - Ensure acceptance criteria align with implementation approach

## Implementation Planning Templates

The following templates should be used when creating implementation plans:

### Technical Approach Template

```markdown
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
```

### Tool Selection Matrix

```markdown
## Tool Selection

| Criteria | Option A | Option B | Option C | Selected |
|----------|----------|----------|----------|----------|
| Performance | Good | Excellent | Fair | Option B |
| Integration | Excellent | Good | Poor | Option B |
| Maintenance | Good | Excellent | Fair | Option B |

**Selection Rationale:** [Explain why Option B was chosen]
```

### File Modification Template

```markdown
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

### Rename (for comprehensive migrations)
- old/path/name.ext → new/path/name.ext
  - Type: [file/directory/both]
  - Related renames:
    - Library directories: `lib/old_name/` → `lib/new_name/`
    - Test files: `*old_name*.rb` → `*new_name*.rb`
    - Module/class names: `OldName` → `NewName`
  - Import updates: [number of files with require/import statements]
  - Documentation updates: [number of markdown files with references]
```

### Risk Assessment Template

```markdown
## Risk Assessment

### Technical Risks
- **Risk:** [Description]
  - **Probability:** High/Medium/Low
  - **Impact:** High/Medium/Low
  - **Mitigation:** [Strategy]
  - **Rollback:** [Procedure]

### Integration Risks
- **Risk:** [Description]
  - **Mitigation:** [Strategy]
  - **Monitoring:** [How to detect]
```

## Content Transformation Guidelines

When transforming from review-task to plan-task focus:

**Remove (WHAT concerns):**
- Behavioral specification validation
- User experience requirements analysis
- Interface contract definition
- Success criteria validation
- Requirements clarification

**Keep and Enhance (HOW concerns):**
- Technical approach analysis
- Implementation strategy
- Tool and library selection
- File modification planning
- Risk assessment and mitigation

**Add (Implementation Planning):**
- Detailed technical research
- Architecture integration analysis
- Step-by-step implementation plan
- Embedded test validation
- Rollback and recovery procedures

## Output / Success Criteria

- Task status changed from `draft` to `pending`
- Complete technical implementation plan with specific steps
- All tools and libraries selected with rationale
- File modification plan with detailed impact analysis
- Risk assessment with mitigation strategies
- Embedded tests for critical operations
- Clear integration with existing architecture
- Rollback procedures documented
- UX/usage documentation created for user-facing features (when applicable)

## Common Patterns

### New Feature Implementation
- Start with architecture integration analysis
- Focus on data flow and state management
- Plan comprehensive testing strategy
- Consider performance implications early

### Refactoring Implementation
- Document current state thoroughly
- Plan incremental transformation steps
- Emphasize backward compatibility
- Create extensive rollback procedures

### Integration Implementation
- Focus on interface compatibility
- Plan configuration management
- Emphasize error handling and recovery
- Document external dependencies

### User-Facing Features
- Create comprehensive usage scenarios early
- Validate command syntax before finalizing
- Include both success and error examples
- Document migration path from legacy features

## Usage Example

**Input:** Draft task with behavioral specification
> "Plan implementation for task .ace-taskflow/$(ace-taskflow release --path)/v.0.5.0/tasks/v.0.5.0+task.1-realtime-collaboration.md (status: draft)"

**Process:** Technical research, tool selection, implementation planning

**Output:** Task with complete implementation plan and status: pending

---

This workflow transforms draft tasks with validated behavioral specifications into fully planned, implementation-ready tasks with detailed technical approaches.

<documents>
    <template path="tmpl://task-management/task.pending">---
id: <generated automatically by ace-taskflow>
status: pending
priority: <high/medium/low>
estimate: <n>h
dependencies: [<ticket-ids>]
---

# <Verb + Object>

## 0. Directory Audit ✅

_Command run:_

```bash
ace-nav guide://
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Why are we doing this?

## Scope of Work

- Bullet 1 …
- Bullet 2 …

### Deliverables

#### Create

- path/to/file.ext

#### Modify

- path/to/other.ext

#### Delete

- path/to/obsolete.ext

## Phases

1. Audit
2. Extract …
3. Refactor …

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: # Run project-specific test command --check-analysis-complete
- [ ] Research best practices and design approach
- [ ] Plan detailed implementation strategy

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Step 1: Describe the first implementation action.
- [ ] Step 2: Describe the second action, which produces a verifiable outcome.
  > TEST: Verify Action 2 Outcome
  > Type: Action Validation
  > Assert: The outcome of Step 2 (e.g., file created, content updated) is as expected.
  > Command: # Run project-specific test command --check-something path/to/relevant_artifact_from_step_2
- [ ] ... Add more implementation steps as needed.

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: All specified deliverables created/modified.
- [ ] AC 2: Key functionalities (if applicable) are working as described.
- [ ] AC 3: All automated checks in the Implementation Plan pass.

## Out of Scope

- ❌ …

## References

```
</template>

    <template path="tmpl://task-management/task.technical-approach">## Technical Approach

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
</template>

    <template path="tmpl://task-management/task.tool-selection-matrix">## Tool Selection

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
</template>

    <template path="tmpl://task-management/task.file-modification-checklist">## File Modifications

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

### Rename (for comprehensive migrations)
- old/path/name.ext → new/path/name.ext
  - Type: [file/directory/both]
  - Related renames:
    - Library directories: `lib/old_name/` → `lib/new_name/`
    - Test files: `*old_name*.rb` → `*new_name*.rb`
    - Module/class names: `OldName` → `NewName`
  - Import updates: [number of files with require/import statements]
  - Documentation updates: [number of markdown files with references]
</template>

    <template path="tmpl://task-management/task.risk-assessment">## Risk Assessment

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
</template>

</documents>
