---
id: v.0.3.0+task.126
status: done
priority: high
estimate: 4h
dependencies: []
---

# Implement unified compact formatter with modification time

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Standardize task display formatting across all task listing commands (next, all, recent) by implementing a unified compact formatter that includes modification time, eliminating code duplication and ensuring consistent user experience.

## Scope of Work

- Create unified compact formatter with modification time support
- Update recent command to use compact format (currently uses verbose format)
- Ensure consistent format: `ID * STATUS * TIME_AGO * Title`
- Implement relative time formatting (hours/days, date for >1 day)
- Apply formatter across all task listing commands

### Deliverables

#### Create

- .ace/tools/lib/coding_agent_tools/molecules/taskflow_management/unified_task_formatter.rb

#### Modify

- .ace/tools/lib/coding_agent_tools/cli/commands/task/recent.rb
- .ace/tools/lib/coding_agent_tools/cli/commands/task/next.rb (update to use unified formatter)
- .ace/tools/lib/coding_agent_tools/cli/commands/task/all.rb (update to use unified formatter)

#### Delete

- N/A

## Phases

1. Audit current formatting implementations across commands
2. Design unified formatter with time support
3. Implement unified formatter molecule
4. Update all commands to use unified formatter

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Analyze current formatting logic in next, all, and recent commands
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All current formatting approaches are documented and understood
  > Command: grep -r "display.*task" .ace/tools/lib/coding_agent_tools/cli/commands/task/
- [ ] Design unified formatter API with modification time support
- [ ] Plan relative time formatting strategy (hours/days/date format)

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Create unified task formatter molecule with time calculation
  > TEST: Verify Formatter Creation
  > Type: Action Validation
  > Assert: Unified formatter handles time formatting correctly
  > Command: grep -E "class.*UnifiedTaskFormatter" .ace/tools/lib/coding_agent_tools/molecules/taskflow_management/unified_task_formatter.rb
- [ ] Implement modification time detection from file system
- [ ] Update recent command to use unified compact formatter
  > TEST: Verify Recent Command Format
  > Type: Action Validation
  > Assert: Recent command uses compact format with modification time
  > Command: task-manager recent | grep -E "v\.[0-9]+\.[0-9]+\.[0-9]+\+task\.[0-9]+ \* [A-Z]+ \* .* \*"
- [ ] Update next and all commands to use unified formatter with time
- [ ] Test relative time formatting edge cases (hours, days, dates)

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: All task listing commands (next, all, recent) use identical compact format
- [ ] AC 2: Format includes modification time: `ID * STATUS * TIME_AGO * Title`
- [ ] AC 3: Time formatting uses relative format (hours/days) or date for >1 day (2025-07-29)
- [ ] AC 4: No code duplication between task display implementations
- [ ] AC 5: Verbose mode still available with --verbose flag

## Out of Scope

- ❌ Changes to task file format or metadata structure
- ❌ Complex time zone handling (use local system time)
- ❌ Internationalization of time strings

## References

Based on feedback from: .ace/taskflow/backlog/ideas/exe-task-manager-improvements.md
- Item #2: Unified compact formatter with modification time
- Target format: `v.0.3.0+task.115 * done * 18 hours ago * Add comprehensive error handling tests`
