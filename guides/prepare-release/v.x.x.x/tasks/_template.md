---
id: v.X.Y.Z-<task_number> # REQUIRED - Unique ID (e.g., v.0.2.3-1)
status: pending # pending | in-progress | done | blocked
priority: <high/medium/low>
estimate: <n>h
dependencies: [<task-ids>] # e.g., [v.0.2.3-1, v.0.2.3-2]
---

# <Verb + Object> - Clear Task Title

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 <relevant-directory> | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree output here>
```

## Objective

Brief description of why this task is necessary and what problem it solves.

## Implementation Details / Notes

- Specific implementation details
- Technical considerations or constraints
- Design decisions
- References to relevant code or documentation

## Implementation Plan

*This section details the specific steps required to complete the task, intended to be followed sequentially. Use a checklist format._

- [ ] Step 1: Describe the first action.
- [ ] Step 2: Describe the second action.
- [ ] ... Add more steps as needed.

## Acceptance Criteria

- [ ] AC 1: First criterion for determining when the task is complete
- [ ] AC 2: Second criterion
- [ ] ... Additional criteria as needed

## Out of Scope

- Items explicitly excluded from this task
- Features or modifications to be addressed in separate tasks

## References

- [Project Management Guide](docs-dev/guides/project-management.md)
- [Other relevant documentation](path/to/relevant/doc.md)
- Links to related issues, PR comments, or external resources
