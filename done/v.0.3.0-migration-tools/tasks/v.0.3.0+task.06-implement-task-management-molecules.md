---

id: v.0.3.0+task.06
status: done
priority: high
estimate: 8h
dependencies: [v.0.3.0+task.05]
---

# Implement Task Management Molecules

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 1 dev-tools/lib/coding_agent_tools/molecules | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/molecules
    └── (existing molecules)
```

## Objective

Implement molecule components that compose atoms to provide higher-level task management functionality including task file loading, release path resolution, and dependency checking.

## Scope of Work

* Implement task_file_loader.rb composing file scanner and YAML parser
* Implement release_path_resolver.rb for current release detection
* Implement task_dependency_checker.rb for dependency validation
* Implement task_id_generator.rb for generating new task IDs
* Implement git_log_formatter.rb for multi-repo git logs
* Create comprehensive unit tests

### Deliverables

#### Create

* lib/coding_agent_tools/molecules/task_management/task_file_loader.rb
* lib/coding_agent_tools/molecules/task_management/release_path_resolver.rb
* lib/coding_agent_tools/molecules/task_management/task_dependency_checker.rb
* lib/coding_agent_tools/molecules/task_management/task_id_generator.rb
* lib/coding_agent_tools/molecules/task_management/git_log_formatter.rb
* Corresponding spec files for each molecule

#### Modify

* None

#### Delete

* None

## Phases

1. Implement task file loading molecule
2. Implement release path resolution
3. Implement dependency checking logic
4. Implement task ID generation
5. Implement git log formatting

## Implementation Plan

### Planning Steps

* [x] Review atom interfaces to plan molecule composition
  > TEST: Atom Review
  > Type: Pre-condition Check
  > Assert: All required atoms are available
  > Command: ls dev-tools/lib/coding_agent_tools/atoms/task_management/*.rb | wc -l
* [x] Analyze exe-old logic for extraction patterns
* [x] Design molecule interfaces with clear contracts

### Execution Steps

- [x] Create task_management directory in molecules/
- [x] Implement task_file_loader.rb using file scanner and YAML parser atoms
  > TEST: Task File Loader
  > Type: Unit Test
  > Assert: Loader can read and parse task files
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/task_management/task_file_loader_spec.rb
- [x] Implement release_path_resolver.rb for finding current release
- [x] Implement task_dependency_checker.rb with cycle detection
- [x] Implement task_id_generator.rb for sequential ID generation
- [x] Implement git_log_formatter.rb for formatted output
  > TEST: Git Log Formatter
  > Type: Unit Test
  > Assert: Formatter handles multi-repo logs
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/task_management/git_log_formatter_spec.rb
- [x] Create comprehensive tests for all molecules

## Acceptance Criteria

* [x] task_file_loader can load single files and directories of tasks
* [x] release_path_resolver correctly identifies current release
* [x] task_dependency_checker validates dependencies and detects cycles
* [x] task_id_generator produces correct sequential IDs
* [x] git_log_formatter produces properly formatted multi-repo logs
* [x] All molecules have >90% test coverage

## Out of Scope

* ❌ Implementing organisms or CLI commands
* ❌ Direct migration of exe-old tools
* ❌ Complex business logic (reserved for organisms)

## References

* Dependency: v.0.3.0+task.05 (atoms implementation)
* Molecule pattern: dev-tools/lib/coding_agent_tools/molecules/
* Logic reference: dev-tools/exe-old/get-next-task, get-recent-tasks