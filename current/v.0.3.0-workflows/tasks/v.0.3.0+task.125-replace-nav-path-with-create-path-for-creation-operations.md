---
id: v.0.3.0+task.125
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Replace nav-path with create-path for creation operations

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

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: All specified deliverables created/modified.
- [ ] AC 2: Key functionalities (if applicable) are working as described.
- [ ] AC 3: All automated checks in the Implementation Plan pass.

## Out of Scope

- ❌ Modifying the actual nav-path or create-path command implementations
- ❌ Removing nav-path command (still needed for path resolution without creation)
- ❌ Changing any Ruby code or command interfaces
- ❌ Updating content outside of documentation and workflow instructions
- ❌ Modifying historical task files or completed work

## References

- Task v.0.3.0+task.112: Add create-path command for file/directory creation with metadata
- nav-path command: /dev-tools/exe/nav-path (path resolution without file creation)
- create-path command: /dev-tools/exe/create-path (path resolution with file creation)
- Configuration: /.coding-agent/create-path.yml (template mappings)
- Main workflow affected: dev-handbook/workflow-instructions/create-task.wf.md
- Tools documentation: docs/tools.md and dev-tools/docs/tools.md
