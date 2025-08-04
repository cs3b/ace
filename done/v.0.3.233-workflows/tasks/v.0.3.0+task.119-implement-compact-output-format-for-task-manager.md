---
id: v.0.3.0+task.119
status: done
priority: medium
estimate: 4h
dependencies: []
---

# Implement compact output format for task-manager

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools | sed 's/^/    /'
```

_Result excerpt:_

```
dev-tools/lib/coding_agent_tools
├── atoms
├── cli
├── constants
├── ecosystems
├── middlewares
├── models
├── molecules
├── organisms
└── version.rb
```

## Objective

Replace the verbose multi-line task output format with a compact single-line format to improve readability and usability when viewing task lists and status information.

## Scope of Work

- Update task-manager output formatting logic
- Implement compact single-line format as specified in requirements
- Ensure all task information remains accessible
- Maintain option for verbose output when needed

### Deliverables

#### Create

- New compact formatter class or method

#### Modify

- dev-tools/lib/coding_agent_tools/cli/task_manager.rb (or equivalent CLI class)
- dev-tools/exe/task-manager (output formatting logic)
- Task display formatting methods

#### Delete

- N/A

## Phases

1. Audit current output formatting implementation
2. Implement compact formatter
3. Update CLI to use compact format by default
4. Test output readability and functionality

## Implementation Plan

### Planning Steps

- [x] Analyze current task-manager output format implementation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current output formatting logic is identified and understood
  > Command: task-manager next --limit 3 | head -10
- [x] Design compact format structure based on requirements
- [x] Plan backward compatibility for verbose output option

### Execution Steps

- [x] Implement compact output formatter that displays task info in single line format
  > TEST: Verify Compact Format
  > Type: Action Validation
  > Assert: Task output follows format: "v.0.3.0+task.116 * PENDING * Refactor create-path executable..."
  > Command: task-manager next --limit 1 | grep -E "v\.[0-9]+\.[0-9]+\.[0-9]+\+task\.[0-9]+ \* [A-Z]+ \*"
- [x] Update task-manager CLI commands to use compact format by default
- [x] Add verbose flag option to maintain access to detailed output when needed
- [x] Update path display to show relative paths from project root

## Acceptance Criteria

- [x] AC 1: Task list displays in compact single-line format as specified
- [x] AC 2: All essential task information (ID, status, title, path, dependencies) is visible
- [x] AC 3: Output is more readable and scannable than previous format
- [x] AC 4: Optional verbose mode still available for detailed information

## Out of Scope

- ❌ Changes to task file format or metadata structure
- ❌ Modifications to task creation or management logic
- ❌ Changes to underlying task data models

## References

Based on requirements from: dev-taskflow/backlog/ideas/exe-task-manager.md
Item #2: Compact format specification:
- From: Multi-line verbose format with separate lines for title, status, path, dependencies
- To: "v.0.3.0+task.116 * PENDING * Refactor create-path executable to use dry library pattern"
      + path on next line indented
      + dependencies on following line if present