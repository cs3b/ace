---

id: v.0.3.0+task.05
status: done
priority: high
estimate: 6h
dependencies: [v.0.3.0+task.04]
---

# Implement Core Task Management Atoms

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 1 .ace/tools/lib/coding_agent_tools/atoms/task_management | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools/lib/coding_agent_tools/atoms/task_management
    ├── file_system_scanner.rb
    └── yaml_frontmatter_parser.rb
```

## Objective

Implement additional core atoms for task management including task ID parsing, directory navigation, and basic task utilities following the established atom pattern.

**Note**: Task 04 has been completed and the foundational atoms are now in place. This task is ready for implementation.

## Scope of Work

* Implement task_id_parser.rb for parsing task IDs
* Implement directory_navigator.rb for release directory operations
* Implement shell_command_executor.rb for command execution
* Create comprehensive unit tests
* Ensure atoms remain dependency-free

### Deliverables

#### Create

* lib/coding_agent_tools/atoms/task_management/task_id_parser.rb
* lib/coding_agent_tools/atoms/task_management/directory_navigator.rb
* lib/coding_agent_tools/atoms/task_management/shell_command_executor.rb
* spec/coding_agent_tools/atoms/task_management/task_id_parser_spec.rb
* spec/coding_agent_tools/atoms/task_management/directory_navigator_spec.rb
* spec/coding_agent_tools/atoms/task_management/shell_command_executor_spec.rb

#### Modify

* None

#### Delete

* None

## Phases

1. Implement task ID parser atom
2. Implement directory navigator atom
3. Implement shell command executor atom
4. Create comprehensive test coverage

## Implementation Plan

### Planning Steps

* [x] Analyze task ID formats from exe-old tools
  > TEST: Format Analysis
  > Type: Pre-condition Check
  > Assert: All task ID formats are documented
  > Command: grep -E "task\.[0-9]+" .ace/tools/exe-old/get-next-task-id | head -5
* [x] Study directory navigation patterns in existing tools
* [x] Design atom interfaces with clear responsibilities

### Execution Steps

- [x] Implement task_id_parser.rb with methods for parsing and validation
  > TEST: Task ID Parser
  > Type: Unit Test
  > Assert: Parser handles various task ID formats
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/task_management/task_id_parser_spec.rb
- [x] Implement directory_navigator.rb for finding release directories
- [x] Implement shell_command_executor.rb with error handling
- [x] Create unit tests achieving 100% coverage
- [x] Ensure all atoms follow single responsibility principle
- [x] Verify no external dependencies in atoms

## Acceptance Criteria

* [x] task_id_parser.rb can parse sequential numbers and extract versions
* [x] directory_navigator.rb can find and validate release directories
* [x] shell_command_executor.rb safely executes commands with error handling
* [x] All atoms have 100% test coverage
* [x] Atoms remain pure with no external dependencies

## Out of Scope

* ❌ Implementing molecules that compose these atoms
* ❌ Creating higher-level business logic
* ❌ Integrating with CLI commands

## References

* **Dependency**: v.0.3.0+task.04 (ATOM structure initialization - ✅ COMPLETED)
* Task ID formats: .ace/tools/exe-old/get-next-task-id
* Directory patterns: .ace/tools/exe-old/get-current-release-path.sh
* Task management logic: .ace/tools/exe-old/get-next-task
* Existing patterns: .ace/tools/lib/coding_agent_tools/atoms/

## Research Findings

### Task ID Format Analysis

Based on research of existing task management tools:
- Task IDs follow pattern: `v.X.Y.Z+task.N` (e.g., `v.0.3.0+task.05`)
- Sequential number extraction: `/\+task\.(\d+)$/`
- Sorting prioritizes: in-progress → pending → other statuses
- Secondary sort by task sequential number (numeric)

### Directory Navigation Patterns

- Base path: `.ace/taskflow/current/*/tasks/`
- Release directories: `v.X.Y.Z-codename` format
- Version extraction: `/^(v\.\d+\.\d+\.\d+)/`
- YAML frontmatter parsing with `---` delimiters

### Shell Command Requirements

- Safe command execution with error handling
- Integration with existing SecurityLogger
- Environment variable support
- Path validation using SecurePathValidator patterns