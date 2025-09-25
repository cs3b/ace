---
id: v.0.9.0+task.031
status: pending
priority: high
estimate: 1 week
dependencies: []
---

# Implement descriptive task paths in ace-taskflow

## Description

Phase 1 of ace-taskflow enhancements. Currently, ace-taskflow generates task file paths that are numerically indexed (e.g., `/025/add-git-commit-and-llm-enhance-flags-to-idea-comma.md`). When browsing the `.ace-taskflow/v.*/t/` directory, users and AI agents only see numeric folder names, providing no immediate context about the task's content or purpose.

This task implements a new descriptive task file and folder naming convention that embeds semantic information directly into the path, making tasks easily identifiable at a glance.

## Behavioral Specification

The new convention will use the format: `[task_id]-[type]-[context]-[keywords]/task.[task_id].md`

Example: `025-feat-taskflow-idea-gc-llm/task.025.md`

Components:
- `[task_id]`: Unique numerical identifier
- `[type]`: Task nature (feat, fix, docs, test, refactor)
- `[context]`: Primary ACE gem or component affected
- `[keywords]`: Concise hyphenated summary from title

## Acceptance Criteria

- [ ] TaskSlugGenerator molecule created for deterministic slug generation
- [ ] path_builder.rb updated to use new naming convention
- [ ] task_loader.rb supports both old and new formats (backward compatibility)
- [ ] Migration utility created to convert existing tasks
- [ ] All tests pass with new naming convention
- [ ] ace-nav can discover tasks using descriptive paths

## Planning Steps

* [ ] Research current task path generation in path_builder.rb
* [ ] Analyze task_loader.rb parsing logic
* [ ] Design migration strategy for existing tasks
* [ ] Review ace-context PresetManager pattern for reference

## Execution Steps

- [ ] Create `ace-taskflow/lib/ace/taskflow/molecules/task_slug_generator.rb`
  - Implement deterministic slug generation from task metadata
  - Add configurable type prefixes
  - Ensure slug length limits

- [ ] Update `ace-taskflow/lib/ace/taskflow/atoms/path_builder.rb`
  - Modify `build_task_path` to use TaskSlugGenerator
  - Update `generate_task_filename` for new structure

- [ ] Update `ace-taskflow/lib/ace/taskflow/molecules/task_loader.rb`
  - Add regex patterns for both naming conventions
  - Implement backward compatibility logic
  - Update task discovery methods

- [ ] Update `ace-taskflow/lib/ace/taskflow/organisms/task_manager.rb`
  - Use TaskSlugGenerator in `create_task` method
  - Update task directory creation logic

- [ ] Create migration utility `ace-taskflow/lib/ace/taskflow/organisms/task_migrator.rb`
  - Scan for old format tasks
  - Generate new paths with slugs
  - Move files and update references

- [ ] Add tests for new functionality
  - Unit tests for TaskSlugGenerator
  - Integration tests for path changes
  - Migration tests

- [ ] Update documentation
  - Add slug format to ace-taskflow README
  - Document migration process

## Implementation Notes

This is Phase 1 of the larger ace-taskflow enhancement plan. It provides the foundation for improved navigation and must be implemented first to avoid double migration later.

Related idea: .ace-taskflow/v.0.9.0/ideas/20250925-004123-currently-paths-for-tasks-looks-like-usersmcps.md
