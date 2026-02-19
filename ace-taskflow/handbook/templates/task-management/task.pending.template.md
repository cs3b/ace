---
id: {id}
status: pending
priority: {priority}
estimate: {estimate}
dependencies: {dependencies}
---

# {title}

## Behavioral Context
<!-- Reference the completed behavioral specification from the draft phase -->
<!-- This section assumes behavioral requirements are already defined -->

**Behavioral Specification Reference**: [Link to completed draft task or behavioral requirements]

**Key Behavioral Requirements**:
- [Summary of key user experience requirements]
- [Summary of key system behavior requirements]  
- [Summary of key interface contract requirements]

## Objective

Why are we implementing this? Focus on technical objectives that support the defined behavioral requirements.

## Scope of Work

- Bullet 1 …
- Bullet 2 …

### Deliverables

#### Create

- path/to/file.ext
- {task-folder}/codemods/migration-name (if task includes data migration or batch transformations)

#### Modify

- path/to/other.ext

#### Delete

- path/to/obsolete.ext

## Phases

1. Audit
2. Extract …
3. Refactor …

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
<!-- Research, analysis, and design activities that clarify the technical approach -->
<!-- Use asterisk markers (* [ ]) for activities that don't change system state -->
<!-- Focus on understanding, designing, and preparing for implementation -->

- [ ] **System Analysis**: Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check  
  > Assert: Key components, interfaces, and integration points are identified
  > Command: bin/test --check-analysis-complete
- [ ] **Architecture Design**: Research best practices and design technical approach
  > TEST: Design Validation
  > Type: Design Review
  > Assert: Architecture decisions align with behavioral requirements
  > Command: bin/test --validate-design-approach
- [ ] **Implementation Strategy**: Plan detailed step-by-step implementation approach
- [ ] **Dependency Analysis**: Identify and validate all required dependencies
- [ ] **Risk Assessment**: Analyze technical risks and define mitigation strategies

### Execution Steps  
<!-- Concrete implementation actions that modify code, create files, or change system state -->
<!-- Use hyphen markers (- [ ]) for actions that result in tangible system changes -->
<!-- Each step should be verifiable and move toward behavioral requirement fulfillment -->

- [ ] **Foundation Setup**: [Create base structure/components needed for implementation]
  > TEST: Foundation Verification
  > Type: Structural Validation
  > Assert: Base components exist and have expected structure
  > Command: bin/test --verify-foundation path/to/base/components
- [ ] **Core Implementation**: [Implement primary functionality that delivers core behavior]
  > TEST: Core Functionality Check
  > Type: Functional Validation
  > Assert: Core behavior works as specified in behavioral requirements
  > Command: bin/test --verify-core-behavior
- [ ] **Interface Integration**: [Implement interfaces defined in behavioral specification]
  > TEST: Interface Contract Validation
  > Type: Integration Test
  > Assert: All interface contracts work as specified
  > Command: bin/test --verify-interfaces
- [ ] **Error Handling**: [Implement error conditions and edge cases from behavioral spec]
  > TEST: Error Scenario Testing
  > Type: Edge Case Validation
  > Assert: Error handling matches behavioral specification
  > Command: bin/test --verify-error-handling
- [ ] **Integration Validation**: [Ensure integration with existing system components]
  > TEST: System Integration Check
  > Type: End-to-End Validation
  > Assert: Implementation integrates properly with existing system
  > Command: bin/test --verify-integration

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

<!-- Define conditions that signify successful implementation of behavioral requirements -->
<!-- These should directly map to success criteria from the behavioral specification -->
<!-- Focus on verifying that behavioral requirements are met, not just implementation completed -->

### Behavioral Requirement Fulfillment
- [ ] **User Experience Delivery**: All user experience requirements from behavioral spec are implemented and working
- [ ] **Interface Contract Compliance**: All interface contracts function exactly as specified in behavioral requirements  
- [ ] **System Behavior Validation**: System demonstrates all expected behaviors defined in behavioral specification

### Implementation Quality Assurance  
- [ ] **Code Quality**: All code meets project standards and passes quality checks
- [ ] **Test Coverage**: All embedded tests in Implementation Plan pass successfully
- [ ] **Integration Verification**: Implementation integrates properly with existing system components
- [ ] **Performance Requirements**: System meets any performance criteria specified in behavioral requirements

### Documentation and Validation
- [ ] **Behavioral Validation**: Success criteria from behavioral specification are demonstrably met
- [ ] **Error Handling**: All error conditions and edge cases handle as specified
- [ ] **Documentation Updates**: Any necessary documentation reflects the implemented behavior

## Out of Scope

- ❌ …

## References

```