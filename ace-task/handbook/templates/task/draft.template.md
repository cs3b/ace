---
id:
  id:
status: draft
priority:
  priority:
estimate: TBD
dependencies:
  dependencies:
bundle:
  presets:
  - project
  files: []
  commands: []
doc-type: template
purpose: Template for drafting task definitions
ace-docs:
  last-updated: '2026-03-21'
---

# {title}

## Behavioral Specification

### User Experience
- **Input**: [What users provide - data, commands, interactions]
- **Process**: [What users experience during interaction - feedback, states, flows]
- **Output**: [What users receive - results, confirmations, artifacts]

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

[Describe the desired behavior, user experience, and system responses]

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# CLI Interface (if applicable)
command-name [options] <arguments>
# Expected outputs, error messages, and status codes

# API Interface (if applicable)
GET/POST/PUT/DELETE /endpoint
# Request/response formats, error responses, status codes

# UI Interface (if applicable)
# User interactions, form behaviors, navigation flows
```

**Exit Codes** (CLI tasks):
<!-- Define exit code semantics - what each code means -->
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments/usage |
| 130 | Interrupted (Ctrl+C) |

**Error Handling:**
- [Error condition 1]: [Expected system response]
- [Error condition 2]: [Expected system response]

**Input Validation** (data-driven features):
<!-- Define what validation is required for input data -->
- [Required field 1]: [Validation rule and error if missing]
- [Required field 2]: [Validation rule and error if missing]

**Edge Cases:**
- [Edge case 1]: [Expected behavior]
- [Edge case 2]: [Expected behavior]

**Concurrency Considerations** (if applicable):
<!-- Document multi-process safety requirements -->
- [ ] File operations: [Atomic write requirements]
- [ ] ID generation: [Uniqueness guarantees under concurrent access]
- [ ] State management: [Race condition handling]

**Cleanup Behavior:**
<!-- What happens to resources on success, failure, and interruption -->
- Success: [Expected cleanup]
- Failure: [Expected cleanup - no orphan temp files]
- Interruption: [Expected cleanup on SIGINT]

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Behavioral Outcome 1**: [Observable user/system behavior or capability]
- [ ] **User Experience Goal 2**: [Measurable user experience improvement]
- [ ] **System Performance 3**: [Measurable system behavior or performance metric]

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [ ] **Requirement Clarity**: [Question about unclear or ambiguous requirements]
- [ ] **Edge Case Handling**: [Question about boundary conditions or unusual scenarios]  
- [ ] **User Experience**: [Question about user expectations, workflows, or interactions]
- [ ] **Success Definition**: [Question about how success will be measured or validated]

### Vertical Slice Decomposition (Task/Subtask Model)
<!-- Describe end-to-end slices using task/subtask structure -->
<!-- Use orchestrator + subtasks for multiple slices; use standalone task for one slice -->

- **Slice Type**: [Standalone task | Orchestrator | Subtask]
- **Slice Outcome**: [Observable end-to-end capability delivered by this task/subtask]
- **Advisory Size**: [small | medium | large]
- **Context Dependencies**: [Critical files/presets/commands this slice needs in fresh sessions]

### Verification Plan
<!-- Define verification strategy before implementation -->
<!-- Include unit/equivalent checks, integration/e2e where applicable, and failure-path validation -->

#### Unit / Component Validation
- [ ] [Scenario]: [Expected observable result]

#### Integration / E2E Validation (if cross-boundary behavior exists)
- [ ] [Scenario]: [Expected observable result]

#### Failure / Invalid-Path Validation
- [ ] [Scenario]: [Expected error handling behavior]

#### Verification Commands
- [ ] [Command/check]: [Expected outcome]

## Objective

Why are we doing this? Focus on user value and behavioral outcomes.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: [Which user interactions, workflows, and experiences are included]
- **System Behavior Scope**: [Which system capabilities, responses, and behaviors are included]  
- **Interface Scope**: [Which APIs, commands, or interfaces are included]

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

#### Demo Scenario (user-facing features only)
<!-- Skip this section if the task has no CLI or user-visible behavior changes -->
<!-- Define what a recorded demo should show so a reviewer can confirm the feature works -->

**What the viewer should understand**: [one sentence summarizing the takeaway]

| Scene | Shows | Commands | Fixtures needed |
|-------|-------|----------|-----------------|
| 1. Show input | The config/input the user creates | `cat <file>` | sample config file |
| 2. Run feature | The feature in action | `ace-<tool> <command>` | — |
| 3. Verify result | The output/outcome | `ls`, `cat`, status check | — |

**Timing**: use 3-5s sleep per scene so the viewer can read output

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: File structures, code organization, technical architecture
- ❌ **Technology Decisions**: Tool selections, library choices, framework decisions  
- ❌ **Performance Optimization**: Specific performance improvement strategies
- ❌ **Future Enhancements**: Related features or capabilities not in current scope

## References

- Related capture-it output (if applicable)
- User experience requirements
- Interface specification examples