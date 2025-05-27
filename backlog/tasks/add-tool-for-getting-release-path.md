```markdown
---
id: backlog+task.<sequential_number>
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# Add Tool for Getting Current Release or Backlog Path

## 0. Directory Audit ✅
_Command run:_
```bash
tree -L 2 docs-project/current docs-dev/backlog | sed 's/^/    /'
```
_Result excerpt: (Placeholder - run command during task execution)_
```
    docs-project/current
    ├── vX.Y.Z
    │   └── tasks
    └── README.md
    docs-dev/backlog
    ├── README.md
    └── tasks
        └── ...existing tasks...
```
🔍 **Directories to audit:** `docs-project/current/` and `docs-dev/backlog/`.

## Objective
Create a reliable method (e.g., a script or function) within the toolkit workflow that can determine the appropriate directory for storing newly created tasks. This method should return the path to the "current release" task directory if one is active and identifiable, or the path to the "backlog" task directory otherwise. This is required to fully automate the task creation and storage process as described in the workflow documentation.

## Scope of Work
1.  Investigate existing project structure or documentation to understand how the "current release" is currently identified or signaled within the project (e.g., a specific file, a directory pattern, a configuration setting).
2.  Design the logic for a tool (script or function) that implements the decision process:
    *   Check for the presence of a "current release" indicator.
    *   If found, construct and return the path to the `tasks/` subdirectory within that release.
    *   If not found, return the path `docs-dev/backlog/tasks/`.
3.  Implement the tool in a suitable scripting language or as part of an existing utility script.
4.  Add tests for the tool to ensure it correctly identifies paths under different scenarios (current release exists, no current release).
5.  Update relevant workflow documentation (e.g., `breakdown-notes-into-tasks.md`) to reference the new tool for determining task storage location.

### Deliverables
#### Create
- A new script or function file (e.g., `bin/get-task-storage-path` or similar).
- Test file(s) for the new tool.
#### Modify
- `coding-agent-workflow-toolkit-meta/docs-dev/workflow-instructions/breakdown-notes-into-tasks.md` (or relevant section) to incorporate the use of the new tool.
#### Delete
- None.

## Phases
1.  Investigate and Design
2.  Implement Tool
3.  Add Tests
4.  Document and Integrate

## Implementation Plan
*This section details the specific steps required to complete the task, intended to be followed sequentially.*
- [ ] **Investigate:** Search project documentation and directory structure to identify the mechanism used to signal the "current release". If no clear mechanism exists, propose a simple one (e.g., a `.current-release` file in `docs-project/`).
- [ ] **Design:** Based on the investigation, define the exact logic and required inputs/outputs for the `get-task-storage-path` tool.
- [ ] **Implement:** Write the script or function for the `get-task-storage-path` tool.
- [ ] **Test (Current Release):** Write a test case that simulates a "current release" environment and verifies the tool returns the correct release-specific tasks path.
  > TEST: Current Release Path Correct
  >   Type: Unit Test
  >   Assert: The tool returns the path `docs-project/current/vX.Y.Z/tasks/` when a mock current release `vX.Y.Z` is set up.
  >   Command: bin/test --tool get-task-storage-path --scenario current-release
- [ ] **Test (Backlog):** Write a test case that simulates an environment with no "current release" and verifies the tool returns the backlog tasks path.
  > TEST: Backlog Path Correct
  >   Type: Unit Test
  >   Assert: The tool returns the path `docs-dev/backlog/tasks/` when no current release is detected.
  >   Command: bin/test --tool get-task-storage-path --scenario no-release
- [ ] **Integrate:** Update the task creation workflow documentation (`breakdown-notes-into-tasks.md`) to describe and utilize the new tool for determining the task file location in Step 6.
- [ ] Ensure all new directories (`docs-project/current/vX.Y.Z/tasks/` and `docs-dev/backlog/tasks/`) are mentioned as requiring creation by the workflow *before* saving files, if they don't exist.

## Acceptance Criteria
- [ ] A tool exists that can be called to get the task storage path.
- [ ] The tool correctly identifies a current release path (e.g., `docs-project/current/vX.Y.Z/tasks/`) when a current release is indicated.
- [ ] The tool correctly returns the backlog path (`docs-dev/backlog/tasks/`) when no current release is indicated.
- [ ] The tool has automated tests covering both scenarios.
- [ ] The `breakdown-notes-into-tasks.md` workflow document is updated to explain and use this tool for selecting the task storage location.

## Out of Scope
- ❌ Defining or changing the overall project release process or versioning scheme.
- ❌ Implementing the actual task file writing logic (that's covered by the existing workflow steps).

## References
- [Breakdown Notes into Tasks Workflow](coding-agent-workflow-toolkit-meta/docs-dev/workflow-instructions/breakdown-notes-into-tasks.md)
- [Write Actionable Task Guide](coding-agent-workflow-toolkit-meta/docs-dev/guides/write-actionable-task.md)

## Risks & Mitigations
- **Risk:** No clear, consistent way to identify the "current release" in the project structure is found during investigation.
- **Mitigation:** Propose and implement a simple, explicit mechanism (e.g., a marker file or symlink) as part of this task, documenting it clearly. Update relevant guides or project setup instructions if necessary.
```