---
id: v.0.9.0+task.034
status: pending
priority: medium
estimate: 1 week
dependencies: [task.031]
---

# Implement task dependency management in ace-taskflow

## Description

Phase 4 of ace-taskflow enhancements. Currently, ace-taskflow manages individual tasks without explicit mechanisms to define relationships or dependencies between them. This task implements a robust dependency management system allowing users and AI agents to define 'depends-on' relationships between tasks.

This enhancement enables complex project management with clear critical paths and prevents out-of-order execution.

## Behavioral Specification

The system will:
1. Prevent tasks from transitioning to 'in-progress' if dependencies are not met
2. Provide clear output indicating why a task is blocked
3. Offer topological sorting to suggest next actionable tasks
4. Show dependencies and their statuses in task details

Commands:
- `ace-taskflow task add-dependency <task_id> --depends-on <other_task_id>`
- `ace-taskflow task remove-dependency <task_id> --depends-on <other_task_id>`
- `ace-taskflow tasks --ready` (show only actionable tasks)
- `ace-taskflow task show <id> --dependencies` (show full dependency tree)

## Acceptance Criteria

- [ ] Task model extended with dependencies array
- [ ] DependencyValidator prevents circular dependencies
- [ ] DependencyResolver determines task readiness
- [ ] Status transitions respect dependency constraints
- [ ] Topological sorting for task ordering
- [ ] CLI commands for dependency management
- [ ] Clear error messages for dependency violations

## Planning Steps

* [ ] Design dependency data model
* [ ] Research topological sorting algorithms
* [ ] Plan circular dependency detection approach
* [ ] Define blocked task behavior

## Execution Steps

- [ ] Extend `ace-taskflow/lib/ace/taskflow/models/task.rb`
  - Add dependencies array field
  - Add blocked_by computed field
  - Add ready status calculation

- [ ] Create `ace-taskflow/lib/ace/taskflow/atoms/dependency_validator.rb`
  - Detect circular dependencies
  - Validate task references exist
  - Check for self-dependencies

- [ ] Create `ace-taskflow/lib/ace/taskflow/molecules/dependency_resolver.rb`
  - Calculate task readiness
  - Build dependency graph
  - Implement topological sorting
  - Find critical path

- [ ] Create `ace-taskflow/lib/ace/taskflow/molecules/task_graph_generator.rb`
  - Generate visual dependency graphs
  - Export to DOT format
  - ASCII tree representation

- [ ] Update `ace-taskflow/lib/ace/taskflow/organisms/task_manager.rb`
  - Check dependencies on status updates
  - Prevent invalid transitions
  - Update dependent task states

- [ ] Add dependency management commands
  - Implement add-dependency subcommand
  - Implement remove-dependency subcommand
  - Add --ready filter to tasks command
  - Enhance task show with dependency tree

- [ ] Update `ace-taskflow/lib/ace/taskflow/molecules/task_filter.rb`
  - Add ready/blocked filters
  - Support dependency-based sorting

- [ ] Add visual indicators
  - Show blocked status in listings
  - Display dependency count
  - Highlight critical path tasks

- [ ] Update documentation
  - Document dependency management
  - Add workflow examples
  - Show best practices

- [ ] Add comprehensive tests
  - Unit tests for validators and resolvers
  - Integration tests for commands
  - Circular dependency tests
  - Status transition tests

## Implementation Notes

This is the most complex phase, requiring careful design to avoid breaking existing functionality. The dependency system must be optional (tasks without dependencies work as before) and provide clear value for complex project management.

This phase can leverage Phase 1 (descriptive paths) for better dependency visualization and integrates well with Phase 3 (enhanced stats) to show blocked task counts.

Related ideas:
- .ace-taskflow/v.0.9.0/ideas/20250925-004814-add-support-for-task-dependencies-in-ace-taskflow.md