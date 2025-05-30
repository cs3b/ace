---
id: <run bin/tnid to generate ID> # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
status: pending # See [Project Management Guide](project-management.md) for all possible values
priority: <high/medium/low>
estimate: <n>h
dependencies: [<ticket-ids>]
---

# <Verb + Object>

## 0. Directory Audit ✅
_Command run:_
```bash
tree -L 2 docs-dev/guides | sed 's/^/    /'
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
*This section details the specific steps required to complete the task, intended to be followed sequentially. Use a checklist format. Consider embedding verification steps directly after an action.*
- [ ] Step 1: Describe the first action.
- [ ] Step 2: Describe the second action, which produces a verifiable outcome.
  > TEST: Verify Action 2 Outcome
  >   Type: Action Validation
  >   Assert: The outcome of Step 2 (e.g., file created, content updated) is as expected.
  >   Command: bin/test --check-something path/to/relevant_artifact_from_step_2
- [ ] ... Add more steps as needed.

## Acceptance Criteria
*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan.*
- [ ] AC 1: All specified deliverables created/modified.
- [ ] AC 2: Key functionalities (if applicable) are working as described.
- [ ] AC 3: All automated checks in the Implementation Plan pass.

## Out of Scope
- ❌ …

## References
```
