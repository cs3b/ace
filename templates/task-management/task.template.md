---
id: {id}
status: pending
priority: {priority}
estimate: {estimate}
dependencies: {dependencies}
---

# {title}

## What: Behavioral Specification

<!-- Start with the WHAT - what needs to be accomplished from a user/system perspective -->

### Expected Behavior

<!-- Describe what the system should do from the user's perspective -->
<!-- Include user experience, system responses, and observable outcomes -->
<!-- Focus on behavior, not implementation details -->

### Interface Contract

<!-- Define the external interfaces, APIs, or interaction points -->
<!-- Specify inputs, outputs, and expected responses -->
<!-- Include error handling and edge case behaviors -->

### Success Criteria

<!-- Define measurable criteria that indicate successful completion -->
<!-- Use checkboxes for clear validation points -->
<!-- Focus on behavioral outcomes, not implementation artifacts -->

- [ ] Success criterion 1: Observable behavior or outcome
- [ ] Success criterion 2: Measurable result or capability
- [ ] Success criterion 3: User experience or system performance goal

## How: Implementation Plan

<!-- Implementation details come after behavioral specification is clear -->

### Planning Steps

<!-- Research, analysis, and design activities that clarify the approach -->
<!-- Use asterisk markers for planning activities -->

- [ ] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: bin/test --check-analysis-complete
- [ ] Research best practices and design approach
- [ ] Plan detailed implementation strategy with specific steps

### Execution Steps

<!-- Concrete implementation actions that modify code, create files, or change system state -->
<!-- Use hyphen markers for implementation actions -->

- [ ] Step 1: Create or modify specific system component
  > TEST: Component Creation
  > Type: Action Validation
  > Assert: Component exists and has expected structure
  > Command: bin/test --verify-component path/to/component
- [ ] Step 2: Implement core functionality
- [ ] Step 3: Add error handling and edge cases
- [ ] Step 4: Integrate with existing system components

### Technical Implementation Details

<!-- Technical approach and architecture decisions -->

#### Architecture Pattern
- [ ] Pattern selection and rationale
- [ ] Integration with existing architecture
- [ ] Impact on system design

#### Technology Stack
- [ ] Libraries/frameworks needed
- [ ] Version compatibility checks
- [ ] Performance implications
- [ ] Security considerations

#### Implementation Strategy
- [ ] Rollback considerations
- [ ] Testing strategy
- [ ] Performance monitoring

### File Modifications

#### Create
- path/to/new/file.ext
  - Purpose: [why this file]
  - Key components: [what it contains]
  - Dependencies: [what it depends on]

#### Modify
- path/to/existing/file.ext
  - Changes: [what to modify]
  - Impact: [effects on system]
  - Integration points: [how it connects]

#### Delete
- path/to/obsolete/file.ext
  - Reason: [why removing]
  - Dependencies: [what depends on this]
  - Migration strategy: [how to handle removal]

### Tool Selection

| Criteria | Option A | Option B | Option C | Selected |
|----------|----------|----------|----------|----------|
| Performance | | | | |
| Integration | | | | |
| Maintenance | | | | |
| Security | | | | |
| Learning Curve | | | | |

**Selection Rationale:** [Explain selection reasoning]

#### Dependencies
- [ ] New dependency 1: version and reason
- [ ] New dependency 2: version and reason
- [ ] Compatibility verification completed

## Validation and Quality Assurance

### Risk Assessment

#### Technical Risks
- **Risk:** [Description]
  - **Probability:** High/Medium/Low
  - **Impact:** High/Medium/Low
  - **Mitigation:** [Strategy]
  - **Rollback:** [Procedure]

#### Integration Risks
- **Risk:** [Description]
  - **Probability:** High/Medium/Low
  - **Impact:** High/Medium/Low
  - **Mitigation:** [Strategy]
  - **Monitoring:** [How to detect]

#### Performance Risks
- **Risk:** [Description]
  - **Mitigation:** [Strategy]
  - **Monitoring:** [Metrics to track]
  - **Thresholds:** [Acceptable limits]

## Scope and Context

### Scope of Work

<!-- High-level scope after behavioral specification is defined -->

- Bullet 1: [behavioral scope item]
- Bullet 2: [implementation scope item]

### Deliverables

#### Create
- path/to/file.ext

#### Modify
- path/to/other.ext

#### Delete
- path/to/obsolete.ext

### Out of Scope

- ❌ Items explicitly not included in this task
- ❌ Future enhancements or related features

## Guidance Comments

<!-- 
TEMPLATE USAGE GUIDANCE:

1. START WITH WHAT: Always begin by filling out the "What: Behavioral Specification" section
   - Expected Behavior: Focus on user experience and observable outcomes
   - Interface Contract: Define APIs, inputs, outputs, error conditions
   - Success Criteria: Measurable, testable conditions for completion

2. THEN PLAN HOW: Move to "How: Implementation Plan" only after behavior is clear
   - Planning Steps: Research, analysis, design work (use * [ ] markers)
   - Execution Steps: Concrete implementation actions (use - [ ] markers)
   - Technical Details: Architecture, tools, files (supporting information)

3. INCREMENTAL USAGE: You can create tasks with only the What section filled out initially
   - Draft State: Complete behavioral specification, leave implementation sections as placeholders
   - Planning State: Add Planning Steps and high-level approach
   - Implementation State: Complete all Execution Steps and technical details

4. EXAMPLES AND PATTERNS:
   - See task examples in dev-taskflow/current/ for completed templates
   - Focus on behavior-first thinking: what the user/system experiences
   - Defer technical decisions until behavioral requirements are clear

5. VALIDATION CHECKLIST:
   - [ ] Expected Behavior is written from user/system perspective
   - [ ] Interface Contract specifies clear inputs/outputs
   - [ ] Success Criteria are measurable and behavioral
   - [ ] Implementation sections support the behavioral specification
   - [ ] Template promotes behavior-first thinking
-->

## References

<!-- Links to related documentation, examples, or specifications -->