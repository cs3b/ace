---
id: v.0.9.0+task.040
status: done
estimate: 4h
dependencies: [task.034]
---

# Implemented dependency-aware sorting and tree visualization for ace-taskflow

## Behavioral Context

**Issue**: The original task 034 specification included critical-path analysis and a --ready flag, but user feedback indicated these weren't the right approach. Tasks with dependencies needed to be automatically sorted after their dependencies in default views, and a tree visualization was needed instead of critical-path.

**Key Behavioral Requirements**:
- Default task sorting should automatically consider dependencies
- Tasks with unmet dependencies appear after ready tasks
- Tree view should show complete dependency chains including filtered-out tasks
- Formatters (--tree, --path, --list) should be applied after filtering

## Objective

Implemented comprehensive dependency management improvements for ace-taskflow, including dependency-aware sorting, tree visualization, and proper formatter handling.

## Scope of Work

- Updated task.034.md specification to remove critical-path and --ready references
- Created DependencyResolver molecule for dependency logic
- Implemented dependency-aware sorting in TaskFilter
- Created DependencyTreeVisualizer for ASCII tree views
- Fixed formatter handling to work after filtering
- Unified status icons across all views

### Deliverables

#### Create
- `ace-taskflow/lib/ace/taskflow/molecules/dependency_resolver.rb` - Core dependency logic
- `ace-taskflow/lib/ace/taskflow/molecules/dependency_tree_visualizer.rb` - Tree visualization

#### Modify
- `ace-taskflow/lib/ace/taskflow/molecules/task_filter.rb` - Added dependency-aware sorting
- `ace-taskflow/lib/ace/taskflow/commands/tasks_command.rb` - Added tree formatter support
- `ace-taskflow/lib/ace/taskflow/commands/task_command.rb` - Added tree view for individual tasks
- `.ace-taskflow/v.0.9.0/t/034-feat-taskflow-dependency-management-ace-task/task.034.md` - Updated specification
- `.ace-taskflow/v.0.9.0/t/034-feat-taskflow-dependency-management-ace-task/ux/usage.md` - Updated examples

## Implementation Summary

### What Was Done

- **Problem Identification**: User feedback revealed that the --ready flag and critical-path analysis weren't intuitive. Users expected dependency handling to be automatic in default sorting.

- **Investigation**: Analyzed current sorting implementation and identified that dependencies could be integrated into the existing sort mechanism.

- **Solution**:
  - Created DependencyResolver to check if dependencies are met and perform topological sorting
  - Modified TaskFilter.sort_tasks to automatically separate ready and blocked tasks
  - Implemented tree visualization showing complete dependency chains
  - Fixed formatters to be applied after filtering instead of bypassing it

- **Validation**: Tested with various task configurations to ensure proper sorting and tree visualization.

### Technical Details

The key innovation was integrating dependency checking into the default sort mechanism:
- Tasks are separated into ready (dependencies met) and blocked (dependencies unmet)
- Each group is sorted using existing criteria (sort field, priority, id)
- Ready tasks always appear before blocked tasks

Tree view was enhanced to show complete dependency chains:
- Fetches ALL tasks to ensure dependencies aren't hidden
- Uses emoji status indicators (🟢 done, 🟡 in-progress, ⚪ pending, ⚫ draft, 🔴 blocked)
- Shows dependencies even if they were filtered out

### Testing/Validation

```bash
# Test dependency-aware sorting
ace-taskflow tasks next

# Test tree view with filtering
ace-taskflow tasks next --limit 3 --tree

# Test individual task tree view
ace-taskflow task show 034 --tree
```

**Results**: Tasks properly sort with dependencies considered, tree view shows complete chains, formatters respect filters and limits.

## References

- Related to: task.034 (original dependency management task)
- Files modified in this session:
  - Created 2 new molecule files for dependency handling
  - Updated 5 existing files for integration
- Follow-up needed: Test with complex dependency chains in production use