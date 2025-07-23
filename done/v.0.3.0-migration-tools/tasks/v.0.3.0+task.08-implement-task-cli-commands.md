---

id: v.0.3.0+task.08
status: done
priority: high
estimate: 8h
dependencies: [v.0.3.0+task.07]
---

# Implement Task CLI Commands

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/cli/commands | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/cli/commands
    ├── llm
    └── (other command directories)
```

## Objective

Implement CLI commands for task management operations using dry-cli framework, providing a seamless interface to the TaskManager organism while maintaining backward compatibility with bin/ scripts.

## Scope of Work

* Create task namespace in CLI commands
* Implement `task next` command with `--limit` option
* Implement `task recent` command with options including `--limit`
* Implement `task all` command
* Implement `task generate-id` command with `--limit` option

### Deliverables

#### Create

* lib/coding_agent_tools/cli/commands/task.rb (namespace)
* lib/coding_agent_tools/cli/commands/task/next.rb
* lib/coding_agent_tools/cli/commands/task/recent.rb
* lib/coding_agent_tools/cli/commands/task/all.rb
* lib/coding_agent_tools/cli/commands/task/generate_id.rb
* Corresponding spec files

**Note**: `task current-release` functionality has been moved to task.12 (release manager) and will be implemented as `release current`

#### Modify

* lib/coding_agent_tools/cli.rb (register task namespace)

#### Delete

* None

## Phases

1. Create task command namespace
2. Implement individual commands
3. Add option parsing and validation
4. Create integration tests
5. Verify backward compatibility

## Implementation Plan

### Planning Steps

* [x] Study dry-cli patterns in existing commands
  > TEST: Pattern Analysis
  > Type: Pre-condition Check
  > Assert: Existing command patterns understood
  > Command: grep -r "dry-cli" dev-tools/lib/coding_agent_tools/cli/commands | wc -l
* [x] Analyze TaskManager organism API for CLI integration
  > TEST: TaskManager API Understanding
  > Type: Pre-condition Check
  > Assert: TaskManager methods and result structures understood
  > Command: cd dev-tools && bundle exec ruby -e "require 'lib/coding_agent_tools'; puts CodingAgentTools::Organisms::TaskManagement::TaskManager.instance_methods(false)"
* [ ] Design command options with --limit support
* [ ] Plan error handling for invalid limit values and CLI edge cases
* [ ] Design CLI output formats consistent with existing tools

### Execution Steps

- [x] Create task.rb namespace module following dry-cli patterns
- [x] Implement task next command with TaskManager integration
  > TEST: Next Command Basic
  > Type: CLI Test
  > Assert: Command executes and returns next task
  > Command: cd dev-tools && bundle exec exe/coding_agent_tools task next --help
- [x] Add --limit option to task next command
  > TEST: Next Command Limit
  > Type: CLI Test
  > Assert: --limit option works correctly
  > Command: cd dev-tools && bundle exec exe/coding_agent_tools task next --limit 3
- [x] Implement task recent with --last and --limit option parsing
  > TEST: Recent Command Options
  > Type: CLI Test
  > Assert: Both --last and --limit options work
  > Command: cd dev-tools && bundle exec exe/coding_agent_tools task recent --last 2.days --limit 5
- [x] Implement task all with color output support
- [x] Implement task generate-id with VERSION argument and --limit option
  > TEST: Generate ID Limit
  > Type: CLI Test
  > Assert: --limit generates multiple IDs
  > Command: cd dev-tools && bundle exec exe/coding_agent_tools task generate-id --limit 3
- [x] Add input validation for --limit option (positive integers only)
- [x] Register all commands in CLI module
- [x] Create comprehensive CLI tests using Aruba framework
  > TEST: CLI Integration Suite
  > Type: Integration Test
  > Assert: All commands work with TaskManager organism
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/task_spec.rb

## Acceptance Criteria

* [x] All four task commands are available via coding_agent_tools CLI (next, recent, all, generate-id)
* [x] Commands maintain exact output format of exe-old tools
* [x] Option parsing works correctly (e.g., --last 2.days, --limit 3)
* [x] --limit option works on next, recent, and generate-id commands
* [x] --limit option validates positive integer input and shows helpful errors
* [x] Error messages are helpful and consistent
* [x] Commands integrate properly with TaskManager organism
* [x] CLI tests using Aruba framework provide comprehensive coverage
* [x] All commands gracefully handle edge cases (no tasks, invalid paths, etc.)

## Out of Scope

* ❌ Updating bin/ scripts (separate task)
* ❌ Modifying organism logic
* ❌ Adding new features beyond exe-old parity (except --limit options)
* ❌ Implementing task current-release command (moved to task.12 release manager)
* ❌ Creating new TaskManager methods (use existing API)

## References

* Dependency: v.0.3.0+task.07 (TaskManager organism)
* CLI framework: lib/coding_agent_tools/cli/
* Command pattern: lib/coding_agent_tools/cli/commands/llm/
* Original tools: dev-tools/exe-old/get-*
* Related task: v.0.3.0+task.12 (ReleaseManager organism - handles `release current` functionality)
* TaskManager API: lib/coding_agent_tools/organisms/task_management/task_manager.rb
* dry-cli documentation: https://dry-rb.org/gems/dry-cli/
* Aruba testing framework: https://github.com/cucumber/aruba