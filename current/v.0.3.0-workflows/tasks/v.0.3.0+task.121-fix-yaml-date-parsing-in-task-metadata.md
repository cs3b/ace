---
id: v.0.3.0+task.121
status: pending
priority: high
estimate: 3h
dependencies: []
---

# Fix YAML date parsing in task metadata

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

Resolve the "Tried to load unspecified class: Date" error that occurs when task-manager processes task files containing date fields in YAML frontmatter.

## Scope of Work

- Fix YAML parsing to properly handle Date objects in task metadata
- Ensure date fields (like `updated: 2025-07-25`) are parsed correctly
- Maintain compatibility with existing task file formats
- Add proper error handling for malformed dates

### Deliverables

#### Create

- Date parsing configuration or fixes

#### Modify

- dev-tools/lib/coding_agent_tools/atoms/yaml_reader.rb (or equivalent YAML processing)
- Any YAML loading/parsing logic in task management
- Error handling for date parsing failures

#### Delete

- N/A

## Phases

1. Audit current YAML parsing implementation
2. Identify the specific Date class loading issue
3. Implement proper Date parsing support
4. Test with existing task files containing dates

## Implementation Plan

### Planning Steps

- [ ] Reproduce the "Tried to load unspecified class: Date" error with specific task file
  > TEST: Error Reproduction
  > Type: Pre-condition Check
  > Assert: Error occurs when parsing task file with date field
  > Command: task-manager next --limit 5 2>&1 | grep "Tried to load unspecified class"
- [ ] Analyze YAML loading configuration and identify missing Date class support
- [ ] Review Ruby YAML security settings that might be blocking Date class loading

### Execution Steps

- [ ] Update YAML loader configuration to safely permit Date class loading
- [ ] Add explicit require for Date class if needed in YAML processing modules
  > TEST: Verify Date Parsing Fix
  > Type: Action Validation
  > Assert: Task files with date fields parse successfully without errors
  > Command: task-manager next --limit 5 | grep -E "task\.[0-9]+"
- [ ] Add error handling and validation for malformed date values in task metadata
- [ ] Test with the specific failing task file (v.0.3.0+task.100) that contains `updated: 2025-07-25`

## Acceptance Criteria

- [ ] AC 1: task-manager commands execute without "Tried to load unspecified class: Date" errors
- [ ] AC 2: Task files with date fields (updated, created, etc.) parse correctly
- [ ] AC 3: Date values in YAML frontmatter are accessible as proper Date objects
- [ ] AC 4: Existing task files continue to work without modification

## Out of Scope

- ❌ Changes to task file format or metadata schema
- ❌ Addition of new date-related functionality
- ❌ Migration of existing date formats
- ❌ Complex date validation or business logic

## References

Based on error from: dev-taskflow/backlog/ideas/exe-task-manager.md
Item #4: Error message and context:
```
task-manager next --limit 5
Warning: Failed to parse task file .../v.0.3.0+task.100-create-unit-tests-for-cli-command-classes.md: Tried to load unspecified class: Date
No actionable tasks found
```

Task file example with date field:
```yaml
---
id: v.0.3.0+task.100
status: in-progress  
priority: medium
estimate: 20h
dependencies: []
completion: 85%
updated: 2025-07-25
remaining_work: 5_git_commands
---
```