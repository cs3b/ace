---
id: v.0.9.0+task.090
status: draft
priority: high
estimate: 1 week
dependencies: []
---

# Implement ace-taskflow task update command for metadata updates

## Behavioral Specification

### User Experience
- **Input**: Task reference (ID, number, or path) and field updates via CLI flags
- **Process**: User executes command with `--field key=value` syntax to update arbitrary task metadata
- **Output**: Confirmation of updated fields and task path

### Expected Behavior

The system should provide a generic way to update any task metadata field through a simple CLI command. Users can update single or multiple fields in one command, with support for nested YAML keys using dot notation (e.g., `worktree.branch`). The command preserves all other task content while only modifying specified fields.

Key behaviors:
- Accept any valid task reference (081, task.081, v.0.9.0+task.081, or file path)
- Support multiple `--field` flags for batch updates
- Handle nested YAML structures with dot notation
- Validate field values match YAML types (string, number, boolean, array)
- Preserve task file formatting and non-metadata content
- Provide clear feedback on what was updated

### Interface Contract

```bash
# CLI Interface
ace-taskflow task update <reference> --field <key=value> [--field <key2=value2>] [options]

# Examples:
# Update single field
ace-taskflow task update 081 --field priority=high

# Update multiple fields
ace-taskflow task update 081 --field priority=high --field estimate="2 weeks"

# Update nested fields (for worktree metadata)
ace-taskflow task update 081 \
  --field worktree.branch=081-fix-auth \
  --field worktree.path=.ace-wt/task.081 \
  --field worktree.created_at="2025-11-01 09:00:00"

# Update arrays
ace-taskflow task update 081 --field "dependencies=[082, 083]"

# Expected output:
# Task updated: v.0.9.0+task.081
# Updated fields:
#   worktree.branch: 081-fix-auth
#   worktree.path: .ace-wt/task.081
#   worktree.created_at: 2025-11-01 09:00:00
# Task path: /path/to/.ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md

# Exit codes:
# 0 - Success
# 1 - Task not found
# 2 - Invalid field syntax
# 3 - File write error
```

**Error Handling:**
- Task not found: "Error: Task not found: <reference>"
- Invalid syntax: "Error: Invalid field syntax. Use: --field key=value"
- Invalid nesting: "Error: Cannot update nested field 'x.y.z' - parent 'x.y' does not exist"
- Type mismatch: "Error: Field 'priority' expects string, got array"
- Write failure: "Error: Failed to update task file: <reason>"

**Edge Cases:**
- Empty value: `--field description=""` clears the field
- Special characters: Values with spaces/quotes properly escaped
- Deep nesting: Support arbitrary depth (e.g., `a.b.c.d=value`)
- Concurrent updates: Use atomic file writes with backup

### Success Criteria

- [ ] **Field Updates**: Any frontmatter field can be updated via --field flag
- [ ] **Nested Support**: Dot notation works for nested YAML structures
- [ ] **Batch Updates**: Multiple --field flags processed in single command
- [ ] **Validation**: Field types validated against existing schema
- [ ] **Preservation**: Non-metadata content remains unchanged
- [ ] **Atomic Writes**: File updates are atomic with automatic backup
- [ ] **Clear Output**: User receives confirmation of all updated fields

### Validation Questions

- [ ] **Field Validation**: Should we validate against known task schema or allow any field?
- [ ] **Type Inference**: How to infer types from string values (e.g., "true" → boolean)?
- [ ] **Array Syntax**: Best syntax for array values in --field flag?
- [ ] **Backup Strategy**: Keep how many backup versions of task files?

## Objective

Enable programmatic and manual updates to task metadata fields without requiring direct file editing. This supports automation tools (like ace-git-worktree) that need to add metadata to tasks, while also providing users with a convenient way to update task properties from the command line.

## Scope of Work

### User Experience Scope
- CLI command for updating any task metadata field
- Support for single and batch field updates
- Clear feedback on what was changed
- Validation of field values and types

### System Behavior Scope
- Parse and validate field update syntax
- Load task file and parse YAML frontmatter
- Apply field updates while preserving other content
- Atomic file writes with backup
- Error handling and user feedback

### Interface Scope
- `ace-taskflow task update` CLI command
- `--field key=value` flag syntax
- Support for nested keys with dot notation
- Structured output for success and errors

### Deliverables

#### Behavioral Specifications
- Command syntax and usage examples
- Field update patterns and validation rules
- Error handling specifications

#### User Experience Artifacts
- Clear command output format
- Helpful error messages with suggestions
- Usage documentation and examples

#### Validation Artifacts
- Test cases for various field types
- Edge case handling verification
- Atomic write operation validation

## Out of Scope

- ❌ **Schema Definition**: Creating formal task schema (future enhancement)
- ❌ **GUI Interface**: Web or desktop UI for task updates
- ❌ **Bulk Operations**: Updating multiple tasks in one command
- ❌ **Field Deletion**: Removing fields entirely (vs. setting empty)
- ❌ **Non-Metadata Updates**: Modifying task content outside frontmatter

## References

- Source Idea: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/20251101-090039-implement-ace-taskflow-task-update-command-for-met.md
- Related Task: v.0.9.0+task.089 (ace-git-worktree gem - requires this command)
- Existing Pattern: ace-taskflow molecules/task_loader.rb update_task_status method
- Similar Tools: kubectl patch, git config, npm config set