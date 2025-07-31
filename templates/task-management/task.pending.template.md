---
id: {id}
status: pending
priority: {priority}
estimate: {estimate}
dependencies: {dependencies}
---

# {title}

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
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

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: bin/test --check-analysis-complete
- [ ] Research best practices and design approach
- [ ] Plan detailed implementation strategy

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Step 1: Describe the first implementation action.
- [ ] Step 2: Describe the second action, which produces a verifiable outcome.
  > TEST: Verify Action 2 Outcome
  > Type: Action Validation
  > Assert: The outcome of Step 2 (e.g., file created, content updated) is as expected.
  > Command: bin/test --check-something path/to/relevant_artifact_from_step_2
- [ ] ... Add more implementation steps as needed.

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

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: All specified deliverables created/modified.
- [ ] AC 2: Key functionalities (if applicable) are working as described.
- [ ] AC 3: All automated checks in the Implementation Plan pass.

## Out of Scope

- ❌ …

## References

```